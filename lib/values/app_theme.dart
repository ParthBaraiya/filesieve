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
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        fontSize: 45.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      displaySmall: TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
      headlineMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
      headlineSmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
      titleMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}
