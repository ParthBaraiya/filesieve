import 'package:filesieve/modules/home/duplicate_group_cubit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    @Default(
      ScanProgress(
        stageTotal: 0,
        stageProcessed: 0,
        stage: ScanProgressStage.extractMetadata,
      ),
    )
    ScanProgress progress,
    @Default(<DuplicateGroupCubit>[]) List<DuplicateGroupCubit> liveEntries,
    @Default(0) int filesAnalyzed,
    @Default(0.0) double overallPercent,
    @Default('') String currentFilePath,
  }) = HomeScreenScanning;

  const factory HomeScreenState.filePreview({
    HomeScreenScanning? scannedState,
    required DuplicateGroupCubit currentGroup,
  }) = HomeScreenFilePreview;
}

extension HomeScreenStateX on HomeScreenState {
  List<ScanFolderModel> get allFolders => switch (this) {
    HomeScreenInitial() => [],
    HomeScreenDragHover(:final folders) => folders,
    HomeScreenDropRejected(:final folders) => folders,
    HomeScreenFoldersAdded(:final folders) => folders,
    HomeScreenScanning(:final folders) => folders,
    HomeScreenFilePreview(:final scannedState) =>
      scannedState?.folders ?? [],
  };

  bool get hasFolders => allFolders.isNotEmpty;

  bool get isScanned =>
      (this is HomeScreenScanning &&
          (this as HomeScreenScanning).progress.stage == .completed) ||
      (this is HomeScreenFilePreview &&
          (this as HomeScreenFilePreview).scannedState != null);
}
