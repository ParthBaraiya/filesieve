import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_progress_model.freezed.dart';

@freezed
abstract class ScanProgress with _$ScanProgress {
  const ScanProgress._();

  const factory ScanProgress({
    required int stageTotal,
    required int stageProcessed,
    required String stage,
  }) = _ScanProgress;

  double get progress =>
      stageTotal == 0 ? 0.0 : (stageProcessed / stageTotal).clamp(0.0, 1.0);
}
