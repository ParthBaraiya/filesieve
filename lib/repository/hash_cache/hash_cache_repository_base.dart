import '../../models/file_hash_entity.dart';
import 'package:omnifile/omnifile.dart';

abstract class HashCacheRepositoryBase {
  FileHashEntity? getEntity(String? path);
  Future<void> savePartialHash(OmniFile meta, String hash);
  Future<void> saveFullHash(OmniFile meta, String hash);
}
