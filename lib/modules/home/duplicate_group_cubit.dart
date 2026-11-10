import 'dart:io';

import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/fs_file/fs_file.dart';

class DuplicateGroupCubit extends Cubit<DuplicateGroupState> {
  DuplicateGroupCubit({required DuplicateGroup group})
    : super(DuplicateGroupState(group: group));

  void deleteFile(FsFile file) {
    if (state.group.files.length == 1) return;

    File(file.path!).deleteSync();

    var group = state.group.copyWith(
      files: [...state.group.files]..removeWhere((e) => e == file),
    );

    emit(state.copyWith(group: group));
  }
}

class DuplicateGroupState {
  final DuplicateGroup group;

  const DuplicateGroupState({required this.group});

  bool get hasFiles => group.hasFiles;

  DuplicateGroupState copyWith({DuplicateGroup? group}) =>
      DuplicateGroupState(group: group ?? this.group);
}
