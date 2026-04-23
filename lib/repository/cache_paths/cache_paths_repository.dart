import 'dart:io';

import 'package:filesieve/models/cache_path_entry_model.dart';
import 'package:filesieve/repository/cache_paths/cache_paths_repository_base.dart';
import 'package:filesieve/values/app_strings.dart';
import 'package:flutter/services.dart';

/// Concrete repository for resolving cache/storage paths.
///
/// NOTE: This implementation uses the injected `storePath` only and does not
/// access any global service locator or open an ObjectBox `Store`.
class CachePathsRepository implements CachePathsRepositoryBase {
  final String storePath;

  CachePathsRepository(this.storePath);

  @override
  Future<List<CachePathEntry>> resolveEntries() async {
    // Use injected store path only. Per spec the ObjectBox store and the
    // hash-cache may resolve to the same directory; we return separate
    // entries for both (do not merge), annotating existence.
    final objectboxPath = storePath;
    final hashCachePath = storePath;

    var objectboxExists = false;
    var hashCacheExists = false;

    if (objectboxPath.isNotEmpty) {
      try {
        objectboxExists = Directory(objectboxPath).existsSync();
      } catch (_) {
        objectboxExists = false;
      }
    }

    if (hashCachePath.isNotEmpty) {
      try {
        hashCacheExists = Directory(hashCachePath).existsSync();
      } catch (_) {
        hashCacheExists = false;
      }
    }

    return [
      CachePathEntry(
        id: 'objectbox',
        label: AppStrings.settingsCacheEntryObjectBoxLabel,
        path: objectboxPath,
        category: 'database',
        exists: objectboxExists,
      ),
      CachePathEntry(
        id: 'hash-cache',
        label: 'Hash Cache',
        path: hashCachePath,
        category: 'cache',
        exists: hashCacheExists,
      ),
    ];
  }

  @override
  Future<void> openFolder(String path) async {
    if (path.isEmpty) {
      throw CacheFolderOpenException('Path is empty');
    }

    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        throw CacheFolderOpenException('Directory does not exist');
      }

      late ProcessResult result;

      if (Platform.isWindows) {
        result = await Process.run('explorer.exe', [path]);
      } else if (Platform.isMacOS) {
        result = await Process.run('open', [path]);
      } else {
        // Fallback for Linux/other unix-like platforms
        result = await Process.run('xdg-open', [path]);
      }

      if (result.exitCode != 0) {
        throw CacheFolderOpenException('Process exited with code ${result.exitCode}');
      }
    } on CacheFolderOpenException {
      rethrow;
    } catch (e) {
      throw CacheFolderOpenException('Failed to open folder: $e');
    }
  }

  @override
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      throw CacheClipboardException('Failed to copy to clipboard: $e');
    }
  }
}

/// Exception thrown when copying to clipboard fails.
class CacheClipboardException implements Exception {
  final String message;
  CacheClipboardException(this.message);

  @override
  String toString() => 'CacheClipboardException: $message';
}

/// Exception thrown when opening a cache folder fails for any reason.
class CacheFolderOpenException implements Exception {
  final String message;
  CacheFolderOpenException(this.message);

  @override
  String toString() => 'CacheFolderOpenException: $message';
}
