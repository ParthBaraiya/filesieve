import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/scan_progress_model.dart';
import '../../../values/app_strings.dart';

class ScanProgressCardWidget extends StatelessWidget {
  const ScanProgressCardWidget({
    super.key,
    required this.overallPercent,
    required this.progress,
    required this.currentFilePath,
    required this.onCancel,
  });

  final double overallPercent;
  final ScanProgress progress;
  final String currentFilePath;

  // ignore: unused_field — button wired in T020 (Phase 5 / US4)
  final VoidCallback onCancel;

  String _stageLabel(String stage) {
    switch (stage) {
      case 'scanning':
        return AppStrings.scanProgressAnalysing;
      case 'partial':
        return 'Computing partial hashes…';
      case 'full':
        return 'Computing full hashes…';
      case 'compare':
        return 'Comparing files…';
      case 'done':
        return 'Scan complete';
      default:
        return AppStrings.scanProgressAnalysing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${overallPercent.toStringAsFixed(0)}%',
              style: textTheme.displayMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),
            LinearProgressIndicator(
              value: overallPercent / 100,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 6,
            ),
            SizedBox(height: 12.h),
            Text(
              _stageLabel(progress.stage),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (currentFilePath.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                currentFilePath,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
