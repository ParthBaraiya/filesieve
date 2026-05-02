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
