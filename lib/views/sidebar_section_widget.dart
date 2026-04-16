import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../values/app_strings.dart';
import '../../values/enums.dart';

/// SidebarSectionWidget — fixed-width sidebar with navigation items and an
/// optional "Add Folder" action button.
///
/// This is the **initial version** created in T017. Phase 6 (T028) will
/// complete it with a logo row, user-profile row, and full active-state
/// styling.
///
/// The widget is intentionally dumb — it receives all data and callbacks via
/// constructor parameters and contains zero business logic or I/O calls.
class SidebarSectionWidget extends StatelessWidget {
  const SidebarSectionWidget({
    super.key,
    required this.activeItem,
    required this.items,
    required this.onNavItemTap,
    this.onAddFolder,
  });

  /// The currently active navigation destination (highlighted in the sidebar).
  final NavigationItem activeItem;

  /// Ordered list of navigation items to render.
  final List<NavigationItem> items;

  /// Called when the user taps a nav item row.
  final void Function(NavigationItem) onNavItemTap;

  /// Called when the user taps "Add Folder".
  /// When [null] the button is hidden (used on non-home screens).
  final VoidCallback? onAddFolder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final username =
        Platform.environment['USERNAME'] ?? 'Administrator';
    final initials = username.isNotEmpty
        ? username.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : 'A';

    return SizedBox(
      width: 280.w,
      child: ColoredBox(
        color: colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo / app-name row ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 16.w, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 22.r,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.appName,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            // ── Add Folder button ────────────────────────────────────────────
            if (onAddFolder != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ElevatedButton(
                  onPressed: onAddFolder,
                  child: const Text('Add Folder'),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            // ── Navigation items ─────────────────────────────────────────────
            ...items.map(
              (item) => _NavItemRow(
                item: item,
                isActive: item == activeItem,
                onTap: () => onNavItemTap(item),
              ),
            ),
            const Spacer(),
            // ── User-profile row ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      initials,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemRow extends StatelessWidget {
  const _NavItemRow({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavigationItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(
                _iconForItem(item),
                size: 20.r,
                color: isActive
                    ? colorScheme.onPrimaryFixedVariant
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 12.w),
              Text(
                _labelForItem(item),
                style: textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? colorScheme.onPrimaryFixedVariant
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForItem(NavigationItem item) => switch (item) {
        NavigationItem.scan => Icons.search,
        NavigationItem.results => Icons.list_alt_outlined,
        NavigationItem.settings => Icons.settings_outlined,
        NavigationItem.history => Icons.history,
      };

  String _labelForItem(NavigationItem item) => switch (item) {
        NavigationItem.scan => 'Scan',
        NavigationItem.results => 'Results',
        NavigationItem.settings => 'Settings',
        NavigationItem.history => 'History',
      };
}
