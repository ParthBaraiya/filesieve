import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_screen_cubit.dart';
import 'home_screen_state.dart';
import 'widgets/duplicate_file_preview_widget.dart';
import 'widgets/scan_setup_body.dart';
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
              onCancel: () =>
                  context.read<HomeScreenCubit>().scanner.cancelScan(),
            ),
          );
        }

        if (state is HomeScreenFilePreview) {
          return DuplicateFilePreviewWidget(state: state);
        }

        return const ScanSetupBody();
      },
    );
  }
}
