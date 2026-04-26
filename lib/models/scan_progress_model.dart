import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_progress_model.freezed.dart';

@freezed
abstract class ScanProgress with _$ScanProgress {
  const ScanProgress._();

  const factory ScanProgress({
    required int stageTotal,
    required int stageProcessed,
    required ScanProgressStage stage,
    @Default('') String currentPath,
  }) = _ScanProgress;

  double get progress =>
      stageTotal == 0 ? 0.0 : (stageProcessed / stageTotal).clamp(0.0, 1.0);
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
}
