import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/scan_duplicate_entry_model.dart';
import '../../models/scan_folder_model.dart';
import '../../models/scan_progress_model.dart';

part 'home_screen_state.freezed.dart';

@freezed
sealed class HomeScreenState with _$HomeScreenState {
  const factory HomeScreenState.initial() = HomeScreenInitial;
  const factory HomeScreenState.dragHover({
    @Default([]) List<ScanFolderModel> folders,
  }) = HomeScreenDragHover;
  const factory HomeScreenState.dropRejected({
    required String reason,
    @Default([]) List<ScanFolderModel> folders,
  }) = HomeScreenDropRejected;
  const factory HomeScreenState.foldersAdded({
    required List<ScanFolderModel> folders,
  }) = HomeScreenFoldersAdded;
  const factory HomeScreenState.scanning({
    required List<ScanFolderModel> folders,
    @Default(ScanProgress(stageTotal: 0, stageProcessed: 0, stage: 'scanning'))
    ScanProgress progress,
    @Default(<DuplicateGroup>[]) List<DuplicateGroup> liveEntries,
    @Default(0) int filesAnalyzed,
    @Default(0.0) double overallPercent,
    @Default('') String currentFilePath,
  }) = HomeScreenScanning;
}

extension HomeScreenStateX on HomeScreenState {
  List<ScanFolderModel> get allFolders => switch (this) {
    HomeScreenInitial() => [],
    HomeScreenDragHover(:final folders) => folders,
    HomeScreenDropRejected(:final folders) => folders,
    HomeScreenFoldersAdded(:final folders) => folders,
    HomeScreenScanning(:final folders) => folders,
  };

  bool get hasFolders => allFolders.isNotEmpty;
}
