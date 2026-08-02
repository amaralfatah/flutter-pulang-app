import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:googleapis/drive/v3.dart' as drive;

import '../../app/router.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/shared/app_snackbar.dart';
import '../../widgets/shared/loading_dialog.dart';

/// Settings screen - App configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 8),
        children: [
          _buildLocationSection(context, ref, settings),
          const SizedBox(height: 8),
          _buildNotificationSection(context, ref, settings, notifier),
          const SizedBox(height: 8),
          _buildAppearanceSection(context, ref, settings, notifier),
          const SizedBox(height: 8),
          _buildBackupSection(context, ref, settings, notifier),
          const SizedBox(height: 8),
          _buildAboutSection(context, ref, settings),
        ],
      ),
    );
  }

  /// M3 list subheader: `titleSmall` in the primary colour (no ad-hoc bold).
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Groups a section's tiles inside a single M3 card surface.
  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return _buildSection(context, 'Lokasi', [
      ListTile(
        leading: _leadingIcon(context, Icons.location_on_outlined),
        title: Text(settings.cityName ?? 'Belum pilih kota'),
        subtitle: const Text('Digunakan untuk jadwal solat'),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showCitySearchDialog(context, ref),
      ),
    ]);
  }

  /// Standard tonal leading icon used by every settings tile.
  Widget _leadingIcon(
    BuildContext context,
    IconData icon, {
    Color? container,
    Color? foreground,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: container ?? colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: foreground ?? colorScheme.primary),
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildSection(context, 'Notifikasi', [
      SwitchListTile(
        secondary: _leadingIcon(context, Icons.notifications_active_outlined),
        title: const Text('Aktifkan Notifikasi'),
        subtitle: const Text('Notifikasi saat masuk waktu solat'),
        value: settings.notificationEnabled,
        onChanged: (value) => notifier.setNotificationEnabled(value),
      ),
      // Diagnostics below are for development only — shipping them puts
      // "(Debug)" entries in front of real users.
      if (kDebugMode)
      ListTile(
        leading: _leadingIcon(
          context,
          Icons.notification_important_outlined,
          container: colorScheme.tertiaryContainer,
          foreground: colorScheme.tertiary,
        ),
        title: const Text('Test Notifikasi'),
        subtitle: const Text('Kirim notifikasi sekarang (Debug)'),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          await ref.read(notificationServiceProvider).requestPermissions();
          await ref
              .read(notificationServiceProvider)
              .showNotification(
                id: 999,
                title: 'Test Notifikasi',
                body: 'Ini adalah contoh notifikasi waktu solat.',
              );

          messenger.showSnackBar(
            AppSnackBar.info(
              colorScheme,
              'Notifikasi dikirim (Tunggu beberapa detik)',
            ),
          );
        },
      ),
      if (kDebugMode)
      ListTile(
        leading: _leadingIcon(
          context,
          Icons.schedule_send_outlined,
          container: colorScheme.tertiaryContainer,
          foreground: colorScheme.tertiary,
        ),
        title: const Text('Test Notifikasi Terjadwal'),
        subtitle: const Text(
          'Jadwalkan via alarm, muncul 1 menit lagi (Debug)',
        ),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final service = ref.read(notificationServiceProvider);

          final granted = await service.requestPermissions();
          if (!granted) {
            messenger.showSnackBar(
              AppSnackBar.error(
                colorScheme,
                'Izin notifikasi belum diberikan. Aktifkan di pengaturan HP.',
              ),
            );
            return;
          }

          final fireAt = await service.scheduleTestNotification();
          final timeLabel = DateFormat('HH:mm:ss').format(fireAt);
          messenger.showSnackBar(
            AppSnackBar.info(
              colorScheme,
              'Alarm dijadwalkan pukul $timeLabel. '
              'Biarkan/keluar app, notifikasi akan muncul.',
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    String getThemeModeLabel(String mode) {
      switch (mode) {
        case 'light':
          return 'Mode Terang';
        case 'dark':
          return 'Mode Gelap';
        default:
          return 'Ikuti Sistem';
      }
    }

    IconData getThemeModeIcon(String mode) {
      switch (mode) {
        case 'light':
          return Icons.light_mode_outlined;
        case 'dark':
          return Icons.dark_mode_outlined;
        default:
          return Icons.brightness_auto_outlined;
      }
    }

    return _buildSection(context, 'Tampilan', [
      ListTile(
        leading: _leadingIcon(context, getThemeModeIcon(settings.themeMode)),
        title: const Text('Mode Tampilan'),
        subtitle: Text(getThemeModeLabel(settings.themeMode)),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showThemeModeDialog(context, settings, notifier),
      ),
    ]);
  }

  void _showThemeModeDialog(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Mode Tampilan'),
        content: RadioGroup<String>(
          groupValue: settings.themeMode,
          onChanged: (selected) {
            if (selected != null) notifier.setThemeMode(selected);
            Navigator.pop(context);
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                title: 'Ikuti Sistem',
                subtitle: 'Otomatis sesuai pengaturan perangkat',
                value: 'system',
              ),
              _ThemeOption(
                title: 'Mode Terang',
                subtitle: 'Tampilan cerah untuk siang hari',
                value: 'light',
              ),
              _ThemeOption(
                title: 'Mode Gelap',
                subtitle: 'Tampilan gelap untuk malam hari',
                value: 'dark',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final backupService = ref.read(backupServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSection(context, 'Backup & Data', [
      ListTile(
        leading: _leadingIcon(context, Icons.account_circle_outlined),
        title: Text(settings.googleAccountEmail ?? 'Belum Login Google'),
        subtitle: const Text('Untuk backup ke Google Drive'),
        trailing: settings.googleAccountEmail == null
            ? Icon(Icons.login_rounded, color: colorScheme.primary)
            : Icon(Icons.logout_rounded, color: colorScheme.error),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final isLogin = settings.googleAccountEmail == null;

          // Login uses a dedicated flow that also auto-restores the latest
          // backup; logout stays a simple sign-out.
          if (isLogin) {
            await _signInAndRestore(context, ref);
            return;
          }

          try {
            await LoadingDialog.run(
              context,
              message: 'Keluar dari akun...',
              task: () => backupService.signOut(),
            );
            // Refresh settings to update UI with new account status
            ref.invalidate(settingsProvider);
          } catch (e) {
            messenger.showSnackBar(
              AppSnackBar.error(colorScheme, 'Gagal keluar: $e'),
            );
          }
        },
      ),
      if (settings.googleAccountEmail != null) ...[
        SwitchListTile(
          secondary: _leadingIcon(context, Icons.backup_outlined),
          title: const Text('Auto Backup'),
          subtitle: const Text('Backup otomatis ke Google Drive'),
          value: settings.autoBackupEnabled,
          onChanged: (value) => notifier.setAutoBackupEnabled(value),
        ),
        ListTile(
          leading: _leadingIcon(context, Icons.cloud_upload_outlined),
          title: const Text('Backup Data'),
          subtitle: Text(
            settings.lastBackupDate != null
                ? 'Terakhir: ${settings.lastBackupDate}'
                : 'Belum pernah backup',
          ),
          onTap: () => _confirmManualBackup(context, ref),
        ),
        ListTile(
          leading: _leadingIcon(
            context,
            Icons.cloud_download_outlined,
            container: colorScheme.tertiaryContainer,
            foreground: colorScheme.tertiary,
          ),
          title: const Text('Restore Data'),
          subtitle: const Text('Kembalikan data dari Google Drive'),
          onTap: () => _showRestoreDialog(context, ref),
        ),
      ],
    ]);
  }

  /// Sign in to Google and restore the most recent backup.
  ///
  /// Behaviour:
  /// - No backup on the account (new user) → just login, nothing restored.
  /// - Local data is empty (fresh install / after reset) → restore silently,
  ///   no confirmation needed since nothing can be overwritten.
  /// - Local data already exists → ask for confirmation before overwriting it.
  Future<void> _signInAndRestore(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final dbService = ref.read(databaseServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      // 1. Sign in, find the latest backup, and check for existing local data.
      final result =
          await LoadingDialog.run<({String? latestId, bool hasLocalData})>(
            context,
            message: 'Menghubungkan ke Google...',
            task: () async {
              await backupService.signIn();

              // listBackups() returns newest-first, so the first entry is latest.
              final backups = await backupService.listBackups();
              final latestId = backups.isNotEmpty ? backups.first.id : null;

              final prayers = await dbService.getAllPrayers();
              return (latestId: latestId, hasLocalData: prayers.isNotEmpty);
            },
          );

      // 2. No backup available → login only.
      if (result.latestId == null) {
        ref.invalidate(settingsProvider);
        messenger.showSnackBar(
          AppSnackBar.success(
            colorScheme,
            'Login berhasil. Belum ada backup untuk dipulihkan.',
          ),
        );
        return;
      }

      // 3. Local data exists → confirm before overwriting it.
      if (result.hasLocalData) {
        if (!context.mounted) return;
        final confirmed = await _confirmRestoreOnLogin(context);
        if (confirmed != true) {
          ref.invalidate(settingsProvider);
          messenger.showSnackBar(
            AppSnackBar.success(
              colorScheme,
              'Login berhasil. Data lokal dipertahankan.',
            ),
          );
          return;
        }
      }

      // 4. Restore the latest backup.
      if (!context.mounted) return;
      await LoadingDialog.run(
        context,
        message: 'Memulihkan data backup terbaru...',
        task: () => backupService.restore(result.latestId!),
      );

      ref.invalidate(settingsProvider);
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(prayerTimesProvider);

      messenger.showSnackBar(
        AppSnackBar.success(
          colorScheme,
          'Login berhasil & data backup terbaru dipulihkan!',
        ),
      );
    } catch (e) {
      // Login may have succeeded even if a later step failed, so refresh the
      // account status regardless. Sign-in cancellation also lands here.
      ref.invalidate(settingsProvider);
      messenger.showSnackBar(AppSnackBar.error(colorScheme, 'Gagal masuk: $e'));
    }
  }

  /// Confirmation shown when login would overwrite existing local data.
  /// Destructive (overwrite) so the confirming action is an error [FilledButton].
  Future<bool?> _confirmRestoreOnLogin(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pulihkan Data Backup?'),
        content: const Text(
          'Login berhasil. Kamu sudah punya data di perangkat ini. '
          'Memulihkan backup terbaru akan MENIMPA data tersebut. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Pertahankan Data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmManualBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup Sekarang?'),
        content: const Text('Data kamu akan disimpan ke Google Drive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Backup'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await _performManualBackup(context, ref);
  }

  Future<void> _performManualBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await LoadingDialog.run(
        context,
        message: 'Sedang melakukan backup...',
        task: () async {
          await backupService.init();
          await backupService.backup();
          await notifier.refresh();
        },
      );

      messenger.showSnackBar(
        AppSnackBar.success(colorScheme, 'Backup berhasil!'),
      );
    } catch (e) {
      messenger.showSnackBar(
        AppSnackBar.error(colorScheme, 'Gagal backup: $e'),
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    // Capture references before any async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await backupService.init();
    if (!context.mounted) return;

    try {
      final List<drive.File> backups = await LoadingDialog.run(
        context,
        message: 'Memuat daftar backup...',
        task: () => backupService.listBackups(),
      );

      if (!context.mounted) return;

      // Show Selection Dialog on Root Navigator
      final colorScheme = Theme.of(context).colorScheme;
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          // Local mutable copy so deletions update the list in place.
          final items = [...backups];
          return StatefulBuilder(
            builder: (statefulContext, setDialogState) {
              return AlertDialog(
                title: const Text('Pilih Backup untuk Dipulihkan'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: items.isEmpty
                      ? Text(
                          'Belum ada backup tersimpan.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (listContext, index) {
                            final file = items[index];
                            final createdLocal = file.createdTime?.toLocal();
                            final dateLabel = createdLocal != null
                                ? DateFormat(
                                    'd MMM yyyy, HH:mm',
                                    'id_ID',
                                  ).format(createdLocal)
                                : 'Tanggal tidak diketahui';
                            final isLatest = index == 0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: Icon(
                                Icons.restore_rounded,
                                color: colorScheme.primary,
                              ),
                              title: Text(
                                dateLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: isLatest
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Terbaru',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colorScheme.error,
                                ),
                                tooltip: 'Hapus backup',
                                onPressed: () async {
                                  final fileId = file.id;
                                  if (fileId == null) return;

                                  final confirmed = await showDialog<bool>(
                                    context: statefulContext,
                                    useRootNavigator: true,
                                    builder: (confirmContext) => AlertDialog(
                                      title: const Text('Hapus Backup?'),
                                      content: Text(
                                        'Backup $dateLabel akan dihapus permanen dari Google Drive.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            confirmContext,
                                          ).pop(false),
                                          child: const Text('Batal'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: colorScheme.error,
                                            foregroundColor:
                                                colorScheme.onError,
                                          ),
                                          onPressed: () => Navigator.of(
                                            confirmContext,
                                          ).pop(true),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed != true) return;

                                  try {
                                    await backupService.deleteBackup(fileId);
                                    setDialogState(() => items.removeAt(index));
                                    scaffoldMessenger.showSnackBar(
                                      AppSnackBar.info(
                                        colorScheme,
                                        'Backup dihapus.',
                                      ),
                                    );
                                  } catch (e) {
                                    scaffoldMessenger.showSnackBar(
                                      AppSnackBar.error(
                                        colorScheme,
                                        'Gagal menghapus: $e',
                                      ),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                final fileId = file.id;
                                if (fileId == null) return;
                                // Pop Selection Dialog from Root Navigator
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();

                                _confirmRestore(
                                  context,
                                  ref,
                                  fileId,
                                  router,
                                  scaffoldMessenger,
                                  backupService,
                                );
                              },
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text('Batal'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        AppSnackBar.error(
          Theme.of(context).colorScheme,
          'Gagal mengambil list backup: $e',
        ),
      );
    }
  }

  void _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    String fileId,
    GoRouter router,
    ScaffoldMessengerState scaffoldMessenger,
    BackupService backupService,
  ) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'PERINGATAN: Tindakan ini akan MENIMPA data yang ada sekarang dengan data dari backup. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

              // Capture colors before async operations
              final colorScheme = Theme.of(context).colorScheme;

              try {
                await LoadingDialog.run(
                  context,
                  message: 'Sedang memulihkan data...',
                  task: () => backupService.restore(fileId),
                );

                ref.invalidate(settingsProvider);
                ref.invalidate(todayPrayersProvider);
                ref.invalidate(prayerTimesProvider);

                scaffoldMessenger.showSnackBar(
                  AppSnackBar.success(colorScheme, 'Data berhasil di-restore!'),
                );

                // Navigate using stored router
                router.go(AppRoutes.home);
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  AppSnackBar.error(colorScheme, 'Gagal restore: $e'),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildSection(context, 'Tentang Aplikasi', [
      ListTile(
        leading: _leadingIcon(
          context,
          Icons.info_outline_rounded,
          container: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        ),
        title: const Text('Versi Aplikasi'),
        subtitle: const Text('1.0.0 (Beta)'),
      ),
      // Destructive action: error-tinted icon + title to set it apart from
      // the neutral entries above (M3 destructive emphasis).
      ListTile(
        leading: _leadingIcon(
          context,
          Icons.delete_forever_outlined,
          container: colorScheme.errorContainer,
          foreground: colorScheme.error,
        ),
        title: Text('Reset Data', style: TextStyle(color: colorScheme.error)),
        subtitle: const Text(
          'Hapus data di perangkat (backup Drive tetap aman)',
        ),
        onTap: () => _showResetConfirmDialog(context, ref),
      ),
    ]);
  }

  void _showCitySearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => _CitySearchDialog());
  }

  void _showResetConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Reset Data?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Ini akan menghapus SEMUA data solat dan setting di perangkat ini. '
          'Backup di Google Drive TIDAK ikut terhapus, jadi data masih bisa '
          'dipulihkan lewat Restore. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _resetData(context, ref);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      // Blocking progress for the destructive op (matches backup/restore).
      await LoadingDialog.run(
        context,
        message: 'Mereset data...',
        task: () async {
          await ref.read(databaseServiceProvider).deleteAllData();
          await ref.read(preferencesServiceProvider).clearAll();
        },
      );

      ref.invalidate(settingsProvider);
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(prayerTimesProvider);

      messenger.showSnackBar(
        AppSnackBar.success(colorScheme, 'Data berhasil direset'),
      );
      if (context.mounted) context.go(AppRoutes.home);
    } catch (e) {
      messenger.showSnackBar(
        AppSnackBar.error(colorScheme, 'Gagal reset data: $e'),
      );
    }
  }
}

/// Single-select theme option backed by the accessible M3 [RadioListTile].
/// Selection state is announced to screen readers automatically (unlike the
/// previous check-icon approach). The enclosing [RadioGroup] handles changes.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _CitySearchDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends ConsumerState<_CitySearchDialog> {
  final _searchController = TextEditingController();
  List<City> _cities = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(prayerApiServiceProvider);
      final cities = await apiService.searchCities(query);
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cari Kota', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kota (min. 3 huruf)',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search_rounded, color: colorScheme.primary),
                  tooltip: 'Cari',
                  onPressed: () => _searchCities(_searchController.text),
                ),
              ),
              onSubmitted: _searchCities,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: TextStyle(color: colorScheme.error))
            else if (_cities.isEmpty && _searchController.text.isNotEmpty)
              Text(
                'Kota tidak ditemukan',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      title: Text(city.name),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref
                            .read(settingsProvider.notifier)
                            .setCity(id: city.id, name: city.name);

                        await ref.read(prayerTimesProvider.notifier).refresh();

                        if (context.mounted) {
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            AppSnackBar.success(
                              colorScheme,
                              'Kota diubah ke ${city.name}',
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
