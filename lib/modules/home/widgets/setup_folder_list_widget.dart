import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/scan_folder_model.dart';
import '../../../values/app_strings.dart';
import '../../app_settings/app_settings_cubit.dart';
import '../home_screen_cubit.dart';

/// SetupFolderListWidget — the "N folders to scan" card: the folder rows plus
/// the include-subfolders / skip-hidden checkboxes.
class SetupFolderListWidget extends StatelessWidget {
  const SetupFolderListWidget({super.key, required this.folders});

  final List<ScanFolderModel> folders;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsCubit>();
    final title = folders.isEmpty
        ? AppStrings.setupFoldersToScan
        : '${folders.length} ${folders.length == 1 ? 'folder' : 'folders'} to scan';

    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              title,
              key: const ValueKey('setup.folderCount'),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ),
          Divider(color: palette.line),
          for (var i = 0; i < folders.length; i++) ...[
            _FolderRow(index: i, folder: folders[i]),
            Divider(color: palette.line),
          ],
          if (folders.isEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26.h, horizontal: 16.w),
              child: Text(
                AppStrings.setupNoFolders,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: palette.muted),
              ),
            ),
            Divider(color: palette.line),
          ],
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Wrap(
              spacing: 16.w,
              children: [
                _OptionCheckbox(
                  key: const ValueKey('setup.includeSubfolders'),
                  label: AppStrings.setupIncludeSubfolders,
                  value: settings.state.includeSubfolders,
                  onChanged: settings.setIncludeSubfolders,
                ),
                _OptionCheckbox(
                  key: const ValueKey('setup.skipHidden'),
                  label: AppStrings.setupSkipHidden,
                  value: settings.state.skipHiddenFiles,
                  onChanged: settings.setSkipHiddenFiles,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.index, required this.folder});

  final int index;
  final ScanFolderModel folder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: palette.panelStrong,
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(Icons.folder_outlined, size: 18.r, color: palette.accentText),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  folder.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.sp,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('setup.removeFolder.$index'),
            tooltip: AppStrings.setupRemoveFolder,
            onPressed: () => context.read<HomeScreenCubit>().removeFolder(index),
            icon: Icon(Icons.close, size: 16.r, color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _OptionCheckbox extends StatelessWidget {
  const _OptionCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: context.palette.text),
            ),
          ],
        ),
      ),
    );
  }
}
