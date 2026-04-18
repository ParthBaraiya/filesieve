import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shows a human-readable label and icon for the current pipeline [stage].
///
/// Stages emitted by [DuplicateFinderService]:
/// - `'scanning'` — metadata collection
/// - `'partial'`  — partial hash pass
/// - `'full'`     — full hash pass
/// - `'compare'`  — byte-by-byte compare pass (Phase 7)
/// - `'done'`     — scan finished
///
/// Consumed by [_ScanningSection] in `scanner_screen.dart`.
class ScanStageIndicatorWidget extends StatelessWidget {
  const ScanStageIndicatorWidget({
    super.key,
    required this.stage,
  });

  final String stage;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _stageInfo(stage);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.r),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(fontSize: 14.sp)),
      ],
    );
  }

  (String, IconData) _stageInfo(String stage) => switch (stage) {
        'scanning' => ('Collecting file metadata…', Icons.folder_outlined),
        'partial' => ('Computing partial hashes…', Icons.fingerprint),
        'full' => ('Computing full hashes…', Icons.rule),
        'compare' => ('Verifying byte-by-byte…', Icons.compare),
        'done' => ('Finalising results…', Icons.check_circle_outline),
        _ => ('Scanning…', Icons.hourglass_bottom),
      };
}
