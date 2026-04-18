import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import '../models/duplicate_group_model.dart';
import '../models/file_hash_entity.dart';
import '../models/file_meta_model.dart';
import '../models/scan_progress_model.dart';
import '../repository/duplicate_finder_repository.dart';
import '../repository/hash_cache_repository.dart';
import '../utils/cancel_token.dart';
import '../utils/hash_utils.dart';

// ---------------------------------------------------------------------------
// _Semaphore — permit-based concurrency limiter
// ---------------------------------------------------------------------------

/// Limits concurrent async operations to a fixed number of permits.
///
/// Callers [acquire] a permit before starting I/O and [release] it in a
/// `finally` block when the I/O completes (or throws).
class _Semaphore {
  _Semaphore(int permits) : _availablePermits = permits;

  int _availablePermits;
  final Queue<Completer<void>> _waiters = Queue();

  /// Acquires a permit. If no permits are available, waits until one is
  /// released by another caller.
  Future<void> acquire() {
    if (_availablePermits > 0) {
      _availablePermits--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Releases a previously acquired permit, waking the oldest waiter if any.
  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _availablePermits++;
    }
  }
}

// ---------------------------------------------------------------------------
// _NoOpHashCacheRepository — Phase 3 stub
// ---------------------------------------------------------------------------

/// No-operation hash cache used until the full ObjectBox-backed
/// [HashCacheRepositoryImpl] is wired in Phase 6 (T032 / T034).
///
/// All reads return `null` (cache miss), all writes are silent no-ops.
/// The pipeline still works correctly — it simply recomputes hashes every run.
class _NoOpHashCacheRepository implements HashCacheRepository {
  @override
  FileHashEntity? getEntity(String path) => null;

  @override
  void savePartialHash(FileMeta meta, String hash) {}

  @override
  void saveFullHash(FileMeta meta, String hash) {}
}

// ---------------------------------------------------------------------------
// DuplicateFinderService — internal pipeline engine (runs in worker isolate)
// ---------------------------------------------------------------------------

/// Core duplicate-detection engine.
///
/// **IMPORTANT**: Instances of this class must only be created and used inside
/// a spawned Dart isolate (never the main/UI isolate).  The hashing methods
/// used in Stage 3 and Stage 5 are synchronous and will block the calling
/// thread while performing file I/O.
///
/// Pipeline stages:
/// 1. Metadata collection  — `statSync` each file; skip inaccessible / zero-byte
/// 2. Group by size         — drop singleton-size files; sort largest first
/// 3. Partial hash          — hash first+last window, bounded by semaphore
/// 4. Group by partial hash — drop files whose partial hash is unique
/// 5. Full hash             — skip files ≤ chunkSize (partial IS the full hash)
/// 6. Group by full hash    — confirmed duplicate groups
/// 7. Emit done progress and return result
class DuplicateFinderService {
  /// Creates a [DuplicateFinderService].
  ///
  /// [hashCache] is used for read-through caching (Phase 6 / T033).
  /// In Phase 3 a [_NoOpHashCacheRepository] stub is passed.
  ///
  /// [concurrencyLimit] caps how many concurrent file-I/O operations run at
  /// the same time inside this isolate (via the [_Semaphore]).
  DuplicateFinderService({
    required HashCacheRepository hashCache,
    int concurrencyLimit = 4,
  })  :
        // ignore: unused_field  — cache integration added in Phase 6 (T033)
        _hashCache = hashCache,
        _semaphore = _Semaphore(concurrencyLimit);

  // ignore: unused_field
  final HashCacheRepository _hashCache;
  final _Semaphore _semaphore;

  /// Runs the staged duplicate-detection pipeline and returns confirmed
  /// duplicate groups.
  ///
  /// Progress snapshots are delivered via [onProgress].
  /// [cancelToken] allows cooperative cancellation between stages.
  Future<List<DuplicateGroup>> find({
    required List<File> files,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
  }) async {
    // -----------------------------------------------------------------------
    // Stage 1: Metadata collection
    // -----------------------------------------------------------------------
    final metaList = <FileMeta>[];
    for (final file in files) {
      try {
        final stat = file.statSync();
        if (stat.size == 0) continue; // zero-byte files cannot be duplicates
        metaList.add(FileMeta(
          path: file.path,
          size: stat.size,
          lastModified: stat.modified.millisecondsSinceEpoch,
        ));
      } on FileSystemException {
        continue; // skip inaccessible / permission-denied files
      }
    }

    onProgress(ScanProgress(
      stage: 'scanning',
      stageTotal: metaList.length,
      stageProcessed: metaList.length,
    ));

    // -----------------------------------------------------------------------
    // Stage 2: Group by size — drop singletons, sort descending
    // -----------------------------------------------------------------------
    final sizeMap = <int, List<FileMeta>>{};
    for (final meta in metaList) {
      sizeMap.putIfAbsent(meta.size, () => []).add(meta);
    }

    final sortedSizes = sizeMap.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // largest files first (FR-009)

    final sizeGroups = sortedSizes
        .where((size) => sizeMap[size]!.length >= 2)
        .map((size) => sizeMap[size]!)
        .toList();

    if (sizeGroups.isEmpty) {
      onProgress(ScanProgress(stage: 'done', stageTotal: 0, stageProcessed: 0));
      return [];
    }

    final sizeCandidates = sizeGroups.expand((g) => g).toList();

    // -----------------------------------------------------------------------
    // Stage 3: Partial hash pass (concurrent, semaphore-guarded)
    // -----------------------------------------------------------------------
    final metaToPartialHash = <FileMeta, String>{};
    {
      final partialTotal = sizeCandidates.length;
      int partialProcessed = 0;
      onProgress(ScanProgress(
        stage: 'partial',
        stageTotal: partialTotal,
        stageProcessed: 0,
      ));

      final hashFutures = sizeCandidates.map((meta) async {
        cancelToken.throwIfCancelled();
        await _semaphore.acquire();
        try {
          cancelToken.throwIfCancelled();
          final hash = HashUtils.partialHash(meta.path);
          onProgress(ScanProgress(
            stage: 'partial',
            stageTotal: partialTotal,
            stageProcessed: ++partialProcessed,
          ));
          return MapEntry(meta, hash);
        } finally {
          _semaphore.release();
        }
      }).toList();

      final results = await Future.wait(hashFutures);
      for (final entry in results) {
        metaToPartialHash[entry.key] = entry.value;
      }
    }

    // -----------------------------------------------------------------------
    // Stage 4: Group by partial hash — drop singletons
    // -----------------------------------------------------------------------
    final partialHashMap = <String, List<FileMeta>>{};
    for (final entry in metaToPartialHash.entries) {
      partialHashMap.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    final partialCandidates = partialHashMap.values
        .where((g) => g.length >= 2)
        .expand((g) => g)
        .toList();

    if (partialCandidates.isEmpty) {
      onProgress(ScanProgress(stage: 'done', stageTotal: 0, stageProcessed: 0));
      return [];
    }

    // -----------------------------------------------------------------------
    // Stage 5: Full hash pass
    //
    // Files ≤ chunkSize: the partial hash already covers the entire file
    //   → reuse the already-computed partial hash; no second file read.
    // Files > chunkSize: compute full hash (concurrent, semaphore-guarded).
    // -----------------------------------------------------------------------
    final fullHashMap = <String, List<FileMeta>>{};
    {
      final fullTotal = partialCandidates.length;
      int fullProcessed = 0;
      onProgress(ScanProgress(
        stage: 'full',
        stageTotal: fullTotal,
        stageProcessed: 0,
      ));

      final hashFutures = partialCandidates.map((meta) async {
        if (meta.size <= HashUtils.chunkSize) {
          // Partial hash covers the complete file for small files.
          onProgress(ScanProgress(
            stage: 'full',
            stageTotal: fullTotal,
            stageProcessed: ++fullProcessed,
          ));
          return MapEntry(meta, metaToPartialHash[meta]!);
        }
        cancelToken.throwIfCancelled();
        await _semaphore.acquire();
        try {
          cancelToken.throwIfCancelled();
          final hash = HashUtils.fullHash(meta.path);
          onProgress(ScanProgress(
            stage: 'full',
            stageTotal: fullTotal,
            stageProcessed: ++fullProcessed,
          ));
          return MapEntry(meta, hash);
        } finally {
          _semaphore.release();
        }
      }).toList();

      final results = await Future.wait(hashFutures);
      for (final entry in results) {
        fullHashMap.putIfAbsent(entry.value, () => []).add(entry.key);
      }
    }

    // -----------------------------------------------------------------------
    // Stage 6: Group by full hash — confirmed duplicate groups
    // -----------------------------------------------------------------------
    final duplicateGroups = fullHashMap.values
        .where((g) => g.length >= 2)
        .map(
          (g) => DuplicateGroup(
            paths: List.unmodifiable(g.map((m) => m.path).toList()),
          ),
        )
        .toList();

    // -----------------------------------------------------------------------
    // Stage 7: Emit done and return
    // -----------------------------------------------------------------------
    onProgress(ScanProgress(stage: 'done', stageTotal: 0, stageProcessed: 0));
    return duplicateGroups;
  }
}

// ---------------------------------------------------------------------------
// DuplicateFinderRepositoryImpl — main-isolate adapter
// ---------------------------------------------------------------------------

/// Main-isolate adapter that implements [DuplicateFinderRepository].
///
/// Owns all [Isolate.spawn] and [SendPort]/[ReceivePort] wiring.
/// The [DuplicateFinderService] pipeline is executed inside the worker isolate.
///
/// Cancel bridging uses a handshake pattern:
///   1. Worker sends its cancel [SendPort] back over [_cancelHandshakePort].
///   2. Repo registers a listener on [CancelToken.cancelFuture] that forwards
///      a `'cancel'` message to the worker when the token fires.
class DuplicateFinderRepositoryImpl implements DuplicateFinderRepository {
  const DuplicateFinderRepositoryImpl({
    this.storePath = '',
    this.concurrencyLimit = 4,
  });

  /// Path to the ObjectBox store directory.
  ///
  /// Passed to the worker isolate and used for hash caching once
  /// [HashCacheRepositoryImpl] is wired in Phase 6 (T034).
  /// An empty string is acceptable in Phase 3 (no-op cache).
  final String storePath;

  /// Maximum concurrent file-I/O operations inside the worker isolate.
  final int concurrencyLimit;

  @override
  Future<List<DuplicateGroup>> find({
    required List<File> files,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
  }) async {
    // All worker→main messages (progress, result, error) arrive on this port.
    final resultRp = ReceivePort();

    // One-shot port: the worker sends back its local cancel SendPort here.
    final handshakeRp = ReceivePort();

    await Isolate.spawn<Map<String, dynamic>>(_workerEntrypoint, {
      'storePath': storePath,
      'filePaths': files.map((f) => f.path).toList(),
      'concurrencyLimit': concurrencyLimit,
      'byteByByteCompare': byteByByteCompare,
      'progressPort': resultRp.sendPort,
      'cancelHandshakePort': handshakeRp.sendPort,
    });

    // Await the worker's cancel SendPort to complete the handshake.
    final workerCancelSendPort = await handshakeRp.first as SendPort;
    handshakeRp.close();

    // Bridge: when cancelToken fires, forward the signal to the worker.
    // Safe to register after the handshake — cancelFuture is backed by a
    // Completer so it fires even if cancel() was called before this line.
    cancelToken.cancelFuture.then((_) => workerCancelSendPort.send('cancel'));

    final completer = Completer<List<DuplicateGroup>>();

    resultRp.listen((raw) {
      final msg = raw as Map<String, dynamic>;
      switch (msg['type'] as String) {
        case 'progress':
          onProgress(ScanProgress(
            stageTotal: msg['stageTotal'] as int,
            stageProcessed: msg['stageProcessed'] as int,
            stage: msg['stage'] as String,
          ));
        case 'result':
          final groups = (msg['groups'] as List<dynamic>)
              .map(
                (g) => DuplicateGroup(
                  paths: List.unmodifiable(
                    (g as List<dynamic>).cast<String>(),
                  ),
                ),
              )
              .toList();
          completer.complete(groups);
          resultRp.close(); // no further messages expected after result
        case 'error':
          final cancelled = msg['cancelled'] as bool;
          final message = msg['message'] as String;
          completer.completeError(
            cancelled ? ScanCancelledException(message) : Exception(message),
          );
          resultRp.close(); // no further messages expected after error
      }
    });

    return completer.future;
  }
}

// ---------------------------------------------------------------------------
// Worker isolate entrypoint (MUST be top-level — Isolate.spawn requirement)
// ---------------------------------------------------------------------------

/// Worker isolate entry point for the duplicate-detection engine.
///
/// **Phase 3 note**: Uses [_NoOpHashCacheRepository] (no caching; all hashes
/// are recomputed every scan).
///
/// **Phase 6 (T034)** will update this function to open an ObjectBox
/// [Store] via `Store.attach(getObjectBoxModel(), storePath)` and replace
/// the no-op cache with [HashCacheRepositoryImpl].
Future<void> _workerEntrypoint(Map<String, dynamic> message) async {
  final localCancelToken = CancelToken();

  // Set up cancel receive port and send it back to the main isolate.
  // The main isolate will complete the bridge after receiving this SendPort.
  final cancelRp = ReceivePort();
  cancelRp.first.then((_) => localCancelToken.cancel());
  final handshakePort = message['cancelHandshakePort'] as SendPort;
  handshakePort.send(cancelRp.sendPort);

  // Phase 3: no-op hash cache — recomputes all hashes every scan.
  // Phase 6 (T034) will replace this block with Store.attach + HashCacheRepositoryImpl.
  final hashCache = _NoOpHashCacheRepository();

  final filePaths = List<String>.from(message['filePaths'] as List);
  final files = filePaths.map((p) => File(p)).toList();
  final concurrencyLimit = message['concurrencyLimit'] as int;
  final byteByByteCompare = message['byteByByteCompare'] as bool;
  final progressPort = message['progressPort'] as SendPort;

  void onProgress(ScanProgress p) => progressPort.send({
        'type': 'progress',
        'stageTotal': p.stageTotal,
        'stageProcessed': p.stageProcessed,
        'stage': p.stage,
      });

  final service = DuplicateFinderService(
    hashCache: hashCache,
    concurrencyLimit: concurrencyLimit,
  );

  try {
    final groups = await service.find(
      files: files,
      cancelToken: localCancelToken,
      onProgress: onProgress,
      byteByByteCompare: byteByByteCompare,
    );
    progressPort.send({
      'type': 'result',
      'groups': groups.map((g) => g.paths).toList(),
    });
  } on ScanCancelledException catch (e) {
    progressPort.send({
      'type': 'error',
      'cancelled': true,
      'message': e.message,
    });
  } on Exception catch (e) {
    progressPort.send({
      'type': 'error',
      'cancelled': false,
      'message': e.toString(),
    });
  }
  // Note: No store.close() in Phase 3 (no ObjectBox store opened).
  // Phase 6 (T034) will add try/finally { store.close(); } around this body.
}
