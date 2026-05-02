import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_state.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';
import 'scan_live_feed_row_widget.dart';

class ScanLiveFeedWidget extends StatelessWidget {
  const ScanLiveFeedWidget({super.key});

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
          Expanded(
            child: BlocBuilder<FileScannerCubit, FileScannerState>(
              bloc: context.read<HomeScreenCubit>().scanner,
              builder: (_, state) {
                if (state is! FileScannerStateScanningStarted) {
                  return Center(child: Text('Scanning has not started yet!!!'));
                }

                final entries = state.groups;

                return entries.isEmpty
                    ? Padding(
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
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                        ),
                        padding: .all(10.sp),
                        itemCount: entries.length,
                        itemBuilder: (_, index) {
                          final entry = entries[index];
                          return ScanLiveFeedGridWidget(
                            group: entry,
                            onPreview: () => context
                                .read<HomeScreenCubit>()
                                .setPreviewGroup(entry),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
