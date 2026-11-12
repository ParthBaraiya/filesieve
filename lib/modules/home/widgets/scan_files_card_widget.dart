import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';

/// ScanFilesCardWidget — scrollable list of every file the scan has listed.
/// It stays on screen after the scan completes.
class ScanFilesCardWidget extends StatelessWidget {
  const ScanFilesCardWidget({super.key, required this.files});

  final List<String> files;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('scan.files'),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                AppStrings.scanFilesTitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              const Spacer(),
              Text(
                '${files.length}',
                key: const ValueKey('scan.filesCount'),
                style: TextStyle(fontSize: 13.sp, color: palette.muted),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 280.h,
            decoration: BoxDecoration(
              color: palette.input,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: ListView.builder(
              key: const ValueKey('scan.filesList'),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              itemCount: files.length,
              itemExtent: 24.h,
              itemBuilder: (context, index) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  files[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.sp,
                    color: palette.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
