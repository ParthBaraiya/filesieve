import 'dart:io';

import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:filesieve/modules/home/duplicate_group_cubit.dart';
import 'package:filesieve/utils/fs_file/fs_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DuplicateFilePreviewBodyCubit
    extends Cubit<DuplicateFilePreviewBodyState> {
  DuplicateFilePreviewBodyCubit({
    required DuplicateGroupCubit group,
    required FsFile file,
  }) : super(DuplicateFilePreviewBodyState(group: group, selectedFile: file));

  void selectFile(FsFile file) {
    emit(state.copyWith(selectedFile: file));
  }

  void deleteFile(FsFile file) {
    if (state.group.state.group.files.length <= 1) return;

    state.group.deleteFile(file);
    var selected = state.selectedFile;
    if (file == state.selectedFile) {
      selected = state.group.state.group.files.first;
    }

    emit(state.copyWith(selectedFile: selected));
  }
}

class DuplicateFilePreviewBodyState {
  final DuplicateGroupCubit group;
  final FsFile selectedFile;

  const DuplicateFilePreviewBodyState({
    required this.group,
    required this.selectedFile,
  });

  DuplicateFilePreviewBodyState copyWith({
    DuplicateGroupCubit? group,
    FsFile? selectedFile,
  }) {
    return DuplicateFilePreviewBodyState(
      group: group ?? this.group,
      selectedFile: selectedFile ?? this.selectedFile,
    );
  }
}
