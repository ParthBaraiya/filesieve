import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/format_utils.dart';
import '../../../values/app_strings.dart';

class ScanStatsCardWidget extends StatelessWidget {
  const ScanStatsCardWidget({
    super.key,
    required this.filesAnalyzed,
    required this.duplicatesFound,
    required this.totalDuplicateSizeBytes,
  });

  final int filesAnalyzed;
  final int duplicatesFound;
  final int totalDuplicateSizeBytes;

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
            _StatRow(
              label: AppStrings.scanStatsFiles,
              value: '$filesAnalyzed',
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: 16.h),
            _StatRow(
              label: AppStrings.scanStatsDuplicates,
              value: '$duplicatesFound',
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: 16.h),
            _StatRow(
              label: AppStrings.scanStatsSavings,
              value: formatBytes(totalDuplicateSizeBytes),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
