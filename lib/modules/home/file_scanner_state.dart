import 'dart:collection';

import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:filesieve/models/fs_exception.dart';
import 'package:filesieve/models/scan_progress_model.dart';
import 'package:filesieve/utils/cancel_token.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_scanner_state.freezed.dart';

@freezed
sealed class FileScannerState with _$FileScannerState {
  const factory FileScannerState.initial() = FileScannerStateInitial;

  const factory FileScannerState.scanning({
    CancelToken? cancelToken,
    required ScanProgress progress,
    required UnmodifiableListView<DuplicateGroup> groups,
    int? totalGroupBytes,
  }) = FileScannerStateScanningStarted;

  const factory FileScannerState.error({required FsException error}) =
      FileScannerStateError;

  const factory FileScannerState.success() = FileScannerStateSuccess;
}
