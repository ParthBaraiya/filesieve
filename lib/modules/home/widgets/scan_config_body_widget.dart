import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';

class ScanConfigBodyWidget extends StatelessWidget {
  const ScanConfigBodyWidget({super.key});

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
            OutlinedButton(
              onPressed: () {},
              child: Text(AppStrings.deleteSelected),
            ),
            SizedBox(width: 8.w),
            FilledButton(
              onPressed: () {},
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
                    Expanded(
                      flex: 7,
                      child: _PanelPlaceholder(
                        label: AppStrings.activeScanTargets,
                        colorScheme: colorScheme,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 5,
                      child: _PanelPlaceholder(
                        label: AppStrings.scanSettings,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _PanelPlaceholder(
                        label: AppStrings.activeScanTargets,
                        colorScheme: colorScheme,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Expanded(
                      flex: 2,
                      child: _PanelPlaceholder(
                        label: AppStrings.scanSettings,
                        colorScheme: colorScheme,
                      ),
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

class _PanelPlaceholder extends StatelessWidget {
  const _PanelPlaceholder({
    required this.label,
    required this.colorScheme,
  });

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
