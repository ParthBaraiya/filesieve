import 'dart:io';

import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_view_model.dart';
import '../../../values/app_strings.dart';
import '../../../views/file_category_icon_widget.dart';

/// ComparePreviewWidget — preview tile (an image when the file is one that
/// Flutter can decode, otherwise a type icon) plus Type / Size / Match facts.
class ComparePreviewWidget extends StatelessWidget {
  const ComparePreviewWidget({super.key, required this.group, required this.previewPath});

  final DuplicateGroupView group;

  /// Path of a copy that still exists on disk, used for the image preview.
  final String? previewPath;

  static const _decodable = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final path = previewPath;
    final ext = path?.split('.').last.toLowerCase();
    final icon = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FileCategoryIconWidget(category: group.category, size: 48.r),
        SizedBox(height: 10.h),
        Text(
          group.category.kindLabel,
          style: TextStyle(fontSize: 12.sp, color: palette.muted),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'File preview',
          image: true,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              key: const ValueKey('compare.preview'),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: palette.panelStrong,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: palette.line),
              ),
              child: path != null && _decodable.contains(ext)
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      cacheWidth: 640,
                      errorBuilder: (_, _, _) => icon,
                    )
                  : icon,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: palette.line),
          ),
          child: Column(
            children: [
              _Fact(label: AppStrings.cmpType, value: group.category.kindLabel),
              SizedBox(height: 6.h),
              _Fact(label: AppStrings.cmpSize, value: formatBytes(group.bytesEach)),
              SizedBox(height: 6.h),
              const _Fact(label: AppStrings.cmpMatch, value: AppStrings.cmpByteForByte),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(fontSize: 12.sp);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: palette.muted)),
        Text(value, style: style.copyWith(color: palette.text)),
      ],
    );
  }
}
