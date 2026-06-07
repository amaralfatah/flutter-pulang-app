import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App theme configuration following strict Material Design 3 guidelines
class AppTheme {
  AppTheme._();

  // Amber/Yellow colors for warning/late status
  static const Color _warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color _warningContainerLight = Color(0xFFFEF3C7); // Amber 100
  static const Color _onWarningContainerLight = Color(0xFF92400E); // Amber 800
  static const Color _warningContainerDark = Color(0xFF78350F); // Amber 900
  static const Color _onWarningContainerDark = Color(0xFFFDE68A); // Amber 200

  /// Light theme
  static ThemeData get light {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.light,
    );

    // Override tertiary with amber for warning/late status
    final colorScheme = baseScheme.copyWith(
      tertiary: _warningColor,
      tertiaryContainer: _warningContainerLight,
      onTertiary: Colors.white,
      onTertiaryContainer: _onWarningContainerLight,
    );

    return _build(
      colorScheme,
      GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ),
    );
  }

  /// Dark theme
  static ThemeData get dark {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.dark,
    );

    // Override tertiary with amber for warning/late status
    final colorScheme = baseScheme.copyWith(
      tertiary: _warningColor,
      tertiaryContainer: _warningContainerDark,
      onTertiary: Colors.black,
      onTertiaryContainer: _onWarningContainerDark,
    );

    return _build(
      colorScheme,
      GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
    );
  }

  /// Shared M3 theme assembly so light and dark stay consistent.
  ///
  /// Component shapes follow the M3 shape scale (medium = 12dp for cards,
  /// extra-large = 28dp for dialogs) and are centralised here so individual
  /// screens never re-declare radii.
  static ThemeData _build(ColorScheme colorScheme, TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // App Bar - Centered title for modern app style
      appBarTheme: const AppBarTheme(centerTitle: true),

      // Cards - M3 medium shape (12dp); clip ripples to the rounded corners.
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialogs - M3 extra-large shape (28dp) on the dialog surface tone.
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // SnackBars - floating per M3 with the small (8dp) shape.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
