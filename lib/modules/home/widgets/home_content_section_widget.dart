import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';
import 'drop_zone_widget.dart';
import 'step_flow_widget.dart';

/// HomeContentSectionWidget — the main body content for the home / onboarding
/// screen.
///
/// Displays:
/// - A headline ([AppStrings.homeHeadline])
/// - A subtitle ([AppStrings.homeSubtitle])
/// - A bento-grid section with the drop zone and two feature cards.
///   Above 900 px wide: drop zone (flex 8) and cards (flex 4) are side-by-side.
///   Below 900 px wide: they stack vertically.
///
/// T024: [_FeatureCardsColumn] is defined inline in this file.
class HomeContentSectionWidget extends StatelessWidget {
  const HomeContentSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.homeHeadline,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.02 * (textTheme.headlineSmall?.fontSize ?? 24),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.homeSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Expanded(flex: 8, child: DropZoneWidget()),
                      SizedBox(width: 16),
                      Expanded(flex: 4, child: _FeatureCardsColumn()),
                    ],
                  );
                } else {
                  return Column(
                    children: const [
                      Expanded(child: DropZoneWidget()),
                      SizedBox(height: 16),
                      _FeatureCardsColumn(),
                    ],
                  );
                }
              },
            ),
          ),
          SizedBox(height: 24.h),
          const StepFlowWidget(),
        ],
      ),
    );
  }
}

/// Two feature-highlight cards stacked vertically.
///
/// Card 1 — "High-Speed Analysis": neutral surface background
///   ([ColorScheme.surfaceContainer])
/// Card 2 — "Byte-Perfect Accuracy": primary-tinted background
///   ([ColorScheme.primaryFixed])
///
/// All text sourced from [AppStrings]; all colours from [Theme.of(context)].
class _FeatureCardsColumn extends StatelessWidget {
  const _FeatureCardsColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _FeatureCard(
            title: AppStrings.featureCard1Title,
            body: AppStrings.featureCard1Body,
            background: Theme.of(context).colorScheme.surfaceContainer,
            icon: Icons.bolt_outlined,
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: _FeatureCard(
            title: AppStrings.featureCard2Title,
            body: AppStrings.featureCard2Body,
            background: Theme.of(context).colorScheme.primaryFixed,
            icon: Icons.verified_outlined,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.body,
    required this.background,
    required this.icon,
  });

  final String title;
  final String body;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24.r,
            color: colorScheme.primary,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
