import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Context extensions for cleaner theme access
/// Usage: context.colorScheme.primary, context.textTheme.bodyLarge
extension ContextExtensions on BuildContext {
  /// Quick access to ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Teks terlokalisasi: context.l10n.appTitle
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Tag locale aktif untuk DateFormat / TableCalendar, mis. 'id' atau 'en'.
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}
