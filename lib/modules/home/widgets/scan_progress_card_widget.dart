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
  final VoidCallback onCancel;

  String _stageLabel(ScanProgressStage stage) {
    return switch (stage) {
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
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
              child: Text(AppStrings.scanProgressCancelButton),
            ),
          ],
        ),
      ),
    );
  }
}
