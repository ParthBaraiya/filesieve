// ---------------------------------------------------------------------------
// DuplicateFinderService — internal pipeline engine (runs in worker isolate)
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:filesieve/utils/classes/fs_semaphore.dart';

import '../../models/duplicate_group_model.dart';
import '../../models/file_meta_model.dart';
import '../../models/scan_progress_model.dart';
import '../../repository/hash_cache/hash_cache_repository_base.dart';
import '../cancel_token.dart';
import '../hash_utils.dart';

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
    required HashCacheRepositoryBase hashCache,
    int concurrencyLimit = 4,
  }) : _hashCache = hashCache,
       _semaphore = FsSemaphore(concurrencyLimit);

  final HashCacheRepositoryBase _hashCache;
  final FsSemaphore _semaphore;

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
    void Function(DuplicateGroup, List<int> sizes)? onGroupFound,
  }) async {
    // -----------------------------------------------------------------------
    // Stage 1: Metadata collection
    // -----------------------------------------------------------------------
    final metaList = <FileMeta>[];
    for (final file in files) {
      try {
        final stat = file.statSync();
        if (stat.size == 0) continue; // zero-byte files cannot be duplicates
        metaList.add(
          FileMeta(
            path: file.path,
            size: stat.size,
            lastModified: stat.modified.millisecondsSinceEpoch,
          ),
        );
      } on FileSystemException {
        continue; // skip inaccessible / permission-denied files
      }
    }

    onProgress(
      ScanProgress(
        stage: 'scanning',
        stageTotal: metaList.length,
        stageProcessed: metaList.length,
      ),
    );

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
      onProgress(
        ScanProgress(
          stage: 'partial',
          stageTotal: partialTotal,
          stageProcessed: 0,
        ),
      );

      final hashFutures = sizeCandidates.map((meta) async {
        cancelToken.throwIfCancelled();
        // Cache hit: entity non-null AND size+lastModified match AND hash present.
        final cached = _hashCache.getEntity(meta.path);
        if (cached != null &&
            cached.size == meta.size &&
            cached.lastModified == meta.lastModified &&
            cached.partialHash != null) {
          onProgress(
            ScanProgress(
              stage: 'partial',
              stageTotal: partialTotal,
              stageProcessed: ++partialProcessed,
              currentPath: meta.path,
            ),
          );
          return MapEntry(meta, cached.partialHash!);
        }
        await _semaphore.acquire();
        try {
          cancelToken.throwIfCancelled();
          final hash = HashUtils.partialHash(meta.path);
          _hashCache.savePartialHash(meta, hash);
          onProgress(
            ScanProgress(
              stage: 'partial',
              stageTotal: partialTotal,
              stageProcessed: ++partialProcessed,
              currentPath: meta.path,
            ),
          );
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
      onProgress(
        ScanProgress(stage: 'full', stageTotal: fullTotal, stageProcessed: 0),
      );

      final hashFutures = partialCandidates.map((meta) async {
        if (meta.size <= HashUtils.chunkSize) {
          // Partial hash covers the complete file for small files.
          onProgress(
            ScanProgress(
              stage: 'full',
              stageTotal: fullTotal,
              stageProcessed: ++fullProcessed,
              currentPath: meta.path,
            ),
          );
          return MapEntry(meta, metaToPartialHash[meta]!);
        }
        cancelToken.throwIfCancelled();
        // Cache hit: entity non-null AND size+lastModified match AND full hash present.
        final cached = _hashCache.getEntity(meta.path);
        if (cached != null &&
            cached.size == meta.size &&
            cached.lastModified == meta.lastModified &&
            cached.fullHash != null) {
          onProgress(
            ScanProgress(
              stage: 'full',
              stageTotal: fullTotal,
              stageProcessed: ++fullProcessed,
              currentPath: meta.path,
            ),
          );
          return MapEntry(meta, cached.fullHash!);
        }
        await _semaphore.acquire();
        try {
          cancelToken.throwIfCancelled();
          final hash = HashUtils.fullHash(meta.path);
          _hashCache.saveFullHash(meta, hash);
          onProgress(
            ScanProgress(
              stage: 'full',
              stageTotal: fullTotal,
              stageProcessed: ++fullProcessed,
              currentPath: meta.path,
            ),
          );
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
    final duplicateGroups = <DuplicateGroup>[];
    final fullHashGroups = <DuplicateGroup>[];
    for (final g in fullHashMap.values.where((g) => g.length >= 2)) {
      final group = DuplicateGroup(
        paths: List.unmodifiable(g.map((m) => m.path)),
      );
      final sizes = g.map((m) => m.size).toList();
      onGroupFound?.call(group, sizes);
      duplicateGroups.add(group);
      fullHashGroups.add(group);
    }

    // -----------------------------------------------------------------------
    // Stage 7: Byte-by-byte compare (skipped when byteByByteCompare == false)
    //
    // For each full-hash group, every file is compared byte-for-byte against
    // the first file.  Matching files form a confirmed sub-group; excluded
    // files are recursively verified against each other so that any genuine
    // identical pair among them is still surfaced (SC-006).
    // Each comparison is guarded by the semaphore (FR-010) and checked for
    // cancellation before acquiring (FR-016).
    // -----------------------------------------------------------------------
    if (byteByByteCompare && fullHashGroups.isNotEmpty) {
      duplicateGroups.clear();
      final compareTotal = fullHashGroups.length;
      int compareProcessed = 0;
      onProgress(
        ScanProgress(
          stage: 'compare',
          stageTotal: compareTotal,
          stageProcessed: 0,
        ),
      );
      for (final group in fullHashGroups) {
        cancelToken.throwIfCancelled();
        final verified = await _byteVerifyGroup(group.paths, cancelToken);
        duplicateGroups.addAll(verified);
        onProgress(
          ScanProgress(
            stage: 'compare',
            stageTotal: compareTotal,
            stageProcessed: ++compareProcessed,
          ),
        );
      }
    }

    // -----------------------------------------------------------------------
    // Stage 8: Emit done and return
    // -----------------------------------------------------------------------
    onProgress(ScanProgress(stage: 'done', stageTotal: 0, stageProcessed: 0));
    return duplicateGroups;
  }

  /// Verifies [paths] (a hash-confirmed group) using byte-for-byte comparison.
  ///
  /// Compares every file against the first via the semaphore-guarded
  /// [HashUtils.byteCompare].  Matching files accumulate in `confirmed`;
  /// non-matching files accumulate in `excluded`.
  ///
  /// If `excluded` has ≥ 2 entries the method calls itself recursively so that
  /// any genuine identical pair among the excluded files still forms a
  /// [DuplicateGroup] (SC-006: all true duplicates must appear in results even
  /// if they were separated from a larger group due to a hash collision).
  ///
  /// Returns a list of [DuplicateGroup]s with ≥ 2 paths each.
  Future<List<DuplicateGroup>> _byteVerifyGroup(
    List<String> paths,
    CancelToken cancelToken,
  ) async {
    if (paths.length < 2) return const [];

    final first = paths[0];
    final confirmed = <String>[first];
    final excluded = <String>[];

    for (final path in paths.sublist(1)) {
      cancelToken.throwIfCancelled();
      await _semaphore.acquire();
      final bool match;
      try {
        cancelToken.throwIfCancelled();
        match = HashUtils.byteCompare(first, path);
      } finally {
        _semaphore.release();
      }
      if (match) {
        confirmed.add(path);
      } else {
        excluded.add(path);
      }
    }

    final groups = <DuplicateGroup>[];
    if (confirmed.length >= 2) {
      groups.add(DuplicateGroup(paths: List.unmodifiable(confirmed)));
    }
    // Recursively verify excluded files — they may still form duplicate pairs.
    if (excluded.length >= 2) {
      groups.addAll(await _byteVerifyGroup(excluded, cancelToken));
    }
    return groups;
  }
}
