import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// HeaderSectionWidget — top bar of the body area.
///
/// Displays a context [label] on the left and notification + help stub
/// [IconButton]s on the right. Callers typically pass
/// [AppStrings.headerContextLabel] as the label.
///
/// All colours and text styles are sourced from [Theme.of(context)].
class HeaderSectionWidget extends StatelessWidget {
  const HeaderSectionWidget({
    super.key,
    required this.label,
  });

  /// Context label displayed on the left side of the header.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
        ],
      ),
    );
  }
}
