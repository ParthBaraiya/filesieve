import 'package:filesieve/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/app_settings_model.dart';
import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';
import '../../../values/enums.dart';
import '../../app_settings/app_settings_cubit.dart';
import 'settings_section_card_widget.dart';

/// RemovalSettingsSectionWidget — "When removing files": Trash vs permanent
/// delete, plus the confirm-before-every-removal switch.
class RemovalSettingsSectionWidget extends StatelessWidget {
  const RemovalSettingsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<AppSettingsCubit>();

    return BlocBuilder<AppSettingsCubit, AppSettingsModel>(
      builder: (context, settings) => SettingsSectionCardWidget(
        title: AppStrings.settingsRemovalTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ModeCard(
                    cardKey: 'settings.mode.trash',
                    label: AppStrings.settingsTrashLabel,
                    sub: AppStrings.settingsTrashSub,
                    selected: settings.removalMode == RemovalMode.trash,
                    onTap: () => cubit.setRemovalMode(RemovalMode.trash),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _ModeCard(
                    cardKey: 'settings.mode.permanent',
                    label: AppStrings.settingsPermanentLabel,
                    sub: AppStrings.settingsPermanentSub,
                    selected: settings.removalMode == RemovalMode.permanent,
                    onTap: () => cubit.setRemovalMode(RemovalMode.permanent),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.settingsConfirmTitle,
                        style: TextStyle(fontSize: 14.sp, color: palette.text),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        AppStrings.settingsConfirmSub,
                        style: TextStyle(fontSize: 12.sp, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: AppStrings.settingsConfirmTitle,
                  child: Switch(
                    key: const ValueKey('settings.confirmSwitch'),
                    value: settings.confirmBeforeEveryRemoval,
                    onChanged: cubit.setConfirmBeforeEveryRemoval,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.cardKey,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String cardKey;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        key: ValueKey(cardKey),
        color: selected ? palette.accentSoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: selected ? palette.accentLine : palette.line,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18.r,
                    color: selected ? AppPalette.brand : palette.muted,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.5,
                          color: palette.muted,
                        ),
                      ),
                    ],
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
