import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_model.dart';
import '../../../models/scan_duplicate_entry_model.dart';
import '../../../values/app_strings.dart';
import 'scan_live_feed_row_widget.dart';

class ScanLiveFeedWidget extends StatelessWidget {
  const ScanLiveFeedWidget({super.key, required this.entries});

  final List<DuplicateGroup> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  Icons.content_copy,
                  size: 18.r,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8.w),
                Text(
                  AppStrings.scanLiveFeedTitle,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    AppStrings.scanLiveFeedLiveLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  AppStrings.scanLiveFeedEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (_, i) => ColoredBox(
                  color: i.isEven
                      ? colorScheme.surfaceContainerLow.withAlpha(80)
                      : colorScheme.surface,
                  child: ScanLiveFeedRowWidget(group: entries[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
