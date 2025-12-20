import 'package:flutter/material.dart';

/// Centralized color palette - Islamic Modern Minimalist
/// PALETTE: Sage-Teal-Mint theme with balanced dark-light contrast
/// Base colors: #D8EFD3, #95D2B3, #55AD9B, #F1F8E8
class AppColors {
  AppColors._();

  // ============================================
  // 1. BRAND COLORS (Dark-Medium-Light Scale)
  // ============================================

  /// #3D8B7A - Deep Teal (DARK) - Derived darker from #55AD9B
  /// Digunakan untuk: Card header, Button primary, AppBar accent
  static const Color primary = Color(0xFF3D8B7A);

  /// #55AD9B - Teal Green (MEDIUM) - Original palette
  /// Digunakan untuk: Secondary buttons, Active icons
  static const Color secondary = Color(0xFF55AD9B);

  /// #95D2B3 - Sage Green (BRIGHT) - Original palette
  /// Digunakan untuk: Highlights, Success indicators
  static const Color accent = Color(0xFF95D2B3);

  // ============================================
  // 2. BACKGROUNDS & SURFACES
  // ============================================

  /// #D8EFD3 - Light Mint (Very Light Green Tint) - Original palette
  /// Digunakan untuk: Selected state, Hover state
  static const Color highlight = Color(0xFFD8EFD3);

  /// Material Design default - menggunakan scaffoldBackgroundColor bawaan theme
  /// Digunakan untuk: Main app background
  static const Color background = Color(0xFFFFFBFE); // M3 surface default

  /// #FFFFFF - Pure White
  /// Digunakan untuk: Cards, Dialogs, Sheets
  static const Color surface = Color(0xFFFFFFFF);

  // ============================================
  // 3. TEXT COLORS (High Contrast for Readability)
  // ============================================

  /// #1C3D35 - Dark Teal Charcoal - Harmonized with palette
  /// Digunakan untuk: Headlines, Body text
  static const Color textPrimary = Color(0xFF1C3D35);

  /// #5A7A72 - Muted Teal (Medium Gray-Green)
  /// Digunakan untuk: Subtitles, Captions, Placeholders
  static const Color textSecondary = Color(0xFF5A7A72);

  // ============================================
  // 4. STATUS COLORS
  // ============================================

  /// Success - Same as secondary for consistency
  static const Color success = Color(0xFF55AD9B);

  /// Warning - Amber/Gold (clearly visible)
  static const Color warning = Color(0xFFF59E0B);

  /// Error - Soft Red (not harsh)
  static const Color error = Color(0xFFDC2626);

  // ============================================
  // 5. UTILITY
  // ============================================

  /// Divider - Light teal-gray for subtle separation
  static const Color divider = Color(0xFFD0E4DE);

  /// Disabled - Muted sage-gray
  static const Color disabled = Color(0xFF9CB5AD);
}
