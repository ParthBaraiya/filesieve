# Skill: Scan Pipeline & Repository Layer

**Applies when**: Creating or modifying the duplicate detection pipeline, adding new scanning features, implementing hash caching, or extending the `DuplicateFinderRepository` interface.

**Constitution references**: Principle I (Layered Architecture), Principle II (Performance Engineering), Principle VI (Data Safety), Principle XIV (Worker Isolate), Principle XV (Incremental Pipeline)

---

## Pipeline Stages (Mandatory Order)

The staged filtering strategy MUST NOT be bypassed or reordered:

```
Stage 1: Metadata collection (statSync — skip zero-byte, inaccessible)
    ↓
Stage 2: Group by size → drop singletons → sort descending (largest first)
    ↓
Stage 3: Partial hash (first+last N bytes, semaphore-guarded, concurrent)
    ↓
Stage 4: Group by partial hash → drop singletons
    ↓
Stage 5: Full hash (skip files ≤ chunkSize — partial IS full hash)
    ↓
Stage 6: Group by full hash → confirmed duplicate groups
    ↓
Stage 7: [Optional] Byte-by-byte compare (recursive sub-grouping)
    ↓
Stage 8: Done — emit final progress, return results
```

**Each stage reduces the candidate set** before applying a more expensive operation. Skipping a stage wastes I/O.

---

## Repository Interface Contract

```dart
abstract class DuplicateFinderRepository {
  Future<List<DuplicateGroup>> find({
    required List<File> files,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
    void Function(DuplicateGroup, List<int> sizes)? onGroupFound,
  });
}
```

**Dual callback contract** (Principle XV):

- `onProgress` — per-file stage progress (stage name, total, processed, currentPath)
- `onGroupFound` — incremental result delivery as each group is confirmed

Results MUST NOT be withheld until pipeline completion.

---

## Hash Caching (ObjectBox)

### Cache Entity

```dart
@Entity()
class FileHashEntity {
  @Id() int id;
  @Index() String path;
  int size;
  int lastModified;
  String? partialHash;
  String? fullHash;
}
```

### Cache Hit Validation

A cache hit requires ALL three fields to match:

```dart
final cached = _hashCache.getEntity(meta.path);
if (cached != null &&
    cached.size == meta.size &&
    cached.lastModified == meta.lastModified &&
    cached.partialHash != null) {
  return cached.partialHash!; // HIT — skip file I/O
}
```

### Read-Then-Update Invariant

When saving a hash, ALWAYS preserve the other hash field:

```dart
void savePartialHash(FileMeta meta, String hash) {
  final existing = getEntity(meta.path);
  _box.put(FileHashEntity(
    id: existing?.id ?? 0,        // Reuse ID to prevent duplicates
    path: meta.path,
    size: meta.size,
    lastModified: meta.lastModified,
    partialHash: hash,
    fullHash: existing?.fullHash,  // PRESERVE existing full hash
  ));
}
```

---

## Small File Optimization

Files where `size ≤ chunkSize` (default 1 MB): the partial hash already covers 100% of the file content. The partial hash IS the full hash — skip the full hash stage:

```dart
if (meta.size <= HashUtils.chunkSize) {
  // Reuse partial hash — no second file read
  return MapEntry(meta, metaToPartialHash[meta]!);
}
```

---

## Byte-by-Byte Verification (Optional Stage 7)

When `byteByByteCompare = true`, each full-hash group is verified:

```dart
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
    try {
      final match = HashUtils.byteCompare(first, path);
      (match ? confirmed : excluded).add(path);
    } finally {
      _semaphore.release();
    }
  }

  final groups = <DuplicateGroup>[];
  if (confirmed.length >= 2) {
    groups.add(DuplicateGroup(paths: List.unmodifiable(confirmed)));
  }
  // CRITICAL: Recursively verify excluded files — they may form their own group
  if (excluded.length >= 2) {
    groups.addAll(await _byteVerifyGroup(excluded, cancelToken));
  }
  return groups;
}
```

**Recursive sub-grouping is mandatory**: Files excluded from one group must be compared among themselves. No true duplicate pair may be silently lost.

---

## FFI / Native Hashing Rules

- MD5 hashing MUST use C++ DLL (`hash_native.dll`) via `dart:ffi` on Windows
- Pure Dart `crypto` package is the fallback for non-Windows / test environments
- `HashUtils` abstracts the platform check:

```dart
static String partialHash(String path, {int chunkSize = 1048576}) {
  if (Platform.isWindows) {
    return nativeMd5Partial(path, chunkSize);
  }
  return _dartPartialHash(path, chunkSize: chunkSize);
}
```

- Native function calls MUST be wrapped with `calloc.free()` in `finally` blocks
- Hash functions are synchronous and MUST only run inside worker isolates

---

## Progress Emission Pattern

Every stage MUST emit progress with `currentPath`:

```dart
// At stage start
onProgress(ScanProgress(
  stage: 'partial',
  stageTotal: partialTotal,
  stageProcessed: 0,
  currentPath: '',
));

// After each file
onProgress(ScanProgress(
  stage: 'partial',
  stageTotal: partialTotal,
  stageProcessed: ++partialProcessed,
  currentPath: meta.path,
));
```

Stage names: `'scanning'`, `'partial'`, `'full'`, `'compare'`, `'done'`.

---

## Error Handling

- `FileSystemException` on `statSync` or file open → silently skip, continue scan
- `ScanCancelledException` → propagate to main isolate as `'error'` message with `cancelled: true`
- Other exceptions → propagate as `'error'` with `cancelled: false`
- Cache corruption → no special handling; cache miss triggers re-hash

---

## Adding a New Pipeline Stage

When extending the pipeline (e.g., adding similarity detection):

1. Add the stage between existing stages in `DuplicateFinderService.find()`
2. Define a new stage name string (e.g., `'similarity'`)
3. Emit progress at start and per-file within the stage
4. Guard all I/O with semaphore + cancelToken check
5. Add the stage label to `ScanStageIndicatorWidget._stageInfo()`
6. Add the stage label to `ScanProgressCardWidget._stageLabel()`
7. Add a weight band to `_computeOverallPercent()` in the cubit (adjust existing weights)
8. Add the new `'type'` message format to the worker→main message dispatch

---

## Checklist

- [ ] Pipeline stages follow the mandatory order (size → partial → full → optional compare)
- [ ] Repository exposes both `onProgress` and `onGroupFound` callbacks
- [ ] Cache hits validated on `(path, size, lastModified)` — all three fields
- [ ] Read-then-update preserves existing hash when saving the other
- [ ] Small files reuse partial hash as full hash — no second read
- [ ] Byte-by-byte verification recursively sub-groups excluded files
- [ ] Progress emitted per-file with `currentPath` for every stage
- [ ] Native FFI memory freed in `finally` blocks
- [ ] All file I/O guarded by semaphore + cancel token check
- [ ] Zero-byte files excluded before any grouping
