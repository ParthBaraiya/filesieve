import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/scan_folder_model.dart';

part 'home_screen_state.freezed.dart';

@freezed
sealed class HomeScreenState with _$HomeScreenState {
  const factory HomeScreenState.initial() = HomeScreenInitial;
  const factory HomeScreenState.dragHover() = HomeScreenDragHover;
  const factory HomeScreenState.dropRejected({
    required String reason,
  }) = HomeScreenDropRejected;
  const factory HomeScreenState.foldersAdded({
    required List<ScanFolderModel> folders,
  }) = HomeScreenFoldersAdded;
}
