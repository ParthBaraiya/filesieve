import 'dart:io';

import 'package:filesieve/models/app_settings_model.dart';
import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:filesieve/models/scan_progress_model.dart';
import 'package:filesieve/repository/app_settings/app_settings_repository_base.dart';
import 'package:filesieve/repository/duplicate_finder/duplicate_finder_repository_base.dart';
import 'package:filesieve/repository/file_removal/file_removal_repository_base.dart';
import 'package:filesieve/utils/cancel_token.dart';
import 'package:omnifile/omnifile.dart';
import 'package:filesieve/values/enums.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFinder implements DuplicateFinderRepositoryBase {
  FakeFinder(this.groups);

  final List<DuplicateGroup> groups;

  @override
  Future<List<DuplicateGroup>> find({
    required List<Directory> folders,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
    bool includeSubfolders = true,
    bool skipHidden = true,
    void Function(DuplicateGroup)? onGroupFound,
    void Function(List<String> paths)? onFilesScanned,
  }) async {
    for (final g in groups) {
      onGroupFound?.call(g);
    }
    onProgress(
      const ScanProgress(
        stageTotal: 1,
        stageProcessed: 1,
        stage: ScanProgressStage.completed,
      ),
    );
    return groups;
  }
}

class FakeRemover implements FileRemovalRepositoryBase {
  final removed = <String, RemovalMode>{};
  final failing = <String>{};

  @override
  bool get canRestore => true;

  @override
  Future<void> remove(String path, RemovalMode mode) async {
    if (failing.contains(path)) throw FileRemovalException(path, 'locked');
    removed[path] = mode;
  }

  @override
  Future<bool> restore(String path) async => removed.remove(path) != null;

  @override
  Future<void> revealInFolder(String path) async {}
}

class MemorySettings implements AppSettingsRepositoryBase {
  @override
  Future<AppSettingsModel> load() async => const AppSettingsModel();
  @override
  Future<void> save(AppSettingsModel settings) async {}
  @override
  Future<void> clear() async {}
}

DuplicateGroup makeGroup(String name, int size, List<(String, int)> copies) {
  // copies: (folder, modified-day offset)
  return DuplicateGroup(
    files: [
      for (final (folder, day) in copies)
        OmniFile(
          source: OmniFileSource.local,
          path: 'C:\\$folder\\$name',
          size: size,
          lastModified: DateTime(2026, 1, 1).add(Duration(days: day)),
        ),
    ],
    totalGroupSize: size * copies.length,
  );
}

