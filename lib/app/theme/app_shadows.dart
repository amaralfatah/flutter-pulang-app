import 'package:flutter/material.dart';

/// Custom shadows following Islamic Modern Minimalist theme
/// Green-tinted subtle shadows instead of default Flutter elevation
class AppShadows {
  AppShadows._();

  /// Standard card shadow - subtle green tint
  static BoxShadow get card => BoxShadow(
    color: const Color(0xFF344E41).withOpacity(0.08),
    blurRadius: 24,
    offset: const Offset(0, 8),
    spreadRadius: 0,
  );

  /// Light shadow for smaller elements
  static BoxShadow get light => BoxShadow(
    color: const Color(0xFF344E41).withOpacity(0.05),
    blurRadius: 12,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );

  /// Elevated shadow for highlighted elements
  static BoxShadow get elevated => BoxShadow(
    color: const Color(0xFF344E41).withOpacity(0.12),
    blurRadius: 32,
    offset: const Offset(0, 12),
    spreadRadius: 0,
  );
}
