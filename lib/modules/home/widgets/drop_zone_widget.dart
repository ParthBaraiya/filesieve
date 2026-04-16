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
class DropZoneWidget extends StatelessWidget {
  const DropZoneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeScreenCubit, HomeScreenState>(
      builder: (context, state) {
        final isHovering = state is HomeScreenDragHover;
        final isRejected = state is HomeScreenDropRejected;
        final colorScheme = Theme.of(context).colorScheme;

        return DropTarget(
          onDragEntered: (_) =>
              context.read<HomeScreenCubit>().onDragEnter(),
          onDragExited: (_) =>
              context.read<HomeScreenCubit>().onDragExit(),
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
                  Icon(
                    Icons.folder_open_outlined,
                    size: 48.r,
                    color: isHovering
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 12.h),
                  if (state case HomeScreenDropRejected(:final reason))
                    _RejectionMessage(reason: reason)
                  else
                    Text(
                      AppStrings.dropZonePrompt,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isHovering
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Displays the rejection reason and auto-dismisses after 2 seconds.
///
/// The [mounted] guard in [initState] prevents a [FlutterError] if the widget
/// is disposed before the timer fires (e.g. rapid repeated drops).
class _RejectionMessage extends StatefulWidget {
  const _RejectionMessage({required this.reason});

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
        context.read<HomeScreenCubit>().resetToInitial();
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
