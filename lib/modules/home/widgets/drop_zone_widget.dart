import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';
import '../home_screen_cubit.dart';
import '../home_screen_state.dart';

/// DropZoneWidget — dashed drop target with the "Choose folders…" button.
///
/// Delegates drag/drop and picking to [HomeScreenCubit]. Highlights while a
/// drag hovers and shows the rejection reason (auto-dismissed after 2 s).
class DropZoneWidget extends StatefulWidget {
  const DropZoneWidget({super.key});

  @override
  State<DropZoneWidget> createState() => _DropZoneWidgetState();
}

class _DropZoneWidgetState extends State<DropZoneWidget> {
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onState(BuildContext context, HomeScreenState state) {
    _dismissTimer?.cancel();
    if (state is HomeScreenDropRejected) {
      final cubit = context.read<HomeScreenCubit>();
      _dismissTimer = Timer(const Duration(seconds: 2), cubit.dismissTransient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<HomeScreenCubit>();

    return BlocConsumer<HomeScreenCubit, HomeScreenState>(
      listener: _onState,
      builder: (context, state) {
        final hovering = state is HomeScreenDragHover;
        final rejected = state is HomeScreenDropRejected;
        final borderColor = rejected
            ? palette.danger
            : hovering
            ? AppPalette.brand
            : palette.dash;

        return DropTarget(
          onDragEntered: (_) => cubit.onDragEnter(),
          onDragExited: (_) => cubit.onDragExit(),
          onDragDone: (details) => cubit.onDrop(details.files),
          child: AnimatedContainer(
            key: const ValueKey('setup.dropZone'),
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: hovering ? palette.accentSoft : palette.panel,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16.w,
              runSpacing: 12.h,
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    size: 24.r,
                    color: palette.accentText,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 240.w, maxWidth: 380.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.setupDropTitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        rejected ? state.reason : AppStrings.setupDropSubtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: rejected ? palette.danger : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('setup.chooseFolders'),
                  onPressed: cubit.onPickFolder,
                  icon: Icon(Icons.add, size: 16.r),
                  label: const Text(AppStrings.setupChooseFolders),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.brand,
                    minimumSize: Size(0, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
