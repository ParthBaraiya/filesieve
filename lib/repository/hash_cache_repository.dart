import '../models/file_hash_entity.dart';
import '../models/file_meta_model.dart';

abstract class HashCacheRepository {
  FileHashEntity? getEntity(String path);
  void savePartialHash(FileMeta meta, String hash);
  void saveFullHash(FileMeta meta, String hash);
}
