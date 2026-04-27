import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_model.dart';
import '../../../models/scan_progress_model.dart';
import 'scan_live_feed_widget.dart';
import 'scan_progress_card_widget.dart';
import 'scan_stats_card_widget.dart';

class ScanProgressBody extends StatelessWidget {
  const ScanProgressBody({
    super.key,
    required this.overallPercent,
    required this.progress,
    required this.currentFilePath,
    required this.filesAnalyzed,
    required this.liveEntries,
    required this.onCancel,
  });

  final double overallPercent;
  final ScanProgress progress;
  final String currentFilePath;
  final int filesAnalyzed;
  final List<DuplicateGroup> liveEntries;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: ScanProgressCardWidget(onCancel: onCancel),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(flex: 4, child: const ScanStatsCardWidget()),
                ],
              );
            }
            return Column(
              children: [
                ScanProgressCardWidget(onCancel: onCancel),
                SizedBox(height: 16.h),
                const ScanStatsCardWidget(),
              ],
            );
          },
        ),
        SizedBox(height: 16.h),
        Expanded(child: ScanLiveFeedWidget(entries: liveEntries)),
      ],
    );
  }
}
