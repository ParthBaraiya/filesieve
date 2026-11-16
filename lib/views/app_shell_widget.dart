import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../modules/app_settings/app_settings_cubit.dart';
import '../values/app_strings.dart';

/// AppShellWidget — the top-level layout shell for all main screens.
///
/// A custom title bar (drag area, theme toggle, window buttons) on top, then
/// the [sidebar] on the left and the [body] filling the rest.
///
/// Route-level transitions are handled by [SharedAxisTransitionPage] in
/// GoRouter's child `pageBuilder`, so this widget renders [body] directly.
class AppShellWidget extends StatelessWidget {
  const AppShellWidget({super.key, required this.sidebar, required this.body});

  /// Fixed-width sidebar column (typically [SidebarSectionWidget]).
  final Widget sidebar;

  /// Main content area — receives all remaining space.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _TitleBar(),
          Expanded(
            child: Row(
              children: [
                sidebar,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = context.theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bar,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icon.png',
                        width: 24,
                        height: 24,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _TitleBarButton(
              key: const ValueKey('titleBar.themeToggle'),
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: 'Switch light or dark theme',
              onTap: () => context.read<AppSettingsCubit>().toggleTheme(
                currentlyDark: isDark,
              ),
            ),
            Container(
              width: 1,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: palette.line,
            ),
            _TitleBarButton(
              key: const ValueKey('titleBar.minimize'),
              icon: Icons.remove,
              tooltip: 'Minimize',
              onTap: () => appWindow.minimize(),
            ),
            _TitleBarButton(
              key: const ValueKey('titleBar.maximize'),
              icon: Icons.crop_square,
              tooltip: 'Maximize',
              onTap: () => appWindow.maximizeOrRestore(),
            ),
            _TitleBarButton(
              key: const ValueKey('titleBar.close'),
              icon: Icons.close,
              tooltip: 'Close',
              onTap: () => appWindow.close(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatelessWidget {
  const _TitleBarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 36,
          child: Icon(icon, size: 16.sp.clamp(14, 18), color: context.palette.muted),
        ),
      ),
    );
  }
}
