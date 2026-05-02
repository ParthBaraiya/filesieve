import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_state.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'scan_live_feed_widget.dart';
import 'scan_progress_card_widget.dart';
import 'scan_stats_card_widget.dart';

class ScanProgressBody extends StatelessWidget {
  const ScanProgressBody({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scanner = context.read<HomeScreenCubit>().scanner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<FileScannerCubit, FileScannerState>(
          bloc: scanner,
          builder: (_, state) {
            if (!(state is! FileScannerStateScanningStarted ||
                state.progress.stage != .completed)) {
              return SizedBox.shrink();
            }

            return Padding(
              padding: .only(bottom: 16.sp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: ScanProgressCardWidget(onCancel: onCancel),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(flex: 4, child: const ScanStatsCardWidget()),
                ],
              ),
            );
          },
        ),
        Expanded(child: const ScanLiveFeedWidget()),
        BlocBuilder<FileScannerCubit, FileScannerState>(
          bloc: scanner,
          builder: (_, state) {
            if (state is! FileScannerStateScanningStarted ||
                state.progress.stage != .completed) {
              return SizedBox.shrink();
            }

            final filesAnalyzed = switch (state) {
              FileScannerStateInitial() => 0,
              FileScannerStateScanningStarted() =>
                state.progress.stageProcessed,
            };

            final duplicatesFound = switch (state) {
              FileScannerStateInitial() => 0,
              FileScannerStateScanningStarted() => state.groups.length,
            };

            return Padding(
              padding: .only(top: 16.sp),
              child: Row(
                children: [
                  Text('Files Scanned: $filesAnalyzed'),
                  Text('Duplicate files found: $duplicatesFound'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
