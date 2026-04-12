import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';

/// StepFlowWidget — a numbered three-step workflow guide.
///
/// Renders three [_StepItem]s sourced from [stepFlowData]:
///   01 · Add Folders
///   02 · Set Filters
///   03 · Review & Resolve
///
/// Displays as a [Row] above 600 px wide, drops to [Wrap] at narrower widths
/// so steps reflow to a single column without overflow.
class StepFlowWidget extends StatelessWidget {
  const StepFlowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildStepItems(context, isWide: true),
          );
        } else {
          return Wrap(
            direction: Axis.vertical,
            spacing: 16.h,
            children: _buildStepItems(context, isWide: false),
          );
        }
      },
    );
  }

  List<Widget> _buildStepItems(
    BuildContext context, {
    required bool isWide,
  }) {
    final items = <Widget>[];
    for (int i = 0; i < stepFlowData.length; i++) {
      final step = stepFlowData[i];
      if (isWide) {
        items.add(
          Expanded(
            child: _StepItem(
              number: step.number,
              label: step.label,
              desc: step.desc,
            ),
          ),
        );
        if (i < stepFlowData.length - 1) {
          items.add(SizedBox(width: 16.w));
        }
      } else {
        items.add(
          _StepItem(
            number: step.number,
            label: step.label,
            desc: step.desc,
          ),
        );
      }
    }
    return items;
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.label,
    required this.desc,
  });

  final String number;
  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: textTheme.headlineLarge?.copyWith(
            color: colorScheme.surfaceContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              label.toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.2,
                fontWeight: .w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              desc,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        )
      ],
    );
  }
}
