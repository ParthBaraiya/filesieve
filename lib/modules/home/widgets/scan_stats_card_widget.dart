import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';

/// ScanStatsCardWidget — three live counters: duplicate groups found, extra
/// copies and space that could be reclaimed.
class ScanStatsCardWidget extends StatelessWidget {
  const ScanStatsCardWidget({
    super.key,
    required this.groups,
    required this.extraCopies,
    required this.reclaimableBytes,
  });

  final int groups;
  final int extraCopies;
  final int reclaimableBytes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            tileKey: 'scan.stat.groups',
            label: AppStrings.scanStatGroups,
            value: '$groups',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatTile(
            tileKey: 'scan.stat.copies',
            label: AppStrings.scanStatCopies,
            value: '$extraCopies',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatTile(
            tileKey: 'scan.stat.space',
            label: AppStrings.scanStatSpace,
            value: formatBytes(reclaimableBytes),
            valueColor: palette.accentText,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.tileKey,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String tileKey;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: palette.muted)),
          SizedBox(height: 4.h),
          Text(
            value,
            key: ValueKey(tileKey),
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 26.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
