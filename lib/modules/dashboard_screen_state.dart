import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/scan_folder_model.dart';

part 'dashboard_screen_state.freezed.dart';

@freezed
sealed class DashboardScreenState with _$DashboardScreenState {
  const factory DashboardScreenState.initial() = DashboardScreenInitial;
  const factory DashboardScreenState.dragHover() = DashboardScreenDragHover;
  const factory DashboardScreenState.dropRejected({required String reason}) =
      DashboardScreenDropRejected;
  const factory DashboardScreenState.foldersAdded({
    required List<ScanFolderModel> folders,
  }) = DashboardScreenFoldersAdded;
}
