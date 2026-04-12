import 'package:flutter/material.dart';

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
    required this.header,
    required this.body,
    required this.footer,
  });

  /// Fixed-width sidebar column (typically [SidebarSectionWidget]).
  final Widget sidebar;

  /// Top of the body area (typically [HeaderSectionWidget]).
  final Widget header;

  /// Main content area — receives all remaining vertical space.
  final Widget body;

  /// Bottom of the body area (typically [FooterSectionWidget]).
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          sidebar,
          Expanded(
            child: Column(
              children: [
                header,
                Expanded(child: body),
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
