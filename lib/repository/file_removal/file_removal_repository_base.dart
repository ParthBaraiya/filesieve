import '../../values/enums.dart';

/// Contract for removing duplicate files from disk.
abstract class FileRemovalRepositoryBase {
  /// Whether [restore] works on this platform (only for [RemovalMode.trash]).
  bool get canRestore;

  /// Removes [path] by moving it to the OS trash or deleting it for good.
  /// Throws a [FileRemovalException] when the file could not be removed.
  Future<void> remove(String path, RemovalMode mode);

  /// Puts a trashed file back at [path]. Returns false if it could not be
  /// found in the trash or the platform cannot restore.
  Future<bool> restore(String path);

  /// Opens the folder containing [path] in the system file manager.
  Future<void> revealInFolder(String path);
}

class FileRemovalException implements Exception {
  const FileRemovalException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'FileRemovalException($path): $message';
}
