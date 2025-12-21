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

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography - Using GoogleFonts but deferring to M3 hierarchy
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ),

      // App Bar - Centered title for modern app style
      appBarTheme: const AppBarTheme(centerTitle: true),
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

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),

      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
