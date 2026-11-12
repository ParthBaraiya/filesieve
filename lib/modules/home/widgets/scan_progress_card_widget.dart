import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/scan_progress_model.dart';
import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';

/// ScanProgressCardWidget — big percentage, progress bar, current file and
/// the three phase cards (list files, match by size, verify contents).
class ScanProgressCardWidget extends StatelessWidget {
  const ScanProgressCardWidget({super.key, required this.progress});

  final ScanProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final done = progress.stage.isCompleted;
    final percent = progress.overallPercent.floor().clamp(0, 100);
    final currentFile = done
        ? AppStrings.scanFinished
        : (progress.currentPath ?? '');

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 16.w,
            runSpacing: 8.h,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$percent%',
                    key: const ValueKey('scan.percent'),
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 56.sp,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.68,
                      color: palette.text,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    done ? AppStrings.scanAllChecked : progress.stage.description,
                    key: const ValueKey('scan.stageLine'),
                    style: TextStyle(fontSize: 14.sp, color: palette.muted),
                  ),
                ],
              ),
              if (progress.stageTotal > 0 && !done)
                Text(
                  '${progress.stageProcessed} of ${progress.stageTotal}',
                  style: TextStyle(fontSize: 13.sp, color: palette.muted),
                ),
            ],
          ),
          SizedBox(height: 18.h),
          Semantics(
            label: 'Scan progress',
            value: '$percent%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10.h,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: palette.track)),
                    FractionallySizedBox(
                      widthFactor: percent / 100,
                      child: ColoredBox(color: done ? palette.ok : AppPalette.brand),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: palette.input,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 14.r, color: palette.muted),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    currentFile,
                    key: const ValueKey('scan.currentFile'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.sp,
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: 12.w),
                Expanded(
                  child: _PhaseCard(
                    index: i,
                    label: const [
                      AppStrings.scanStageListFiles,
                      AppStrings.scanStageMatchBySize,
                      AppStrings.scanStageVerify,
                    ][i],
                    isDone: done || i < progress.stage.phase,
                    isActive: !done && i == progress.stage.phase,
                    activeText: progress.stage.description,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.activeText,
  });

  final int index;
  final String label;
  final bool isDone;
  final bool isActive;
  final String activeText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sub = isDone
        ? AppStrings.scanStageDone
        : isActive
        ? activeText
        : AppStrings.scanStageWaiting;

    return Container(
      key: ValueKey('scan.phase.$index'),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDone
            ? palette.okSoft
            : isActive
            ? palette.accentSoft
            : palette.panel,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isActive ? palette.accentLine : Colors.transparent),
      ),
      child: Row(
        children: [
          _PhaseIcon(isDone: isDone, isActive: isActive),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.isDone, required this.isActive});

  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = 26.r;

    if (isDone) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: palette.ok),
        child: Icon(Icons.check, size: 14.r, color: palette.onOk),
      );
    }
    if (isActive) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppPalette.brand,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.line, width: 2),
      ),
    );
  }
}
