import 'package:filesieve/models/cache_path_entry_model.dart';

abstract class CachePathsRepositoryBase {
  /// Resolve configured cache/storage entries used by the app.
  Future<List<CachePathEntry>> resolveEntries();

  /// Open the given folder in the host OS file manager.
  Future<void> openFolder(String path);

  /// Copy the given text to the system clipboard.
  Future<void> copyToClipboard(String text);
}
