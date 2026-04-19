import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_shape_tokens.dart';

/// AppTheme — maps Stitch "Precision Core" design system tokens to Flutter
/// ThemeData. All named colours and typography come from the Stitch
/// `namedColors` + design-md document captured in T004.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // --- Primary ---
      primary: Color(0xFF003EC7),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF0052FF),
      onPrimaryContainer: Color(0xFFDFE3FF),
      // --- Secondary ---
      secondary: Color(0xFF4459A8),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF95AAFE),
      onSecondaryContainer: Color(0xFF253B89),
      // --- Tertiary ---
      tertiary: Color(0xFF952200),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFBF3003),
      onTertiaryContainer: Color(0xFFFFDDD5),
      // --- Error ---
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      // --- Surface / Background ---
      surface: Color(0xFFF9F9FC),
      onSurface: Color(0xFF1A1C1E),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF3F3F6),
      surfaceContainer: Color(0xFFEEEEF0),
      surfaceContainerHigh: Color(0xFFE8E8EA),
      surfaceContainerHighest: Color(0xFFE2E2E5),
      surfaceDim: Color(0xFFDADADC),
      surfaceBright: Color(0xFFF9F9FC),
      surfaceTint: Color(0xFF004CED),
      onSurfaceVariant: Color(0xFF434656),
      // --- Outline ---
      outline: Color(0xFF737688),
      outlineVariant: Color(0xFFC3C5D9),
      // --- Inverse ---
      inverseSurface: Color(0xFF2F3133),
      onInverseSurface: Color(0xFFF0F0F3),
      inversePrimary: Color(0xFFB7C4FF),
      // --- Scrim / Shadow ---
      scrim: Color(0xFF000000),
      shadow: Color(0xFF000000),
    );

    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // --- Button themes ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: .w600,
            letterSpacing: 0,
          ),
          padding: .symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: .w600,
            letterSpacing: 0,
          ),
          side: BorderSide(color: colorScheme.outline),
          padding: .symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: .w600,
            letterSpacing: 0,
          ),
          padding: .symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
        ),
      ),

      // --- Card ---
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(12.r),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: .zero,
      ),

      // --- Tooltip ---
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: .w400,
          color: colorScheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: .circular(6.r),
        ),
        padding: .symmetric(horizontal: 12.w, vertical: 6.h),
      ),

      // --- Divider ---
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // --- Progress indicators ---
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        borderRadius: .circular(2.r),
      ),

      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: .resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: .resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // --- Checkbox ---
      checkboxTheme: CheckboxThemeData(
        fillColor: .resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: .circular(3.r)),
      ),

      // --- Slider ---
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withAlpha(30),
        valueIndicatorColor: colorScheme.inverseSurface,
        valueIndicatorTextStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: .w500,
          color: colorScheme.onInverseSurface,
        ),
      ),

      // --- Input / TextField (for future use) ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: .symmetric(horizontal: 12.w, vertical: 12.h),
        hintStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: .w400,
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: .w500,
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: .w400,
          color: colorScheme.error,
        ),
        helperStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: .w400,
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: .circular(8.r),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: .circular(8.r),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: .circular(8.r),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: .circular(8.r),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // --- Dialog (for future use) ---
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: .w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: .w400,
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: .circular(16.r)),
      ),

      // --- SnackBar (for future use) ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: .w400,
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
        behavior: .floating,
      ),

      // --- ListTile (for future use) ---
      listTileTheme: ListTileThemeData(
        contentPadding: .symmetric(horizontal: 16.w, vertical: 4.h),
        titleTextStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: .w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: .w400,
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: .w400,
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
      ),

      // --- PopupMenu (for future use) ---
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 14.sp,
            fontWeight: .w400,
            color: colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: .circular(8.r)),
      ),

      extensions: [AppShapeTokens()],
    );
  }

  static TextTheme _buildTextTheme() {
    // Typography derived from Stitch design-md:
    //   headline-sm  → 1.5rem = 24sp, SemiBold (w600), letterSpacing -0.02em
    //   title-md     → 1rem   = 16sp, SemiBold (w600)
    //   title-sm     → 0.875rem = 14sp, Bold (w700)
    //   body-md      → 0.875rem = 14sp, Regular (w400)
    //   body-sm      → 0.75rem  = 12sp, Regular (w400)
    //   label-sm     → 0.6875rem = 11sp, Regular (w400)
    //   label-md     → 0.875rem  = 14sp, Medium (w500) — nav items
    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57.sp,
        fontWeight: .w400,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        fontSize: 45.sp,
        fontWeight: .w400,
        letterSpacing: -0.02,
      ),
      displaySmall: TextStyle(
        fontSize: 36.sp,
        fontWeight: .w400,
        letterSpacing: -0.02,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: .w600,
        letterSpacing: -0.02,
      ),
      headlineMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: .w600,
        letterSpacing: -0.02,
      ),
      headlineSmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: .w600,
        letterSpacing: -0.02,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 20.sp,
        fontWeight: .w600,
        letterSpacing: -0.02,
      ),
      titleMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: .w600,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: .w700,
        letterSpacing: 0,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: .w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: .w400,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: .w400,
        letterSpacing: 0,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: .w500,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: .w700,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11.sp,
        fontWeight: .w400,
        letterSpacing: 0,
      ),
    );
  }
}
