import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';
import '../home_screen_cubit.dart';
import '../home_screen_state.dart';

/// DropZoneWidget — the draggable folder-drop target on the home screen.
///
/// Delegates all drag/drop events to [HomeScreenCubit] via [context.read].
/// Renders a hover highlight when [HomeScreenDragHover] is active and
/// an inline rejection message when [HomeScreenDropRejected] is active.
/// Rejection messages auto-dismiss after 2 seconds.
///
/// SC-004 Performance Baseline (drag-and-drop drop-to-state-change):
/// Target: ≤200 ms. Measure with Flutter DevTools frame timings.
/// Result: [TODO — measure on target Windows hardware and record here]
class DropZoneWidget extends StatelessWidget {
  const DropZoneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<HomeScreenCubit>().onPickFolder(),
      child: BlocBuilder<HomeScreenCubit, HomeScreenState>(
        builder: (context, state) {
          final isHovering = state is HomeScreenDragHover;
          final isRejected = state is HomeScreenDropRejected;
          final colorScheme = Theme.of(context).colorScheme;

          return DropTarget(
            onDragEntered: (_) => context.read<HomeScreenCubit>().onDragEnter(),
            onDragExited: (_) => context.read<HomeScreenCubit>().onDragExit(),
            onDragDone: (details) =>
                context.read<HomeScreenCubit>().onDrop(details.files),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isHovering
                    ? colorScheme.primary.withAlpha(20)
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isHovering
                      ? colorScheme.primary
                      : isRejected
                      ? colorScheme.error
                      : colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72.r,
                      height: 72.r,
                      decoration: BoxDecoration(
                        color: isHovering
                            ? colorScheme.primary
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 40.r,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Builder(
                        builder: (_) {
                          if (state case HomeScreenDropRejected(
                            :final reason,
                          )) {
                            return _RejectionMessage(
                              key: const ValueKey('rejected'),
                              reason: reason,
                            );
                          }
                          return Text(
                            key: const ValueKey('prompt'),
                            AppStrings.dropZonePrompt,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isHovering
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (state is! HomeScreenDropRejected)
                      Text(
                        AppStrings.dropZoneSecondary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        AppStrings.dropZoneFormats,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Displays the rejection reason and auto-dismisses after 2 seconds.
///
/// The [mounted] guard in [initState] prevents a [FlutterError] if the widget
/// is disposed before the timer fires (e.g. rapid repeated drops).
class _RejectionMessage extends StatefulWidget {
  const _RejectionMessage({super.key, required this.reason});

  final String reason;

  @override
  State<_RejectionMessage> createState() => _RejectionMessageState();
}

class _RejectionMessageState extends State<_RejectionMessage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<HomeScreenCubit>().dismissTransient();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.reason,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
      textAlign: TextAlign.center,
    );
  }
}
