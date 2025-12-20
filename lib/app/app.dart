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

    return MaterialApp.router(
      title: 'Pulang - Presensi Solat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          ThemeMode.light, // Force light theme for consistent Islamic aesthetic
      routerConfig: router,
    );
  }
}
