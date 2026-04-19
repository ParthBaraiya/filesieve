import 'dart:io';

import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';
import '../home_screen_cubit.dart';
import '../home_screen_state.dart';

class FolderListPanelWidget extends StatelessWidget {
  const FolderListPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.activeScanTargets.toUpperCase(),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        AppStrings.foldersQueued,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      context.read<HomeScreenCubit>().onPickFolder(),
                  icon: Icon(Icons.add_circle_outline_outlined, size: 18.r),
                  label: Text(AppStrings.addNewTarget),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          // Folder list
          Expanded(
            child: BlocBuilder<HomeScreenCubit, HomeScreenState>(
              builder: (context, state) {
                final folders = state.allFolders;
                if (folders.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ListView.builder(
                  padding: EdgeInsets.all(10.r),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return _FolderItem(
                      path: folder.path,
                      displayName: folder.displayName,
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
          // Bottom progress section
          Divider(height: 1, color: colorScheme.outlineVariant),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.estimatedScanTime.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '--:--',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: 0,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderItem extends StatefulWidget {
  const _FolderItem({
    required this.path,
    required this.displayName,
    required this.index,
  });

  final String path;
  final String displayName;
  final int index;

  @override
  State<_FolderItem> createState() => _FolderItemState();
}

class _FolderItemState extends State<_FolderItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stat = FileStat.statSync(widget.path);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: .all(4.h),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surfaceContainer,
            borderRadius: .circular(10.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    size: 20.r,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.path,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: .ellipsis,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            "Modified ${stat.modified.timeAgo()}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    onPressed: () => context
                        .read<HomeScreenCubit>()
                        .removeFolder(widget.index),
                    icon: Icon(
                      Icons.close,
                      size: 18.r,
                      color: colorScheme.error,
                    ),
                    tooltip: AppStrings.deleteSelected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
