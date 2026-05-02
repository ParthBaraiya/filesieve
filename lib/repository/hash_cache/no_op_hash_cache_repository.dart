import 'package:filesieve/utils/fs_file/fs_file.dart';

import '../../models/file_hash_entity.dart';
import 'hash_cache_repository_base.dart';

// ---------------------------------------------------------------------------
// _NoOpHashCacheRepository — Phase 3 stub
// ---------------------------------------------------------------------------

/// No-operation hash cache used until the full ObjectBox-backed
/// [HashCacheRepositoryImpl] is wired in Phase 6 (T032 / T034).
///
/// All reads return `null` (cache miss), all writes are silent no-ops.
/// The pipeline still works correctly — it simply recomputes hashes every run.
class NoOpHashCacheRepository implements HashCacheRepositoryBase {
  @override
  FileHashEntity? getEntity(String? path) => null;

  @override
  Future<void> savePartialHash(FsFile meta, String hash) => Future.value();

  @override
  Future<void> saveFullHash(FsFile meta, String hash) => Future.value();
}
