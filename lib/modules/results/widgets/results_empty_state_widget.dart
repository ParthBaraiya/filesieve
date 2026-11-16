import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';

/// ResultsEmptyStateWidget — shown when no duplicate groups are left: either
/// nothing has been scanned yet, or everything was cleaned up.
class ResultsEmptyStateWidget extends StatelessWidget {
  const ResultsEmptyStateWidget({
    super.key,
    required this.hasScanned,
    required this.freedBytes,
    required this.freedCount,
    required this.onAction,
  });

  final bool hasScanned;
  final int freedBytes;
  final int freedCount;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = hasScanned ? AppStrings.dupCleanTitle : AppStrings.dupNotScannedTitle;
    final body = !hasScanned
        ? AppStrings.dupNotScannedBody
        : freedCount > 0
        ? 'You freed ${formatBytes(freedBytes)} by removing $freedCount ${freedCount == 1 ? 'copy' : 'copies'}.'
        : AppStrings.dupCleanNone;

    return Container(
      key: const ValueKey('results.empty'),
      padding: EdgeInsets.symmetric(vertical: 56.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(color: palette.okSoft, shape: BoxShape.circle),
            child: Icon(
              hasScanned ? Icons.check : Icons.search,
              size: 30.r,
              color: palette.ok,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          SizedBox(height: 12.h),
          Text(body, style: TextStyle(fontSize: 14.sp, color: palette.muted)),
          SizedBox(height: 20.h),
          OutlinedButton(
            key: const ValueKey('results.emptyAction'),
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.text,
              backgroundColor: palette.panelStrong,
              side: BorderSide(color: palette.line),
              minimumSize: Size(0, 42.h),
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(hasScanned ? AppStrings.dupScanAgain : AppStrings.dupGoToScan),
          ),
        ],
      ),
    );
  }
}
