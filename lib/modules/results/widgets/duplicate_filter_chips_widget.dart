import 'package:filesieve/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';
import '../../../values/enums.dart';

/// DuplicateFilterChipsWidget — "All · 8", "Images · 2" … type filter chips.
/// Categories with no groups are hidden (except the selected one).
class DuplicateFilterChipsWidget extends StatelessWidget {
  const DuplicateFilterChipsWidget({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final FileCategory? selected;

  /// Number of groups for a category; null asks for the total.
  final int Function(FileCategory? category) countFor;
  final ValueChanged<FileCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = [
      for (final c in FileCategory.values)
        if (countFor(c) > 0 || c == selected) c,
    ];

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: [
        _Chip(
          chipKey: 'results.filter.all',
          label: '${AppStrings.dupFilterAll} · ${countFor(null)}',
          on: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final c in categories)
          _Chip(
            chipKey: 'results.filter.${c.name}',
            label: '${c.label} · ${countFor(c)}',
            on: selected == c,
            onTap: () => onSelected(c),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.chipKey,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String chipKey;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      selected: on,
      child: Material(
        key: ValueKey(chipKey),
        color: on ? AppPalette.brand : palette.panel,
        shape: StadiumBorder(
          side: BorderSide(color: on ? AppPalette.brand : palette.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 34.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: on ? Colors.white : palette.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
