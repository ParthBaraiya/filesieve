# 🚀 Complete Business Logic – Duplicate File Comparison (With Progress + Cancellation + Priority Queue)

## 🎯 Objective

Implement a **high-performance duplicate file detection engine** with:

* Size filtering
* Partial + full hashing
* Persistent caching (ObjectBox)
* Parallel processing (Isolates-ready)
* Native acceleration (FFI-ready)
* ✅ Progress tracking (stage-relative — no overflow)
* ✅ Cancelable scan
* ✅ Priority-based processing (largest size-groups first)
* ✅ Bounded parallel I/O (semaphore, configurable concurrency limit)
* ✅ Optional byte-by-byte verification (flag-controlled)
* ✅ Zero-byte file exclusion
* ✅ Symlink support (follows symlinks to target)
* ✅ Safe cache writes (read-then-update, preserves both hash tiers)
* ✅ Small-file optimisation (skip full hash when size ≤ chunkSize)

---

# 🧠 Final Flow

```text id="flow_final"
Scan Files
 → Filter: skip zero-byte files; follow symlinks to target
 → Group by Size
 → Sort Size-Groups: largest size-group processed first (group-level priority)
 → Partial Hash (bounded parallel + cache; per-stage progress 0→100%)
 → Group by Partial Hash
 → Full Hash (bounded parallel + cache; skip if file size ≤ chunkSize)
 → [Optional] Byte-by-Byte Verification (only if byteByByteCompare = true)
 → Emit Stage-Relative Progress Updates
 → Return Duplicate Groups
```

---

# 🧱 Models

```dart id="models_final"
class FileMeta {
  final String path;
  final int size;
  final int lastModified;

  FileMeta({
    required this.path,
    required this.size,
    required this.lastModified,
  });
}

class DuplicateGroup {
  final List<String> paths;
  DuplicateGroup(this.paths);
}

/// Progress is tracked per-stage, not across all stages combined.
/// This prevents stageProcessed from ever exceeding stageTotal, which would
/// occur if a single counter spanned stages with shrinking candidate sets.
/// The UI should reset its progress bar whenever the stage name changes.
class ScanProgress {
  final int stageTotal;     // total operations in the current stage
  final int stageProcessed; // completed operations in the current stage
  final String stage;       // 'scanning' | 'partial' | 'full' | 'compare' | 'done'

  double get progress => stageTotal == 0 ? 0 : stageProcessed / stageTotal;

  ScanProgress({
    required this.stageTotal,
    required this.stageProcessed,
    required this.stage,
  });
}
```

---

# 🗄️ ObjectBox Entity

```dart id="objectbox_final"
@Entity()
class FileHashEntity {
  @Id()
  int id = 0;

  String path;
  int size;
  int lastModified;
  String? partialHash;
  String? fullHash;

  FileHashEntity({
    required this.path,
    required this.size,
    required this.lastModified,
    this.partialHash,
    this.fullHash,
  });
}
```

---

# 🗃️ Cache Repository

```dart id="cache_repo_final"
class HashCacheRepository {
  final Box<FileHashEntity> box;

  HashCacheRepository(this.box);

  FileHashEntity? get(String path) {
    final q = box.query(FileHashEntity_.path.equals(path)).build();
    final result = q.findFirst();
    q.close();
    return result;
  }

  void save(FileHashEntity entity) {
    box.put(entity);
  }
}
```

---

# ❌ Cancellation Token

```dart id="cancel_token_final"
class CancelToken {
  bool _isCancelled = false;

  void cancel() => _isCancelled = true;

  void throwIfCancelled() {
    if (_isCancelled) {
      throw Exception('Scan cancelled');
    }
  }
}
```

---

# ⚡ Hash Utils

```dart id="hash_utils_final"
class HashUtils {
  static const int chunkSize = 1024 * 1024; // 1 MB

  static Future<String> partial(File file) async {
    final raf = file.openSync();
    final size = raf.lengthSync();

    final bytes = <int>[];

    bytes.addAll(raf.readSync(size > chunkSize ? chunkSize : size));

    if (size > chunkSize) {
      raf.setPositionSync(size - chunkSize);
      bytes.addAll(raf.readSync(chunkSize));
    }

    raf.closeSync();

    return md5.convert(bytes).toString();
  }

  static Future<String> full(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Byte-by-byte comparison of two files.
  /// Returns true only when both files are absolutely identical in content.
  /// Used as the optional final verification stage (byteByByteCompare = true)
  /// to eliminate the theoretical (but rare) hash-collision false positive.
  static Future<bool> byteCompare(File a, File b) async {
    final iterA = StreamIterator(a.openRead());
    final iterB = StreamIterator(b.openRead());

    try {
      while (true) {
        final hasA = await iterA.moveNext();
        final hasB = await iterB.moveNext();

        if (hasA != hasB) return false; // one stream ended before the other

        if (!hasA) return true; // both exhausted — files are equal

        final chunkA = iterA.current;
        final chunkB = iterB.current;

        if (chunkA.length != chunkB.length) return false;
        for (int i = 0; i < chunkA.length; i++) {
          if (chunkA[i] != chunkB[i]) return false;
        }
      }
    } finally {
      await iterA.cancel();
      await iterB.cancel();
    }
  }
}
```

---

# 🧠 Priority Queue Strategy

## Why?

* Processing larger size-groups first maximises the chance of early candidate elimination
* Within a size group every file has the **same size** — sorting files *inside* a group by size is always a no-op and MUST NOT be applied
* Priority is therefore applied at the **group level**: iterate size-groups largest first

---

## Implementation

Sort size-group keys descending before iteration. The `prioritize()` helper on individual file lists is removed:

```dart id="priority_sort"
final sortedSizeKeys = sizeGroups.keys.toList()
  ..sort((a, b) => b.compareTo(a)); // largest size-group iterated first
```
```

---

# 🔒 Concurrency Pool (Semaphore)

`Future.wait` over hundreds of files simultaneously floods the OS with concurrent reads and causes I/O saturation (especially on spinning drives). A simple semaphore bounds the number of inflight operations.

```dart id="semaphore"
class _Semaphore {
  final int maxCount;
  int _count;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this.maxCount) : _count = maxCount;

  Future<void> acquire() async {
    if (_count > 0) {
      _count--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _count++;
    }
  }
}
```

The default concurrency limit is `4`. Caller may override via a constructor parameter.

---

# 🧠 Core Service (FINAL)

```dart id="service_final"
class DuplicateFinderService {
  final HashCacheRepository cache;

  /// Maximum number of files hashed concurrently.
  /// Prevents OS I/O saturation, especially on spinning drives.
  static const int _defaultConcurrency = 4;

  final int concurrencyLimit;

  DuplicateFinderService(this.cache, {this.concurrencyLimit = _defaultConcurrency});

  /// ⚠️ Isolate boundary: this entire method is intended to run inside a
  /// spawned Dart Isolate. The caller manages isolate lifecycles.
  /// [onProgress] bridges ScanProgress updates back to the main isolate
  /// via a SendPort wrapper.
  ///
  /// [byteByByteCompare] — when true, performs byte-by-byte verification
  /// after the full-hash stage. Eliminates hash-collision false positives.
  /// Controlled by caller; defaults to false.
  Future<List<DuplicateGroup>> find({
    required List<File> files,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
  }) async {
    final semaphore = _Semaphore(concurrencyLimit);

    // ── Step 1: Collect metadata ─────────────────────────────────────
    // Symlinks: File.statSync() follows the link to its target automatically.
    // Zero-byte files are excluded — they all match trivially and are not
    // meaningful duplicates.
    // Inaccessible files (locked / permission-denied / deleted) are silently
    // skipped.
    final metas = <FileMeta>[];
    for (final f in files) {
      cancelToken.throwIfCancelled();
      try {
        final stat = f.statSync();
        if (stat.size == 0) continue;
        metas.add(FileMeta(
          path: f.path,
          size: stat.size,
          lastModified: stat.modified.millisecondsSinceEpoch,
        ));
      } catch (_) {
        // Skip inaccessible file silently.
      }
    }

    onProgress(ScanProgress(
      stageTotal: metas.length,
      stageProcessed: metas.length,
      stage: 'scanning',
    ));
    cancelToken.throwIfCancelled();

    // ── Step 2: Group by size ────────────────────────────────────────
    final sizeGroups = <int, List<FileMeta>>{};
    for (final f in metas) {
      sizeGroups.putIfAbsent(f.size, () => []).add(f);
    }
    sizeGroups.removeWhere((_, v) => v.length < 2);

    // Group-level priority: iterate largest size-groups first.
    // Within a size group every file has the same size, so intra-group
    // sorting by size is a no-op and is intentionally omitted.
    final sortedSizeKeys = sizeGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // ── Step 3: Partial hash ─────────────────────────────────────────
    final partialCandidates = sortedSizeKeys
        .expand((k) => sizeGroups[k]!)
        .toList();

    int stageProcessed = 0;
    final partialGroups = <String, List<FileMeta>>{};

    onProgress(ScanProgress(
      stageTotal: partialCandidates.length,
      stageProcessed: 0,
      stage: 'partial',
    ));

    await Future.wait(partialCandidates.map((file) async {
      cancelToken.throwIfCancelled();
      await semaphore.acquire();
      try {
        cancelToken.throwIfCancelled();
        final hash = await _partial(file);
        partialGroups.putIfAbsent(hash, () => []).add(file);
      } catch (_) {
        // Skip inaccessible file silently.
      } finally {
        semaphore.release();
        stageProcessed++;
        onProgress(ScanProgress(
          stageTotal: partialCandidates.length,
          stageProcessed: stageProcessed,
          stage: 'partial',
        ));
      }
    }));

    partialGroups.removeWhere((_, v) => v.length < 2);

    // ── Step 4: Full hash ────────────────────────────────────────────
    // Group-level priority: largest groups first.
    // Small-file optimisation: if a file's size is ≤ chunkSize its partial
    // hash already covers the whole file — full hash is identical, so the
    // full-hash read is skipped and the partial hash is reused directly.
    final sortedPartialGroups = partialGroups.values.toList()
      ..sort((a, b) => b.first.size.compareTo(a.first.size));

    final fullCandidates = sortedPartialGroups
        .expand((g) => g)
        .where((f) => f.size > HashUtils.chunkSize)
        .toList();

    final smallFileCandidates = sortedPartialGroups
        .expand((g) => g)
        .where((f) => f.size <= HashUtils.chunkSize)
        .toList();

    stageProcessed = 0;
    final fullGroups = <String, List<FileMeta>>{};

    // Re-group small files under their partial hash — all cache hits, no I/O.
    for (final f in smallFileCandidates) {
      try {
        final hash = await _partial(f);
        fullGroups.putIfAbsent(hash, () => []).add(f);
      } catch (_) {
        // Skip inaccessible file silently.
      }
    }

    onProgress(ScanProgress(
      stageTotal: fullCandidates.length,
      stageProcessed: 0,
      stage: 'full',
    ));

    await Future.wait(fullCandidates.map((file) async {
      cancelToken.throwIfCancelled();
      await semaphore.acquire();
      try {
        cancelToken.throwIfCancelled();
        final hash = await _full(file);
        fullGroups.putIfAbsent(hash, () => []).add(file);
      } catch (_) {
        // Skip inaccessible file silently.
      } finally {
        semaphore.release();
        stageProcessed++;
        onProgress(ScanProgress(
          stageTotal: fullCandidates.length,
          stageProcessed: stageProcessed,
          stage: 'full',
        ));
      }
    }));

    fullGroups.removeWhere((_, v) => v.length < 2);

    // ── Step 5: Optional byte-by-byte verification ───────────────────
    // Only executes when byteByByteCompare = true.
    // Confirms every full-hash group with exact byte comparison before
    // including in results. Eliminates the theoretical (but rare)
    // hash-collision false positive.
    List<DuplicateGroup> results;
    if (byteByByteCompare) {
      stageProcessed = 0;
      final compareGroups = <List<String>>[];

      onProgress(ScanProgress(
        stageTotal: fullGroups.length,
        stageProcessed: 0,
        stage: 'compare',
      ));

      for (final group in fullGroups.values) {
        cancelToken.throwIfCancelled();
        try {
          final reference = File(group.first.path);
          final confirmedEqual = <String>[group.first.path];

          for (final candidate in group.skip(1)) {
            cancelToken.throwIfCancelled();
            try {
              if (await HashUtils.byteCompare(reference, File(candidate.path))) {
                confirmedEqual.add(candidate.path);
              }
            } catch (_) {
              // Skip inaccessible candidate silently.
            }
          }

          if (confirmedEqual.length >= 2) compareGroups.add(confirmedEqual);
        } catch (_) {
          // Skip inaccessible reference file silently.
        }
        stageProcessed++;
        onProgress(ScanProgress(
          stageTotal: fullGroups.length,
          stageProcessed: stageProcessed,
          stage: 'compare',
        ));
      }

      results = compareGroups.map((paths) => DuplicateGroup(paths)).toList();
    } else {
      results = fullGroups.values
          .map((g) => DuplicateGroup(g.map((e) => e.path).toList()))
          .toList();
    }

    onProgress(ScanProgress(
      stageTotal: results.length,
      stageProcessed: results.length,
      stage: 'done',
    ));

    return results;
  }

  Future<String> _partial(FileMeta meta) async {
    final existing = cache.get(meta.path);

    if (existing != null &&
        existing.size == meta.size &&
        existing.lastModified == meta.lastModified &&
        existing.partialHash != null) {
      return existing.partialHash!;
    }

    final hash = await HashUtils.partial(File(meta.path));

    // Read-then-update: preserve the existing ObjectBox id and the fullHash
    // already stored for this file. Avoids creating a duplicate entity and
    // avoids losing a fullHash that was computed in an earlier scan session.
    cache.save(FileHashEntity(
      id: existing?.id ?? 0,
      path: meta.path,
      size: meta.size,
      lastModified: meta.lastModified,
      partialHash: hash,
      fullHash: existing?.fullHash,
    ));

    return hash;
  }

  Future<String> _full(FileMeta meta) async {
    final existing = cache.get(meta.path);

    if (existing != null &&
        existing.size == meta.size &&
        existing.lastModified == meta.lastModified &&
        existing.fullHash != null) {
      return existing.fullHash!;
    }

    final hash = await HashUtils.full(File(meta.path));

    // Read-then-update: preserve the existing ObjectBox id and the partialHash
    // already stored for this file.
    cache.save(FileHashEntity(
      id: existing?.id ?? 0,
      path: meta.path,
      size: meta.size,
      lastModified: meta.lastModified,
      partialHash: existing?.partialHash,
      fullHash: hash,
    ));

    return hash;
  }
}
```

---

# ⚡ Key Features

## ✅ Group-Level Priority

* Largest size-groups iterated first for maximum early elimination
* Intra-group sorting by size is intentionally omitted (all files in a size group are the same size)

## ✅ Stage-Relative Progress Tracking

* Each stage reports its own 0→100% — no cross-stage counter overflow
* UI resets progress bar on stage transition
* Stages: `scanning` → `partial` → `full` → `compare` (optional) → `done`

## ✅ Bounded Parallel I/O

* `_Semaphore` limits concurrent file reads (default: 4)
* Prevents OS I/O saturation on both SSDs and spinning drives
* Concurrency limit configurable by caller

## ✅ Cancellation

* Safe interruption at any stage via `CancelToken`

## ✅ Safe Cache Writes (Read-Then-Update)

* `_partial` preserves the existing `fullHash` when saving a new `partialHash`
* `_full` preserves the existing `partialHash` when saving a new `fullHash`
* ObjectBox entity `id` is reused to prevent duplicate records

## ✅ Small-File Optimisation

* Files with `size ≤ chunkSize`: partial hash covers 100% of content; full hash read is skipped
* Partial hash is reused as the full-hash key directly (cache hit, no I/O)

## ✅ Zero-Byte File Exclusion

* Empty files are filtered out before any grouping — they match trivially and are not meaningful duplicates

## ✅ Symlink Support

* Symlinks are followed; `File.statSync()` resolves to the link target automatically
* Two symlinks pointing to the same target will naturally produce identical hashes and be grouped as duplicates

## ✅ Optional Byte-by-Byte Verification

* Controlled by `byteByByteCompare` flag on `find()`; off by default
* When enabled, each full-hash group undergoes exact byte comparison before being emitted
* Eliminates the theoretical hash-collision false positive

## ✅ Inaccessible File Handling

* Locked, permission-denied, or mid-scan-deleted files are silently skipped
* Scan continues without interruption

---

# 📌 Copilot Instructions

* Apply priority at the **group level** (sort size-group keys descending); never sort files within a size group by size
* Use `_Semaphore` for all `Future.wait` over file I/O; never use unbounded parallelism
* Use `ScanProgress(stageTotal, stageProcessed, stage)` — reset per stage; never accumulate across stages
* Silently skip any file that throws during `statSync`, partial hash, or full hash
* Exclude zero-byte files before any grouping
* Follow symlinks (no special handling needed: `File.statSync()` follows them automatically)
* In `_partial` and `_full`: always read the existing cache entity before saving; preserve the other hash tier and the ObjectBox `id`
* Skip the full hash read for files where `size <= HashUtils.chunkSize`; reuse partial hash as full-hash key
* `byteByByteCompare` stage is optional and flag-controlled; default is false
* Respect `cancelToken.throwIfCancelled()` inside every loop and async operation
* All hashing runs in a spawned Dart Isolate; `onProgress` bridges to main isolate via SendPort

---

# 🚀 Result

You now have a **production-grade duplicate detection engine** with:

* Smart prioritization
* Real-time progress
* Cancelable execution
* Scalable architecture

---
