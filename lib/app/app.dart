import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Main application widget wrapped with Riverpod
class PulangApp extends ConsumerStatefulWidget {
  const PulangApp({super.key});

  @override
  ConsumerState<PulangApp> createState() => _PulangAppState();
}

class _PulangAppState extends ConsumerState<PulangApp> {
  @override
  void initState() {
    super.initState();
    // Trigger an automatic Google Drive backup once on app launch.
    // Runs in the background and is a no-op unless it's actually due
    // (auto-backup enabled, signed in, and >24h since the last backup).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNotificationPermission();
      _runAutoBackup();
    });
  }

  /// Request the notification permission on launch when the user has
  /// notifications enabled, so prayer alarms can actually be displayed.
  /// Runs after the first frame so the system dialog appears over the UI.
  Future<void> _ensureNotificationPermission() async {
    try {
      final enabled = await ref
          .read(preferencesServiceProvider)
          .isNotificationEnabled();
      if (!enabled) return;
      await ref.read(notificationServiceProvider).requestPermissions();
    } catch (_) {
      // Permission prompt failures must never disrupt startup.
    }
  }

  Future<void> _runAutoBackup() async {
    try {
      // Daily WhatsApp-style background backup via AlarmManager, so backups
      // also happen when the app isn't opened. The callback re-checks all
      // conditions itself, so scheduling unconditionally here is safe.
      await BackupService.scheduleDailyAutoBackup();

      // Catch-up pass on launch (fully silent — no Credential Manager UI).
      await ref.read(backupServiceProvider).autoBackupIfDue();
      if (!mounted) return;
      // Refresh settings so the "last backup" timestamp updates in the UI.
      ref.read(settingsProvider.notifier).refresh();
    } catch (_) {
      // Silent: an automatic backup must never disrupt app startup.
    }
  }

  @override
  Widget build(BuildContext context) {
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
