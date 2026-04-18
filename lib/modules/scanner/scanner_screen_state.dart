import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/duplicate_group_model.dart';
import '../../models/scan_progress_model.dart';

part 'scanner_screen_state.freezed.dart';

@freezed
sealed class ScannerScreenState with _$ScannerScreenState {
  /// No scan in progress. [selectedPaths] holds directories chosen by the user.
  const factory ScannerScreenState.initial({
    @Default(<String>[]) List<String> selectedPaths,
  }) = ScannerInitial;

  /// Scan is running. [groups] accumulates confirmed duplicate groups as they
  /// are found (populated in Phase 4 / T025; empty list in Phase 3).
  /// [progress] reflects the current pipeline stage and file count.
  const factory ScannerScreenState.scanning({
    required List<DuplicateGroup> groups,
    @Default(ScanProgress(stageTotal: 0, stageProcessed: 0, stage: 'scanning'))
    ScanProgress progress,
  }) = ScannerScanning;

  /// Scan finished successfully. [groups] is the complete list of duplicates.
  const factory ScannerScreenState.done({
    required List<DuplicateGroup> groups,
  }) = ScannerDone;

  /// Scan failed with an unrecoverable error. [message] describes the failure.
  /// [groups] preserves any groups accumulated before the failure.
  const factory ScannerScreenState.error({
    required String message,
    required List<DuplicateGroup> groups,
  }) = ScannerError;

  /// Scan was cancelled by the user. [groups] contains any duplicate groups
  /// that were confirmed before cancellation.
  const factory ScannerScreenState.cancelled({
    required List<DuplicateGroup> groups,
  }) = ScannerCancelled;
}

/// Convenience extension for cross-variant group access.
extension ScannerScreenStateX on ScannerScreenState {
  /// Returns the duplicate groups available in the current state, or an empty
  /// list when no scan has been run yet.
  List<DuplicateGroup> get allGroups => switch (this) {
        ScannerInitial() => const [],
        ScannerScanning(:final groups) => groups,
        ScannerDone(:final groups) => groups,
        ScannerError(:final groups) => groups,
        ScannerCancelled(:final groups) => groups,
      };
}
