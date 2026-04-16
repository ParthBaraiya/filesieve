import 'package:flutter/material.dart';

/// AppShapeTokens — ThemeExtension carrying border-radius tokens sourced from
/// the Stitch "Precision Core" design system (roundness: ROUND_FOUR).
///
/// Attach to ThemeData.extensions in AppTheme so any widget can retrieve these
/// via `Theme.of(context).extension<AppShapeTokens>()!`.
class AppShapeTokens extends ThemeExtension<AppShapeTokens> {
  const AppShapeTokens({
    this.borderRadiusXl = const BorderRadius.all(Radius.circular(12)),
    this.borderRadiusMd = const BorderRadius.all(Radius.circular(6)),
    this.dropZoneBorderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  /// 12 px — used for cards, buttons, panels.
  final BorderRadius borderRadiusXl;

  /// 6 px — used for chips, tags, input fields.
  final BorderRadius borderRadiusMd;

  /// 12 px — matches the drop-zone container border radius from Stitch.
  final BorderRadius dropZoneBorderRadius;

  @override
  AppShapeTokens copyWith({
    BorderRadius? borderRadiusXl,
    BorderRadius? borderRadiusMd,
    BorderRadius? dropZoneBorderRadius,
  }) {
    return AppShapeTokens(
      borderRadiusXl: borderRadiusXl ?? this.borderRadiusXl,
      borderRadiusMd: borderRadiusMd ?? this.borderRadiusMd,
      dropZoneBorderRadius: dropZoneBorderRadius ?? this.dropZoneBorderRadius,
    );
  }

  @override
  AppShapeTokens lerp(AppShapeTokens? other, double t) {
    if (other == null) return this;
    return AppShapeTokens(
      borderRadiusXl:
          BorderRadius.lerp(borderRadiusXl, other.borderRadiusXl, t)!,
      borderRadiusMd:
          BorderRadius.lerp(borderRadiusMd, other.borderRadiusMd, t)!,
      dropZoneBorderRadius: BorderRadius.lerp(
          dropZoneBorderRadius, other.dropZoneBorderRadius, t)!,
    );
  }
}
