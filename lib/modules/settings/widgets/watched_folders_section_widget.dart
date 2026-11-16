import 'package:filesieve/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';
import '../../home/home_screen_cubit.dart';
import '../../home/home_screen_state.dart';
import 'settings_section_card_widget.dart';

/// WatchedFoldersSectionWidget — the folder list with Add folder / remove.
/// Editing is disabled while a scan is running.
class WatchedFoldersSectionWidget extends StatelessWidget {
  const WatchedFoldersSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<HomeScreenCubit>();

    return BlocBuilder<HomeScreenCubit, HomeScreenState>(
      builder: (context, state) {
        final folders = state.allFolders;
        final locked = state is HomeScreenScanning;

        return SettingsSectionCardWidget(
          title: AppStrings.settingsFoldersTitle,
          subtitle: AppStrings.settingsFoldersSub,
          trailing: OutlinedButton.icon(
            key: const ValueKey('settings.addFolder'),
            onPressed: locked ? null : cubit.onPickFolder,
            icon: Icon(Icons.add, size: 14.r),
            label: const Text(AppStrings.settingsAddFolder),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.text,
              backgroundColor: palette.panelStrong,
              side: BorderSide(color: palette.line),
              minimumSize: Size(0, 36.h),
              textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.r)),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: palette.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (folders.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    child: Text(
                      AppStrings.settingsNoFolders,
                      style: TextStyle(fontSize: 13.sp, color: palette.muted),
                    ),
                  ),
                for (var i = 0; i < folders.length; i++)
                  Container(
                    padding: EdgeInsets.fromLTRB(14.w, 4.h, 4.w, 4.h),
                    decoration: BoxDecoration(
                      border: i == folders.length - 1
                          ? null
                          : Border(bottom: BorderSide(color: palette.line)),
                    ),
                    child: Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 96.w),
                          child: Text(
                            folders[i].displayName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: palette.text,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            folders[i].path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12.sp,
                              color: palette.muted,
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('settings.removeFolder.$i'),
                          tooltip: AppStrings.settingsStopWatching,
                          onPressed: locked ? null : () => cubit.removeFolder(i),
                          icon: Icon(Icons.close, size: 15.r, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
