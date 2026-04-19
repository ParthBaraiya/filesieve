import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../values/app_strings.dart';
import 'home_screen_cubit.dart';
import 'home_screen_state.dart';
import 'widgets/drop_zone_widget.dart';
import 'widgets/scan_config_body_widget.dart';
import 'widgets/scan_progress_body_widget.dart';
import 'widgets/step_flow_widget.dart';

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
            child: ScanProgressBodyWidget(
              overallPercent: state.overallPercent,
              progress: state.progress,
              currentFilePath: state.currentFilePath,
              filesAnalyzed: state.filesAnalyzed,
              liveEntries: state.liveEntries,
              onCancel: () => context.read<HomeScreenCubit>().cancelScan(),
            ),
          );
        }

        if (state.hasFolders) {
          return Padding(
            padding: .symmetric(horizontal: 32.w, vertical: 24.h),
            child: const ScanConfigBodyWidget(),
          );
        }

        return const _OnboardingBody();
      },
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: .symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: .center,
        children: [
          SizedBox(height: 80.h),
          Text(
            AppStrings.homeHeadline,
            textAlign: .center,
            style: textTheme.headlineLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: .w700,
              letterSpacing: -0.02 * (textTheme.headlineMedium?.fontSize ?? 28),
            ),
          ),
          SizedBox(height: 8.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600.w),
            child: Text(
              AppStrings.homeSubtitle,
              textAlign: .center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: 50.h),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: .stretch,
                    children: [
                      const Expanded(flex: 8, child: DropZoneWidget()),
                      SizedBox(width: 16.w),
                      const Expanded(flex: 4, child: _FeatureCardsColumn()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      const Expanded(flex: 3, child: DropZoneWidget()),
                      SizedBox(height: 16.h),
                      const Expanded(flex: 2, child: _FeatureCardsColumn()),
                    ],
                  );
                }
              },
            ),
          ),
          SizedBox(height: 50.h),
          const StepFlowWidget(),
          SizedBox(height: 30.h),
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
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: _FeatureCard(
            title: AppStrings.featureCard1Title,
            body: AppStrings.featureCard1Body,
            background: Theme.of(context).colorScheme.surfaceContainer,
            icon: Icons.speed,
            iconColor: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: _FeatureCard(
            title: AppStrings.featureCard2Title,
            body: AppStrings.featureCard2Body,
            background: Theme.of(context).colorScheme.primary,
            icon: Icons.verified_user,
            iconColor: Theme.of(context).colorScheme.onPrimary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    this.iconColor,
    this.foregroundColor,
  });

  final String title;
  final String body;
  final Color background;
  final IconData icon;
  final Color? iconColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: .all(16.r),
      decoration: BoxDecoration(
        color: background,
        borderRadius: .circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Icon(icon, size: 24.r, color: iconColor ?? colorScheme.primary),
          SizedBox(height: 8.h),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: foregroundColor ?? colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: foregroundColor ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
