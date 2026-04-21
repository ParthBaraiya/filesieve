import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../models/duplicate_group_model.dart';
import '../../models/file_hash_entity.dart';
import '../../models/scan_progress_model.dart';
import '../../objectbox.g.dart';
import '../../utils/duplicate_finder/duplicate_finder_service.dart';
import '../hash_cache/hash_cache_repository.dart';
import '../hash_cache/no_op_hash_cache_repository.dart';
import 'duplicate_finder_repository_base.dart';
import '../hash_cache/hash_cache_repository_base.dart';
import '../../utils/cancel_token.dart';

// ---------------------------------------------------------------------------
// Worker message types (worker→main)
// ---------------------------------------------------------------------------

sealed class _WorkerMessage {}

final class _ProgressMessage extends _WorkerMessage {
  _ProgressMessage({
    required this.stageTotal,
    required this.stageProcessed,
    required this.stage,
    required this.currentPath,
  });

  final int stageTotal;
  final int stageProcessed;
  final String stage;
  final String currentPath;
}

final class _ResultMessage extends _WorkerMessage {
  _ResultMessage({required this.groups});

  final List<DuplicateGroup> groups;
}

final class _ErrorMessage extends _WorkerMessage {
  _ErrorMessage({required this.cancelled, required this.message});

  final bool cancelled;
  final String message;
}

// ---------------------------------------------------------------------------
// Worker spawn message (main→worker, one-shot at isolate start)
// ---------------------------------------------------------------------------

class _WorkerSpawnMessage {
  const _WorkerSpawnMessage({
    required this.storePath,
    required this.folderPaths,
    required this.concurrencyLimit,
    required this.byteByByteCompare,
    required this.progressPort,
    required this.cancelHandshakePort,
  });

  final String storePath;
  final List<String> folderPaths;
  final int concurrencyLimit;
  final bool byteByByteCompare;
  final SendPort progressPort;
  final SendPort cancelHandshakePort;
}

// ---------------------------------------------------------------------------
// DuplicateFinderRepositoryImpl — main-isolate adapter
// ---------------------------------------------------------------------------

/// Main-isolate adapter that implements [DuplicateFinderRepositoryBase].
///
/// Owns all [Isolate.spawn] and [SendPort]/[ReceivePort] wiring.
/// The [DuplicateFinderService] pipeline is executed inside the worker isolate.
///
/// Cancel bridging uses a handshake pattern:
///   1. Worker sends its cancel [SendPort] back over [_cancelHandshakePort].
///   2. Repo registers a listener on [CancelToken.cancelFuture] that forwards
///      a `'cancel'` message to the worker when the token fires.
class DuplicateFinderRepository implements DuplicateFinderRepositoryBase {
  const DuplicateFinderRepository({
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
    required List<Directory> folders,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
    void Function(DuplicateGroup)? onGroupFound,
  }) async {
    // All worker→main messages (progress, result, error) arrive on this port.
    final resultRp = ReceivePort();

    // One-shot port: the worker sends back its local cancel SendPort here.
    final handshakeRp = ReceivePort();

    await Isolate.spawn<_WorkerSpawnMessage>(
      _workerEntrypoint,
      _WorkerSpawnMessage(
        storePath: storePath,
        folderPaths: folders.map((d) => d.path).toList(),
        concurrencyLimit: concurrencyLimit,
        byteByByteCompare: byteByByteCompare,
        progressPort: resultRp.sendPort,
        cancelHandshakePort: handshakeRp.sendPort,
      ),
    );

    // Await the worker's cancel SendPort to complete the handshake.
    final workerCancelSendPort = await handshakeRp.first as SendPort;
    handshakeRp.close();

    // Bridge: when cancelToken fires, forward the signal to the worker.
    // Safe to register after the handshake — cancelFuture is backed by a
    // Completer so it fires even if cancel() was called before this line.
    cancelToken.cancelFuture.then((_) => workerCancelSendPort.send('cancel'));

    final completer = Completer<List<DuplicateGroup>>();
    resultRp.listen((raw) {
      if (raw is DuplicateGroup) {
        onGroupFound?.call(raw);
        return;
      }

      final msg = raw as _WorkerMessage;
      switch (msg) {
        case _ProgressMessage():
          onProgress(
            ScanProgress(
              stageTotal: msg.stageTotal,
              stageProcessed: msg.stageProcessed,
              stage: msg.stage,
              currentPath: msg.currentPath,
            ),
          );
        case _ResultMessage():
          completer.complete(msg.groups);
          resultRp.close(); // no further messages expected after result
        case _ErrorMessage():
          completer.completeError(
            msg.cancelled
                ? ScanCancelledException(msg.message)
                : Exception(msg.message),
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
/// Opens the ObjectBox [Store] via [Store.attach] when a [storePath] is
/// provided (Phase 6+).  If [storePath] is empty, falls back to the no-op
/// cache so the pipeline still works without ObjectBox.
///
/// [Store.attach] is used (not `Store(...)`) because the main isolate already
/// holds an open [Store] on the same directory.  Opening a second independent
/// [Store] on the same path would cause file-lock contention on Windows.
Future<void> _workerEntrypoint(_WorkerSpawnMessage msg) async {
  final localCancelToken = CancelToken();

  // Set up cancel receive port and send it back to the main isolate.
  final cancelRp = ReceivePort();
  cancelRp.first.then((_) => localCancelToken.cancel());
  msg.cancelHandshakePort.send(cancelRp.sendPort);

  // Collect files from all provided folder paths inside the isolate.
  final files = <File>[];
  for (final folderPath in msg.folderPaths) {
    try {
      for (final entity in Directory(folderPath).listSync(recursive: true)) {
        if (entity is File) files.add(entity);
      }
    } on FileSystemException {
      // silently skip unreadable directories
    }
  }

  void onProgress(ScanProgress p) => msg.progressPort.send(
    _ProgressMessage(
      stageTotal: p.stageTotal,
      stageProcessed: p.stageProcessed,
      stage: p.stage,
      currentPath: p.currentPath,
    ),
  );

  // Attach to the main isolate's ObjectBox store (if a path was supplied).
  // A null store means the no-op cache is used instead.
  final Store? store = msg.storePath.isNotEmpty
      ? Store.attach(getObjectBoxModel(), msg.storePath)
      : null;

  try {
    final hashCache = store != null
        ? HashCacheRepository(store.box<FileHashEntity>())
        : NoOpHashCacheRepository();

    final service = DuplicateFinderService(
      hashCache: hashCache,
      concurrencyLimit: msg.concurrencyLimit,
    );

    try {
      final groups = await service.find(
        files: files,
        cancelToken: localCancelToken,
        onProgress: onProgress,
        byteByByteCompare: msg.byteByByteCompare,
        onGroupFound: (paths) {
          return msg.progressPort.send(paths);
        },
      );
      msg.progressPort.send(_ResultMessage(groups: groups));
    } on ScanCancelledException catch (e) {
      msg.progressPort.send(_ErrorMessage(cancelled: true, message: e.message));
    } on Exception catch (e) {
      msg.progressPort.send(
        _ErrorMessage(cancelled: false, message: e.toString()),
      );
    }
  } finally {
    store?.close(); // always release the ObjectBox file handle (FR-017)
  }
}
