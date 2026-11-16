import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_screen_cubit.dart';
import 'home_screen_state.dart';
import 'widgets/scan_setup_body.dart';
import 'widgets/scan_progress_body.dart';

/// HomeScreen — the main body content for the home / onboarding
/// screen.
///
/// Shows the scan progress while a scan runs, otherwise the folder setup.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeScreenCubit, HomeScreenState>(
      builder: (context, state) {
        if (state is HomeScreenScanning) {
          return ScanProgressBody(
            folderCount: state.folders.length,
            onCancel: () => context.read<HomeScreenCubit>().scanner.cancelScan(),
          );
        }

        return const ScanSetupBody();
      },
    );
  }
}
