import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Main application widget wrapped with Riverpod
class PulangApp extends ConsumerWidget {
  const PulangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize date change service to monitor for day changes
    ref.watch(dateChangeServiceProvider);

    // Watch theme mode from settings
    final settings = ref.watch(settingsProvider);
    final themeMode = _getThemeMode(settings.themeMode);

    return MaterialApp.router(
      title: 'Pulang - Presensi Solat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  /// Convert string to ThemeMode enum
  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
