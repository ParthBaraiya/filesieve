import 'dart:collection';

import 'package:filesieve/models/fs_exception.dart';
import 'package:filesieve/models/scan_progress_model.dart';
import 'package:filesieve/utils/cancel_token.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'duplicate_group_cubit.dart';

part 'file_scanner_state.freezed.dart';

@freezed
sealed class FileScannerState with _$FileScannerState {
  const factory FileScannerState.initial() = FileScannerStateInitial;

  const factory FileScannerState.scanning({
    CancelToken? cancelToken,
    required ScanProgress progress,
    required UnmodifiableListView<DuplicateGroupCubit> groups,
    int? totalGroupBytes,
  }) = FileScannerStateScanningStarted;

  const factory FileScannerState.error({required FsException error}) =
      FileScannerStateError;

  const factory FileScannerState.success({
    required ScanProgress progress,
    required UnmodifiableListView<DuplicateGroupCubit> groups,
    int? totalGroupBytes,
  }) = FileScannerStateSuccess;
}

extension FileScannerStateX on FileScannerState {
  ScanProgress? get getProgress {
    switch (this) {
      case FileScannerStateScanningStarted():
        return (this as FileScannerStateScanningStarted).progress;

      case FileScannerStateSuccess():
        return (this as FileScannerStateSuccess).progress;
      case FileScannerStateInitial():
      case FileScannerStateError():
        return null;
    }
  }

  UnmodifiableListView<DuplicateGroupCubit> get getGroups {
    switch (this) {
      case FileScannerStateScanningStarted():
        return (this as FileScannerStateScanningStarted).groups;
      case FileScannerStateSuccess():
        return (this as FileScannerStateSuccess).groups;
      case FileScannerStateInitial():
      case FileScannerStateError():
        return UnmodifiableListView([]);
    }
  }
}
