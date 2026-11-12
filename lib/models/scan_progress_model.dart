import 'package:freezed_annotation/freezed_annotation.dart';

import '../values/app_strings.dart';

part 'scan_progress_model.freezed.dart';

@freezed
abstract class ScanProgress with _$ScanProgress {
  const ScanProgress._();

  const factory ScanProgress({
    required int stageTotal,
    required int stageProcessed,
    required ScanProgressStage stage,
    String? currentPath,
  }) = _ScanProgress;

  double get progress =>
      stageTotal == 0 ? 0.0 : (stageProcessed / stageTotal).clamp(0.0, 1.0);

  static const zero = ScanProgress(
    stageTotal: 1,
    stageProcessed: 0,
    stage: .scanningFile,
  );
}

enum ScanProgressStage {
  scanningFile,
  extractMetadata,
  groupingBySize,
  calcPartialHash,
  groupingByPartialHash,
  calcFullHash,
  groupingByFullHash,
  byteByByteCompare,
  completed;

  bool get isCompleted => this == .completed;
  bool get isScanning => !isCompleted;

  String get description => switch (this) {
    .scanningFile => AppStrings.scanProgressAnalysing,
    .calcPartialHash => 'Computing partial hashes…',
    .calcFullHash => 'Computing full hashes…',
    .byteByByteCompare => 'Comparing files…',
    .completed => 'Scan complete',
    .extractMetadata => 'Extracting files metadata',
    .groupingBySize => 'Grouping files by size',
    .groupingByPartialHash => 'Grouping files by partial hash',
    .groupingByFullHash => 'Grouping files by full hash',
  };
}

extension ScanProgressX on ScanProgress {
  /// Whole-scan progress from 0 to 100, weighting each pipeline stage by its
  /// typical share of the work.
  double get overallPercent {
    final ratio = progress;
    return switch (stage) {
      ScanProgressStage.scanningFile => ratio * 5,
      ScanProgressStage.extractMetadata => 5 + ratio * 5,
      ScanProgressStage.groupingBySize => 10 + ratio * 5,
      ScanProgressStage.calcPartialHash => 15 + ratio * 15,
      ScanProgressStage.groupingByPartialHash => 30 + ratio * 5,
      ScanProgressStage.calcFullHash => 35 + ratio * 20,
      ScanProgressStage.groupingByFullHash => 55 + ratio * 15,
      ScanProgressStage.byteByByteCompare => 70 + ratio * 29,
      ScanProgressStage.completed => 100,
    };
  }
}

extension ScanProgressStageX on ScanProgressStage {
  /// Which of the three user-facing phases this stage belongs to:
  /// 0 = list files, 1 = match by size, 2 = verify contents.
  int get phase => switch (this) {
    ScanProgressStage.scanningFile ||
    ScanProgressStage.extractMetadata => 0,
    ScanProgressStage.groupingBySize ||
    ScanProgressStage.calcPartialHash ||
    ScanProgressStage.groupingByPartialHash => 1,
    _ => 2,
  };
}
