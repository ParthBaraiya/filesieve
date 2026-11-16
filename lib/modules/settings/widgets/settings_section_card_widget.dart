import 'package:filesieve/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// SettingsSectionCardWidget — a titled glass card used by every settings
/// section. [trailing] sits at the right of the title row.
class SettingsSectionCardWidget extends StatelessWidget {
  const SettingsSectionCardWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12.sp, color: palette.muted),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (child != null) ...[SizedBox(height: 12.h), child!],
        ],
      ),
    );
  }
}
