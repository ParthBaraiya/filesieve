import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_state.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/scan_progress_model.dart';
import '../../../values/app_strings.dart';

class ScanProgressCardWidget extends StatelessWidget {
  const ScanProgressCardWidget({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<FileScannerCubit, FileScannerState>(
      bloc: context.read<HomeScreenCubit>().scanner,
      builder: (_, state) {
        final progressPercentage = switch (state) {
          FileScannerStateInitial() => 0,
          FileScannerStateScanningStarted() => state.progress.progress,
          FileScannerStateError() => 0,
          FileScannerStateSuccess() => 100,
        };

        final ScanProgressStage stage = switch (state) {
          FileScannerStateInitial() => .scanningFile,
          FileScannerStateScanningStarted() => state.progress.stage,
          FileScannerStateError() => .scanningFile,
          FileScannerStateSuccess() => .completed,
        };

        final filePath = switch (state) {
          FileScannerStateInitial() => null,
          FileScannerStateScanningStarted() => state.progress.currentPath,
          FileScannerStateError() => null,
          FileScannerStateSuccess() => null,
        };

        return Card(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}%',
                  style: textTheme.displayMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                LinearProgressIndicator(
                  value: progressPercentage.toDouble(),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                  minHeight: 6,
                ),
                SizedBox(height: 12.h),
                Text(
                  stage.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (filePath?.isNotEmpty ?? false) ...[
                  SizedBox(height: 4.h),
                  Text(
                    filePath!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 16.h),
                if (state is FileScannerStateScanningStarted)
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
      },
    );
  }
}
