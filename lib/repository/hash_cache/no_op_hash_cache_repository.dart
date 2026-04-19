import '../../models/file_hash_entity.dart';
import '../../models/file_meta_model.dart';
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
  FileHashEntity? getEntity(String path) => null;

  @override
  void savePartialHash(FileMeta meta, String hash) {}

  @override
  void saveFullHash(FileMeta meta, String hash) {}
}
