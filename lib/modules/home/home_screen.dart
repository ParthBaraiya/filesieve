import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_screen_cubit.dart';
import 'home_screen_state.dart';
import 'widgets/scan_config_body.dart';
import 'widgets/scan_onboarding_body.dart';
import 'widgets/scan_progress_body.dart';

/// HomeScreen — the main body content for the home / onboarding
/// screen.
///
/// When folders have been added ([HomeScreenStateX.hasFolders]), displays the
/// scan configuration body. Otherwise displays the onboarding layout.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeScreenCubit, HomeScreenState>(
      builder: (context, state) {
        if (state is HomeScreenScanning) {
          return Padding(
            padding: .symmetric(horizontal: 32.w, vertical: 24.h),
            child: ScanProgressBody(
              overallPercent: state.overallPercent,
              progress: state.progress,
              currentFilePath: state.currentFilePath,
              filesAnalyzed: state.filesAnalyzed,
              liveEntries: state.liveEntries,
              onCancel: () =>
                  context.read<HomeScreenCubit>().scanner.cancelScan(),
            ),
          );
        }

        if (state.hasFolders) {
          return Padding(
            padding: .symmetric(horizontal: 32.w, vertical: 24.h),
            child: const ScanConfigBody(),
          );
        }

        return const ScanOnboardingBody();
      },
    );
  }
}
