import 'package:filesieve/models/fs_exception.dart';
import 'package:filesieve/models/scan_progress_model.dart';
import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_state.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../values/app_palette.dart';
import '../../../values/app_routes.dart';
import '../../../values/app_strings.dart';
import 'scan_files_card_widget.dart';
import 'scan_progress_card_widget.dart';
import 'scan_stats_card_widget.dart';

/// ScanProgressBody — the "Scanning N folders" screen: header with Cancel (or
/// "Review duplicates" when finished), progress card and live counters.
class ScanProgressBody extends StatelessWidget {
  const ScanProgressBody({
    super.key,
    required this.folderCount,
    required this.onCancel,
  });

  final int folderCount;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final home = context.read<HomeScreenCubit>();

    return BlocConsumer<FileScannerCubit, FileScannerState>(
      bloc: home.scanner,
      listener: (context, state) {
        // A cancelled scan simply returns to the folder setup.
        if (state case FileScannerStateError(:final error)
            when error.code == FsExceptionCodes.scanCancelled) {
          home.dismissTransient();
        }
      },
      builder: (context, state) {
        if (state case FileScannerStateError(:final error)
            when error.code != FsExceptionCodes.scanCancelled) {
          return _ScanFailed(error: error, onBack: home.dismissTransient);
        }

        final progress = state.getProgress ?? ScanProgress.zero;
        final done = progress.stage.isCompleted;
        var extraCopies = 0;
        var reclaimable = 0;
        var groups = 0;
        for (final cubit in state.getGroups) {
          final group = cubit.state.group;
          final n = group.files.length;
          if (n < 2) continue;
          groups++;
          extraCopies += n - 1;
          reclaimable += group.totalGroupSize * (n - 1) ~/ n;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(32.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: done
                    ? AppStrings.scanComplete
                    : 'Scanning $folderCount ${folderCount == 1 ? 'folder' : 'folders'}',
                subtitle: done
                    ? 'Found $groups ${groups == 1 ? 'group' : 'groups'} of identical files'
                    : AppStrings.scanUsuallyTakes,
                done: done,
                onCancel: onCancel,
                onReview: () => context.go(AppRoutes.results),
              ),
              SizedBox(height: 20.h),
              ScanProgressCardWidget(progress: progress),
              SizedBox(height: 20.h),
              ScanStatsCardWidget(
                groups: groups,
                extraCopies: extraCopies,
                reclaimableBytes: reclaimable,
              ),
              if (home.scanner.scannedFiles.isNotEmpty) ...[
                SizedBox(height: 20.h),
                ScanFilesCardWidget(files: home.scanner.scannedFiles),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onCancel,
    required this.onReview,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16.w,
      runSpacing: 12.h,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              key: const ValueKey('scan.title'),
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.56,
                color: palette.text,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14.sp, color: palette.muted),
            ),
          ],
        ),
        if (done)
          FilledButton(
            key: const ValueKey('scan.reviewDuplicates'),
            onPressed: onReview,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.brand,
              minimumSize: Size(0, 44.h),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11.r)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(AppStrings.scanReviewDuplicates),
                SizedBox(width: 10.w),
                Icon(Icons.arrow_forward, size: 16.r),
              ],
            ),
          )
        else
          OutlinedButton(
            key: const ValueKey('scan.cancel'),
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.danger,
              side: BorderSide(color: palette.line),
              minimumSize: Size(0, 40.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text(AppStrings.scanCancel),
          ),
      ],
    );
  }
}

class _ScanFailed extends StatelessWidget {
  const _ScanFailed({required this.error, required this.onBack});

  final FsException error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480.w),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: palette.dangerLine),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error.title,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                error.description,
                style: TextStyle(fontSize: 14.sp, color: palette.muted),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                key: const ValueKey('scan.failedBack'),
                onPressed: onBack,
                child: const Text(AppStrings.scanFailedBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
