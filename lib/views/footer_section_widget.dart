import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../values/app_strings.dart';

/// FooterSectionWidget — slim footer bar shown at the bottom of the app shell.
///
/// Contains:
/// - A gradient CPU-load indicator: a [ShaderMask] wrapping a
///   [LinearProgressIndicator] at `value: 0.0` (stub — real value wired in a
///   future performance-monitoring feature). Uses the correct Flutter pattern:
///   [LinearProgressIndicator] does NOT accept a [LinearGradient] directly, so
///   the gradient is applied via [ShaderMask.shaderCallback].
/// - The scanning engine version string ([AppStrings.scanningEngineVersion]).
/// - A cloud-sync status stub: [Icons.cloud_off] + "Offline" label, both in
///   [ColorScheme.onSurfaceVariant] (FR-011).
class FooterSectionWidget extends StatelessWidget {
  const FooterSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Gradient CPU-load indicator (4 px tall) ───────────────────────
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [colorScheme.primary, colorScheme.primaryContainer],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: 0.0,
              color: Colors.white,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        // ── Footer content row ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            children: [
              // Engine version
              Text(
                AppStrings.scanningEngineVersion,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Cloud-sync status stub
              Icon(
                Icons.cloud_off,
                size: 14.r,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 4.w),
              Text(
                'Offline',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
