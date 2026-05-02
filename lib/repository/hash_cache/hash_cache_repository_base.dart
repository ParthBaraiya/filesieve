import '../../models/file_hash_entity.dart';
import '../../utils/fs_file/fs_file.dart';

abstract class HashCacheRepositoryBase {
  FileHashEntity? getEntity(String? path);
  Future<void> savePartialHash(FsFile meta, String hash);
  Future<void> saveFullHash(FsFile meta, String hash);
}
