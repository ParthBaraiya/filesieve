import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';

/// SetupStepChipsWidget — the "1 Add folders — 2 Scan — 3 Review" progress
/// chips shown above the setup headline. [activeStep] is 1-based.
class SetupStepChipsWidget extends StatelessWidget {
  const SetupStepChipsWidget({super.key, this.activeStep = 1});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const labels = [
      AppStrings.setupStepAddFolders,
      AppStrings.setupStepScan,
      AppStrings.setupStepReview,
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10.w,
      runSpacing: 8.h,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          _StepChip(number: i + 1, label: labels[i], active: i + 1 == activeStep),
          if (i < labels.length - 1)
            SizedBox(
              width: 24.w,
              height: 1,
              child: ColoredBox(color: palette.line),
            ),
        ],
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.number,
    required this.label,
    required this.active,
  });

  final int number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 6.h, 12.w, 6.h),
      decoration: BoxDecoration(
        color: active ? palette.accentSoft : null,
        borderRadius: BorderRadius.circular(999),
        border: active ? null : Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20.r,
            height: 20.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppPalette.brand : palette.panelStrong,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : palette.muted,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: active ? palette.accentText : palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
