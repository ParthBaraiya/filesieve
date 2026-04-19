import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// AppShellWidget — the top-level layout shell for all main screens.
///
/// Composes a fixed sidebar on the left and an [Expanded] body column on the
/// right. The body column is further divided into three vertical slots:
/// [header] (static height), [body] (fills remaining space), and [footer]
/// (static height).
///
/// Route-level transitions are handled by [SharedAxisTransitionPage] in
/// GoRouter's child `pageBuilder`, so this widget renders [body] directly.
class AppShellWidget extends StatelessWidget {
  const AppShellWidget({
    super.key,
    required this.sidebar,
    required this.body,
    this.footer,
  });

  /// Fixed-width sidebar column (typically [SidebarSectionWidget]).
  final Widget sidebar;

  /// Main content area — receives all remaining vertical space.
  final Widget body;

  /// Bottom of the body area (typically [FooterSectionWidget]).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 32,
            child: MoveWindow(
              child: Row(
                children: [
                  WindowTitleBarBox(
                    child: Padding(
                      padding: const .symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          'FileSieve',
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: null,
                    icon: const Icon(Icons.notifications_outlined),
                    color: context.theme.colorScheme.onSurfaceVariant,
                    tooltip: 'Notifications',
                    iconSize: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  IconButton(
                    onPressed: null,
                    icon: const Icon(Icons.help_outline),
                    color: context.theme.colorScheme.onSurfaceVariant,
                    tooltip: 'Help',
                    iconSize: 18.sp,
                  ),
                  _AppBarIcon(
                    child: Icons.minimize,
                    iconColor: context.theme.colorScheme.primary,
                    tooltip: 'Minimize',
                    onTap: () => appWindow.minimize(),
                  ),
                  _AppBarIcon(
                    child: Icons.close,
                    iconColor: context.theme.colorScheme.error,
                    backgroundColor: context.theme.colorScheme.errorContainer,
                    tooltip: 'Close',
                    onTap: () => appWindow.close(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                sidebar,
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: body),
                      ?footer,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  const _AppBarIcon({
    super.key,
    required this.child,
    this.tooltip,
    required this.iconColor,
    this.backgroundColor,
    required this.onTap,
  });

  final IconData child;
  final String? tooltip;
  final Color iconColor;
  final Color? backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 50,
        height: 32,
        child: InkWell(
          onTap: onTap,
          child: ColoredBox(
            color: backgroundColor ?? Colors.transparent,
            child: Padding(
              padding: .symmetric(vertical: 8, horizontal: 12),
              child: Icon(
                child,
                color: iconColor,
                size: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
