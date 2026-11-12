import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_view_model.dart';
import '../../../views/file_category_icon_widget.dart';

/// Column widths shared by the table header and every row.
class DuplicateTableColumns {
  const DuplicateTableColumns._();

  static double get copies => 80.w;
  static double get size => 110.w;
  static double get reclaimable => 130.w;
  static double get chevron => 36.w;
  static double get gap => 16.w;
}

/// DuplicateGroupRowWidget — one clickable row of the duplicates table.
class DuplicateGroupRowWidget extends StatelessWidget {
  const DuplicateGroupRowWidget({
    super.key,
    required this.group,
    required this.onOpen,
  });

  final DuplicateGroupView group;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copies = group.remaining.length;

    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: palette.tile,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: FileCategoryIconWidget(
                      category: group.category,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          group.whereLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.sp, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: DuplicateTableColumns.gap),
            SizedBox(
              width: DuplicateTableColumns.copies,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 24.h,
                  padding: EdgeInsets.symmetric(horizontal: 9.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.panelStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '×$copies',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: DuplicateTableColumns.gap),
            SizedBox(
              width: DuplicateTableColumns.size,
              child: Text(
                formatBytes(group.bytesEach),
                style: TextStyle(fontSize: 13.sp, color: palette.muted),
              ),
            ),
            SizedBox(width: DuplicateTableColumns.gap),
            SizedBox(
              width: DuplicateTableColumns.reclaimable,
              child: Text(
                formatBytes(group.reclaimableBytes),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.accentText,
                ),
              ),
            ),
            SizedBox(width: DuplicateTableColumns.gap),
            SizedBox(
              width: DuplicateTableColumns.chevron,
              child: Icon(Icons.chevron_right, size: 16.r, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
