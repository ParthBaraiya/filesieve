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

/// AppearanceSectionWidget — System / Light / Dark segmented choice.
class AppearanceSectionWidget extends StatelessWidget {
  const AppearanceSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<AppSettingsCubit>();

    return BlocBuilder<AppSettingsCubit, AppSettingsModel>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, settings) => SettingsSectionCardWidget(
        title: AppStrings.settingsAppearanceTitle,
        trailing: Container(
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            color: palette.input,
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: palette.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in AppThemeMode.values)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: settings.themeMode == mode,
                  child: Material(
                    key: ValueKey('settings.theme.${mode.name}'),
                    color: settings.themeMode == mode
                        ? AppPalette.brand
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    child: InkWell(
                      onTap: () => cubit.setThemeMode(mode),
                      borderRadius: BorderRadius.circular(8.r),
                      child: SizedBox(
                        height: 34.h,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              mode.label,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: settings.themeMode == mode
                                    ? Colors.white
                                    : palette.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
