import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';

/// Manrope keeps small labels highly legible while retaining a distinctive,
/// confident shape for restaurant names and primary actions.
abstract final class AppTypography {
  static const fontFamily = 'Manrope';

  static TextTheme get textTheme {
    final base = ThemeData.light().textTheme.apply(fontFamily: fontFamily);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: AppColors.textPrimary,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
        color: AppColors.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: AppColors.textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    );
  }

  static ThemeData lightTheme() {
    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      fontFamily: fontFamily,
    );

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: textTheme.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
    );
  }
}
