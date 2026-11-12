import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/suggested_folders.dart';
import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';
import '../../app_settings/app_settings_cubit.dart';
import '../home_screen_cubit.dart';
import '../home_screen_state.dart';
import 'drop_zone_widget.dart';
import 'setup_folder_list_widget.dart';
import 'setup_step_chips_widget.dart';

/// ScanSetupBody — first step of the flow: add folders, set options, start.
/// Shown whether or not folders have been added yet.
class ScanSetupBody extends StatelessWidget {
  const ScanSetupBody({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final suggestions = suggestedFolders();

    return BlocBuilder<HomeScreenCubit, HomeScreenState>(
      builder: (context, state) {
        final folders = state.allFolders;
        final haveNames = {for (final f in folders) f.path};
        final chips = [
          for (final s in suggestions)
            if (!haveNames.contains(s.path)) s,
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 720.w.clamp(560, 900)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SetupStepChipsWidget(),
                  SizedBox(height: 22.h),
                  Text(
                    AppStrings.setupHeadline,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 36.sp,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.72,
                      color: palette.text,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    AppStrings.setupSubtitle,
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.6,
                      color: palette.muted,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  const DropZoneWidget(),
                  if (chips.isNotEmpty) ...[
                    SizedBox(height: 22.h),
                    _SuggestedChips(chips: chips),
                  ],
                  SizedBox(height: 22.h),
                  SetupFolderListWidget(folders: folders),
                  SizedBox(height: 22.h),
                  _StartRow(enabled: state is HomeScreenFoldersAdded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestedChips extends StatelessWidget {
  const _SuggestedChips({required this.chips});

  final List<({String name, String path})> chips;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Text(
            AppStrings.setupSuggested,
            style: TextStyle(fontSize: 13.sp, color: palette.muted),
          ),
        ),
        for (final chip in chips)
          ActionChip(
            key: ValueKey('setup.suggested.${chip.name}'),
            onPressed: () =>
                context.read<HomeScreenCubit>().addFolderPaths([chip.path]),
            avatar: Icon(Icons.add, size: 13.r, color: palette.text),
            label: Text(chip.name),
            labelStyle: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: palette.text,
            ),
            backgroundColor: palette.panel,
            side: BorderSide(color: palette.line),
            shape: const StadiumBorder(),
          ),
      ],
    );
  }
}

class _StartRow extends StatelessWidget {
  const _StartRow({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12.h,
      spacing: 16.w,
      children: [
        Text(
          AppStrings.setupSettingsHint,
          style: TextStyle(fontSize: 13.sp, color: context.palette.muted),
        ),
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: FilledButton(
            key: const ValueKey('setup.startScan'),
            onPressed: enabled
                ? () {
                    final settings = context.read<AppSettingsCubit>().state;
                    context.read<HomeScreenCubit>().startScan(
                      includeSubfolders: settings.includeSubfolders,
                      skipHidden: settings.skipHiddenFiles,
                    );
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.brand,
              disabledBackgroundColor: AppPalette.brand,
              disabledForegroundColor: Colors.white,
              minimumSize: Size(0, 44.h),
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(AppStrings.setupStartScan),
                SizedBox(width: 10.w),
                Icon(Icons.arrow_forward, size: 16.r),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
