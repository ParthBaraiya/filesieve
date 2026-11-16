import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../values/enums.dart';

/// SidebarSectionWidget — left navigation column: the three destinations,
/// the watched-folder list and the "Reclaimable" summary card.
///
/// Pure presentation: every value arrives through parameters.
class SidebarSectionWidget extends StatelessWidget {
  const SidebarSectionWidget({
    super.key,
    required this.activeItem,
    required this.items,
    required this.onNavItemTap,
    required this.folderNames,
    required this.duplicateGroupCount,
    required this.reclaimableBytes,
    required this.freedBytes,
  });

  /// The currently active navigation destination (highlighted).
  final NavigationItem activeItem;

  /// Ordered list of navigation items to render.
  final List<NavigationItem> items;

  /// Called when the user taps a nav item row.
  final void Function(NavigationItem) onNavItemTap;

  /// Display names of the watched folders.
  final List<String> folderNames;

  /// Number of duplicate groups still unresolved (badge on "Duplicates").
  final int duplicateGroupCount;

  /// Bytes that removing every extra copy would free.
  final int reclaimableBytes;

  /// Bytes freed by removals this session.
  final int freedBytes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 240.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: palette.side,
        border: Border(right: BorderSide(color: palette.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            _NavItemRow(
              key: ValueKey('sidebar.nav.${item.name}'),
              item: item,
              isActive: item == activeItem,
              badge: item == NavigationItem.results
                  ? '$duplicateGroupCount'
                  : null,
              onTap: () => onNavItemTap(item),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 20.h, 12.w, 6.h),
            child: Text(
              'WATCHED FOLDERS',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.66,
                color: palette.muted,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: folderNames.length,
              itemBuilder: (context, index) => SizedBox(
                height: 30.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 15.r, color: palette.muted),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          folderNames[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.sp, color: palette.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _ReclaimableCard(
            reclaimableBytes: reclaimableBytes,
            freedBytes: freedBytes,
          ),
        ],
      ),
    );
  }
}

class _NavItemRow extends StatelessWidget {
  const _NavItemRow({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  final NavigationItem item;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isActive ? palette.text : palette.muted;

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: isActive ? palette.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: SizedBox(
            height: 40.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(item.icon, size: 18.r, color: color),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReclaimableCard extends StatelessWidget {
  const _ReclaimableCard({
    required this.reclaimableBytes,
    required this.freedBytes,
  });

  final int reclaimableBytes;
  final int freedBytes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reclaimable',
            style: TextStyle(fontSize: 12.sp, color: palette.muted),
          ),
          SizedBox(height: 4.h),
          Text(
            formatBytes(reclaimableBytes),
            key: const ValueKey('sidebar.reclaimable'),
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            freedBytes > 0
                ? '${formatBytes(freedBytes)} freed this session'
                : 'Not cleaned yet',
            style: TextStyle(fontSize: 12.sp, color: palette.muted),
          ),
        ],
      ),
    );
  }
}
