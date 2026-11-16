import 'package:filesieve/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_view_model.dart';
import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';
import '../../../values/enums.dart';

/// CompareVersionCardWidget — one copy of a file: where it lives, when it was
/// modified, and the Keep / Remove / Show in folder / Restore actions.
class CompareVersionCardWidget extends StatelessWidget {
  const CompareVersionCardWidget({
    super.key,
    required this.version,
    required this.isKeep,
    required this.isOldest,
    required this.canRestore,
    required this.busy,
    required this.onKeep,
    required this.onRemove,
    required this.onReveal,
    required this.onRestore,
  });

  final DuplicateVersionView version;
  final bool isKeep;
  final bool isOldest;
  final bool canRestore;
  final bool busy;
  final VoidCallback onKeep;
  final VoidCallback onRemove;
  final VoidCallback onReveal;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final gone = version.isRemoved;
    final modified = version.modified?.format('MMM d, y');

    return Opacity(
      opacity: gone ? 0.6 : 1,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
        decoration: BoxDecoration(
          color: isKeep && !gone ? palette.accentSoft : palette.panel,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isKeep && !gone ? palette.accentLine : palette.line,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    color: palette.panelStrong,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(Icons.folder_outlined, size: 18.r, color: palette.accentText),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8.w,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            version.folderName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.text,
                              decoration: gone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isOldest) _Badge(label: AppStrings.cmpOldest),
                          if (isKeep && !gone)
                            _Badge(label: AppStrings.cmpKeeping, filled: true),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        version.path,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.sp,
                          color: palette.muted,
                        ),
                      ),
                      if (modified != null) ...[
                        SizedBox(height: 3.h),
                        Text(
                          'Modified $modified',
                          style: TextStyle(fontSize: 12.sp, color: palette.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            if (gone)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    version.removedAs == RemovalMode.trash
                        ? AppStrings.cmpMovedToTrash
                        : AppStrings.cmpDeleted,
                    style: TextStyle(fontSize: 13.sp, color: palette.muted),
                  ),
                  if (version.removedAs == RemovalMode.trash && canRestore)
                    TextButton(
                      onPressed: busy ? null : onRestore,
                      style: TextButton.styleFrom(foregroundColor: palette.accentText),
                      child: const Text(AppStrings.cmpRestore),
                    ),
                ],
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  if (!isKeep) ...[
                    _ActionButton(
                      label: AppStrings.cmpKeepThis,
                      onPressed: onKeep,
                    ),
                    _ActionButton(
                      label: AppStrings.cmpRemove,
                      icon: Icons.delete_outline,
                      danger: true,
                      onPressed: busy ? null : onRemove,
                    ),
                  ] else
                    _ActionButton(
                      label: AppStrings.cmpShowInFolder,
                      quiet: true,
                      onPressed: onReveal,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 20.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppPalette.brand : palette.panelStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : palette.muted,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.quiet = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger ? palette.danger : (quiet ? palette.muted : palette.text);
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      backgroundColor: danger
          ? palette.dangerSoft
          : (quiet ? Colors.transparent : palette.panelStrong),
      side: BorderSide(color: danger ? palette.dangerLine : palette.line),
      minimumSize: Size(0, 36.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.r)),
    );

    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 14.r),
            label: Text(label),
          );
  }
}
