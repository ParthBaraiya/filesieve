import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../values/app_strings.dart';
import 'settings_screen_cubit.dart';
import 'settings_screen_state.dart';
import 'widgets/appearance_section_widget.dart';
import 'widgets/removal_settings_section_widget.dart';
import 'widgets/reset_section_widget.dart';
import 'widgets/settings_section_card_widget.dart';
import 'widgets/storage_cache_section_widget.dart';
import 'widgets/watched_folders_section_widget.dart';

/// SettingsScreen — removal behaviour, watched folders, appearance, storage
/// and cache locations (from the route-provided `SettingsScreenCubit`), and
/// reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocListener<SettingsScreenCubit, SettingsScreenState>(
      listener: (context, state) {
        if (state is SettingsScreenOpenFolderError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 28.h),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760.w.clamp(640, 900)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.settingsTitle,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.56,
                    color: palette.text,
                  ),
                ),
                SizedBox(height: 18.h),
                const RemovalSettingsSectionWidget(),
                SizedBox(height: 18.h),
                const WatchedFoldersSectionWidget(),
                SizedBox(height: 18.h),
                const AppearanceSectionWidget(),
                SizedBox(height: 18.h),
                BlocBuilder<SettingsScreenCubit, SettingsScreenState>(
                  builder: (context, state) {
                    final copiedId = state is SettingsScreenPathCopied
                        ? state.copiedEntryId
                        : null;
                    final cubit = context.read<SettingsScreenCubit>();

                    return SettingsSectionCardWidget(
                      title: AppStrings.settingsSectionStorageTitle,
                      child: StorageCacheSectionWidget(
                        entries: List.unmodifiable(state.entries),
                        copiedEntryId: copiedId,
                        onOpenFolder: cubit.openFolder,
                        onCopyPath: cubit.copyPath,
                      ),
                    );
                  },
                ),
                SizedBox(height: 18.h),
                const ResetSectionWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
