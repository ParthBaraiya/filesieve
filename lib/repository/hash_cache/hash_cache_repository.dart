import 'package:filesieve/utils/fs_file/fs_file.dart';

import '../../models/file_hash_entity.dart';
import '../../objectbox.g.dart';
import 'hash_cache_repository_base.dart';

/// ObjectBox-backed implementation of [HashCacheRepository].
///
/// Stores [FileHashEntity] records indexed on [FileHashEntity.path]
/// so that previously computed hashes can be reused on re-scans.
///
/// **Read-then-update invariants (FR-012, FR-013, FR-014)**:
/// - Both [savePartialHash] and [saveFullHash] read the existing entity first
///   so that the write preserves whichever hash field was NOT being updated.
/// - When a matching entity is found, its `id` is reused (`existing.id`)
///   so ObjectBox replaces the existing row rather than inserting a duplicate.
/// - If no entity exists for the path, `id = 0` causes ObjectBox to insert a
///   new row and assign a fresh auto-increment id.
class HashCacheRepository implements HashCacheRepositoryBase {
  HashCacheRepository(this._box);

  final Box<FileHashEntity> _box;

  /// Returns the cached entity for [path], or `null` if none exists.
  ///
  /// Uses the indexed [FileHashEntity_.path] property so the query is served
  /// by the ObjectBox B-tree index without a full table scan (FR-012).
  @override
  FileHashEntity? getEntity(String? path) => path == null
      ? null
      : _box.query(FileHashEntity_.path.equals(path)).build().findFirst();

  /// Saves (or updates) the partial hash for [meta.path].
  ///
  /// Reads the existing entity first so that any already-stored [FileHashEntity.fullHash]
  /// is preserved.
  @override
  Future<void> savePartialHash(FsFile meta, String hash) async {
    final existing = getEntity(meta.path);

    _box.put(
      FileHashEntity(
        id: existing?.id ?? 0,
        path: meta.path ?? '',
        size: (await meta.size) ?? 0,
        lastModified: meta.lastModified?.millisecondsSinceEpoch ?? 0,
        partialHash: hash,
        fullHash: existing?.fullHash, // preserve existing full hash
      ),
    );
  }

  /// Saves (or updates) the full hash for [meta.path].
  ///
  /// Reads the existing entity first so that any already-stored [FileHashEntity.partialHash]
  /// is preserved.
  @override
  Future<void> saveFullHash(FsFile meta, String hash) async {
    final existing = getEntity(meta.path);
    _box.put(
      FileHashEntity(
        id: existing?.id ?? 0,
        path: meta.path ?? '',
        size: (await meta.size) ?? 0,
        lastModified: meta.lastModified?.millisecondsSinceEpoch ?? 0,
        partialHash: existing?.partialHash, // preserve existing partial hash
        fullHash: hash,
      ),
    );
  }
}
