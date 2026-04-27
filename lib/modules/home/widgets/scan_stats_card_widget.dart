import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_state.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/format_utils.dart';
import '../../../values/app_strings.dart';

class ScanStatsCardWidget extends StatelessWidget {
  const ScanStatsCardWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<FileScannerCubit, FileScannerState>(
      bloc: context.read<HomeScreenCubit>().scanner,
      builder: (_, state) {
        final filesAnalyzed = switch(state) {
          FileScannerStateInitial() => 0,
          FileScannerStateScanningStarted() => state.progress.stageProcessed,
          FileScannerStateError() => 0,
          FileScannerStateSuccess() => 0,
        };

        final duplicatesFound = switch(state) {
          FileScannerStateInitial() => 0,
          FileScannerStateScanningStarted() => state.groups.length,
          FileScannerStateError() => 0,
          FileScannerStateSuccess() => 0,
        };
        
        final totalDuplicateSizeBytes = switch(state) {
          FileScannerStateInitial() => 0,
          FileScannerStateScanningStarted() => state.totalGroupBytes ?? 0,
          FileScannerStateError() => 0,
          FileScannerStateSuccess() => 0,
        };

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
