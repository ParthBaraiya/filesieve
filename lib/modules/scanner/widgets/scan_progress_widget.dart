// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import '../../../models/scan_progress_model.dart';

// /// Displays a [LinearProgressIndicator] with a percentage label for the
// /// current [ScanProgress] snapshot.
// ///
// /// Consumed by [_ScanningSection] in `scanner_screen.dart` while the worker
// /// isolate is running.
// class ScanProgressWidget extends StatelessWidget {
//   const ScanProgressWidget({
//     super.key,
//     required this.progress,
//   });

//   final ScanProgress progress;

//   @override
//   Widget build(BuildContext context) {
//     final pct = (progress.progress * 100).toStringAsFixed(0);
//     final label = progress.stageTotal == 0
//         ? ''
//         : '${progress.stageProcessed} / ${progress.stageTotal}  ($pct%)';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         LinearProgressIndicator(
//           value: progress.stageTotal == 0 ? null : progress.progress,
//           minHeight: 6.h,
//         ),
//         SizedBox(height: 6.h),
//         Text(
//           label,
//           textAlign: TextAlign.end,
//           style: TextStyle(fontSize: 12.sp, color: Colors.grey),
//         ),
//       ],
//     );
//   }
// }
