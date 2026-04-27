import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';
import '../home_screen_cubit.dart';
import 'folder_list_panel_widget.dart';
import 'scan_settings_panel_widget.dart';

class ScanConfigBody extends StatelessWidget {
  const ScanConfigBody({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.scanConfigTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppStrings.scanConfigSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            FilledButton(
              onPressed: () => context.read<HomeScreenCubit>().startScan(),
              child: Text(AppStrings.startScan),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        // Responsive panels layout
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      flex: 7,
                      child: FolderListPanelWidget(),
                    ),
                    SizedBox(width: 16.w),
                    const Expanded(
                      flex: 5,
                      child: ScanSettingsPanelWidget(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: FolderListPanelWidget(),
                    ),
                    SizedBox(height: 16.h),
                    const Expanded(
                      flex: 2,
                      child: ScanSettingsPanelWidget(),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
