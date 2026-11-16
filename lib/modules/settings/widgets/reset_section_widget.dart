import 'package:filesieve/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../values/app_routes.dart';
import '../../../values/app_strings.dart';
import '../../app_settings/app_settings_cubit.dart';
import '../../home/home_screen_cubit.dart';
import '../../home/home_screen_state.dart';
import 'settings_section_card_widget.dart';

/// ResetSectionWidget — "Start over": clears folders, results and preferences
/// and returns to the first-launch setup.
class ResetSectionWidget extends StatelessWidget {
  const ResetSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scanning = context.select<HomeScreenCubit, bool>(
      (c) => c.state is HomeScreenScanning,
    );

    return SettingsSectionCardWidget(
      title: AppStrings.settingsResetTitle,
      subtitle: AppStrings.settingsResetSub,
      trailing: OutlinedButton(
        key: const ValueKey('settings.reset'),
        onPressed: scanning
            ? null
            : () async {
                final home = context.read<HomeScreenCubit>();
                final settings = context.read<AppSettingsCubit>();
                final router = GoRouter.of(context);
                await home.reset();
                await settings.reset();
                router.go(AppRoutes.home);
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.danger,
          side: BorderSide(color: palette.dangerLine),
          minimumSize: Size(0, 38.h),
          textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.r)),
        ),
        child: const Text(AppStrings.settingsResetButton),
      ),
    );
  }
}
