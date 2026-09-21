import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The complete visual vocabulary for the vendor app.
/// Keep raw colour values in this file only so a palette refresh is a one-file change.
abstract final class AppColors {
  static const Color primary = Color(0xFFFC8019);
  static const Color primaryLight = Color(0xFFFFA35C);
  static const Color primaryDark = Color(0xFFE56F12);
  static const Color primaryTint = Color(0xFFFFE8D5);
  static const Color primarySoft = Color(0xFFFFF4EB);
  static const Color primaryDim = Color(0x1AFC8019);
  static const Color primaryBorder = Color(0x4DFC8019);

  // Backwards-compatible aliases used while screens are migrated.
  static const Color orange = primary;
  static const Color orangeLight = primaryLight;
  static const Color orangeWarm = primaryDark;
  static const Color orangeTint = primaryTint;
  static const Color orangeDim = primaryDim;
  static const Color orangeBorder = primaryBorder;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color canvas = bg;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFF7F7F7);
  static const Color surfaceElevated = Color(0xFFFFE8D5);
  static const Color surfaceMuted = Color(0xFFF2F2F3);
  static const Color navBg = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF282C3F);
  static const Color textSecondary = Color(0xFF686B78);
  static const Color textMuted = Color(0xFF93959F);
  static const Color icon = Color(0xFF686B78);
  static const Color iconMuted = Color(0xFF93959F);
  static const Color textOnAccent = Color(0xFFFFFFFF);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textWhite = textInverse;

  static const Color success = Color(0xFF198754);
  static const Color successLight = Color(0xFF43B980);
  static const Color successTint = Color(0xFFE7F6ED);
  static const Color successDim = Color(0x1A198754);
  static const Color successBorder = Color(0x40198754);
  static const Color green = success;
  static const Color greenDim = successDim;
  static const Color greenBorder = successBorder;
  static const Color warning = Color(0xFFD98A10);
  static const Color warningTint = Color(0xFFFFF1D7);
  static const Color danger = Color(0xFFD64545);
  static const Color dangerTint = Color(0xFFFFE9E8);
  static const Color red = danger;
  static const Color gold = Color(0xFFC98A22);

  static const Color border = Color(0xFFE9E9EB);
  static const Color borderStrong = Color(0xFFD4D5D9);
  static const Color borderAccent = primary;
  static const Color divider = Color(0xFFEFEFF1);
  static const Color shadow = Color(0x1A282C3F);
  static const Color shadowStrong = Color(0x33282C3F);
  static const Color overlay = Color(0x99000000);
  static const Color overlaySoft = Color(0x14000000);
  static const Color darkSurface = Color(0xFF282C3F);
  static const Color darkSurfaceRaised = Color(0xFF3D4152);
  static const Color bgSplash = darkSurface;
  static const Color surfaceWarm = darkSurfaceRaised;

  static const Color white = Color(0xFFFFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black26 = Color(0x42000000);
  static const Color transparent = Color(0x00000000);
  static const Color separator = Color(0x14000000);
  static const Color iconGrey = iconMuted;
}

abstract final class AppGradients {
  static const LinearGradient brand = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkHero = LinearGradient(
    colors: [AppColors.darkSurfaceRaised, AppColors.darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

abstract final class AppRadii {
  static const double small = 10;
  static const double medium = 14;
  static const double large = 20;
  static const double pill = 999;
}

abstract final class AppShadows {
  static const List<BoxShadow> card = [];
  static const List<BoxShadow> floating = [];
}

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnAccent,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.textOnAccent,
      secondaryContainer: AppColors.warningTint,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.success,
      onTertiary: AppColors.textOnAccent,
      tertiaryContainer: AppColors.successTint,
      onTertiaryContainer: AppColors.success,
      error: AppColors.danger,
      onError: AppColors.textOnAccent,
      errorContainer: AppColors.dangerTint,
      onErrorContainer: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceRaised,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      shadow: AppColors.shadowStrong,
      scrim: AppColors.overlay,
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.textInverse,
      inversePrimary: AppColors.primaryLight,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.medium),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      side: const BorderSide(color: AppColors.border, width: 1),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.large)),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnAccent,
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primaryBorder),
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(color: AppColors.danger)),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor: AppColors.primaryTint,
        disabledColor: AppColors.surfaceMuted,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        secondaryLabelStyle: TextStyle(color: AppColors.primaryDark),
        side: BorderSide(color: AppColors.border),
        shape: StadiumBorder(),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        indicatorColor: AppColors.primaryTint,
        labelTextStyle:
            WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.divider, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: TextStyle(color: AppColors.textInverse),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryTint,
        circularTrackColor: AppColors.primaryTint,
      ),
    );
  }
}
