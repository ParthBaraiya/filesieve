import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    return SizedBox(
      width: 280.w,
      child: ColoredBox(
        color: colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 24.h),
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
            ...items.map(
              (item) => _NavItemRow(
                item: item,
                isActive: item == activeItem,
                onTap: () => onNavItemTap(item),
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
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 12.w),
              Text(
                _labelForItem(item),
                style: textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? colorScheme.primary
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
