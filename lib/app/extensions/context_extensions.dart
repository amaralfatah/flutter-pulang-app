import 'package:flutter/material.dart';

/// Context extensions for cleaner theme access
/// Usage: context.colorScheme.primary, context.textTheme.bodyLarge
extension ContextExtensions on BuildContext {
  /// Quick access to ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;
}
