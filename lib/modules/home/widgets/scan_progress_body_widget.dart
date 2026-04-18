import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/scan_duplicate_entry_model.dart';
import '../../../models/scan_progress_model.dart';
import 'scan_live_feed_widget.dart';
import 'scan_progress_card_widget.dart';
import 'scan_stats_card_widget.dart';

class ScanProgressBodyWidget extends StatelessWidget {
  const ScanProgressBodyWidget({
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
  final List<ScanDuplicateEntryModel> liveEntries;
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
                    child: ScanProgressCardWidget(
                      overallPercent: overallPercent,
                      progress: progress,
                      currentFilePath: currentFilePath,
                      onCancel: onCancel,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 4,
                    child: ScanStatsCardWidget(
                      filesAnalyzed: filesAnalyzed,
                      duplicatesFound: liveEntries.length,
                      totalDuplicateSizeBytes: liveEntries.fold(
                        0,
                        (s, e) => s + e.sizeBytes,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                ScanProgressCardWidget(
                  overallPercent: overallPercent,
                  progress: progress,
                  currentFilePath: currentFilePath,
                  onCancel: onCancel,
                ),
                SizedBox(height: 16.h),
                ScanStatsCardWidget(
                  filesAnalyzed: filesAnalyzed,
                  duplicatesFound: liveEntries.length,
                  totalDuplicateSizeBytes: liveEntries.fold(
                    0,
                    (s, e) => s + e.sizeBytes,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 16.h),
        ScanLiveFeedWidget(entries: liveEntries),
      ],
    );
  }
}
