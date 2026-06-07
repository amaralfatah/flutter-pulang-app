import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:googleapis/drive/v3.dart' as drive;

import '../../app/router.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Lokasi'),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            settings.cityName ?? 'Belum pilih kota',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Digunakan untuk jadwal solat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: () => _showCitySearchDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Notifikasi'),
        SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: const Text(
            'Aktifkan Notifikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Notifikasi saat masuk waktu solat',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          value: settings.notificationEnabled,
          onChanged: (value) => notifier.setNotificationEnabled(value),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notification_important_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          title: const Text(
            'Test Notifikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Kirim notifikasi sekarang (Debug)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          onTap: () async {
            await ref.read(notificationServiceProvider).requestPermissions();
            await ref
                .read(notificationServiceProvider)
                .showNotification(
                  id: 999,
                  title: 'Test Notifikasi',
                  body: 'Ini adalah contoh notifikasi waktu solat.',
                );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Notifikasi dikirim (Tunggu beberapa detik)',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              );
            }
          },
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_send_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          title: const Text(
            'Test Notifikasi Terjadwal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Jadwalkan via alarm, muncul 1 menit lagi (Debug)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final secondaryColor = Theme.of(context).colorScheme.secondary;
            final errorColor = Theme.of(context).colorScheme.error;
            final service = ref.read(notificationServiceProvider);

            final granted = await service.requestPermissions();
            if (!granted) {
              messenger.showSnackBar(
                SnackBar(
                  content: const Text(
                    'Izin notifikasi belum diberikan. Aktifkan di pengaturan HP.',
                  ),
                  backgroundColor: errorColor,
                ),
              );
              return;
            }

            final fireAt = await service.scheduleTestNotification();
            final timeLabel = DateFormat('HH:mm:ss').format(fireAt);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Alarm dijadwalkan pukul $timeLabel. '
                  'Biarkan/keluar app, notifikasi akan muncul.',
                ),
                backgroundColor: secondaryColor,
              ),
            );
          },
        ),
      ],
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Tampilan'),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              getThemeModeIcon(settings.themeMode),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: const Text(
            'Mode Tampilan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            getThemeModeLabel(settings.themeMode),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: () => _showThemeModeDialog(context, settings, notifier),
        ),
      ],
    );
  }

  void _showThemeModeDialog(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pilih Mode Tampilan',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: context,
              icon: Icons.brightness_auto_outlined,
              title: 'Ikuti Sistem',
              subtitle: 'Otomatis sesuai pengaturan perangkat',
              value: 'system',
              currentValue: settings.themeMode,
              onTap: () {
                notifier.setThemeMode('system');
                Navigator.pop(context);
              },
            ),
            _buildThemeOption(
              context: context,
              icon: Icons.light_mode_outlined,
              title: 'Mode Terang',
              subtitle: 'Tampilan cerah untuk siang hari',
              value: 'light',
              currentValue: settings.themeMode,
              onTap: () {
                notifier.setThemeMode('light');
                Navigator.pop(context);
              },
            ),
            _buildThemeOption(
              context: context,
              icon: Icons.dark_mode_outlined,
              title: 'Mode Gelap',
              subtitle: 'Tampilan gelap untuk malam hari',
              value: 'dark',
              currentValue: settings.themeMode,
              onTap: () {
                notifier.setThemeMode('dark');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildBackupSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final backupService = ref.read(backupServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Backup & Data'),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            settings.googleAccountEmail ?? 'Belum Login Google',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Untuk backup ke Google Drive',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          trailing: settings.googleAccountEmail == null
              ? Icon(
                  Icons.login_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final errorColor = Theme.of(context).colorScheme.error;
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
                SnackBar(
                  content: Text('Gagal keluar: $e'),
                  backgroundColor: errorColor,
                ),
              );
            }
          },
        ),
        if (settings.googleAccountEmail != null) ...[
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.backup_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: const Text(
              'Auto Backup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Backup otomatis ke Google Drive',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            value: settings.autoBackupEnabled,
            onChanged: (value) => notifier.setAutoBackupEnabled(value),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: const Text(
              'Backup Data',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              settings.lastBackupDate != null
                  ? 'Terakhir: ${settings.lastBackupDate}'
                  : 'Belum pernah backup',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            onTap: () => _confirmManualBackup(context, ref),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            title: const Text(
              'Restore Data',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Kembalikan data dari Google Drive',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            onTap: () => _showRestoreDialog(context, ref),
          ),
        ],
      ],
    );
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
      final result = await LoadingDialog.run<({String? latestId, bool hasLocalData})>(
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
          SnackBar(
            content: const Text(
              'Login berhasil. Belum ada backup untuk dipulihkan.',
            ),
            backgroundColor: colorScheme.primary,
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
            SnackBar(
              content: const Text('Login berhasil. Data lokal dipertahankan.'),
              backgroundColor: colorScheme.primary,
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
        SnackBar(
          content: const Text('Login berhasil & data backup terbaru dipulihkan!'),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      // Login may have succeeded even if a later step failed, so refresh the
      // account status regardless. Sign-in cancellation also lands here.
      ref.invalidate(settingsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal masuk: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  /// Confirmation shown when login would overwrite existing local data.
  Future<bool?> _confirmRestoreOnLogin(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Pulihkan Data Backup?',
          style: TextStyle(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Login berhasil. Kamu sudah punya data di perangkat ini. '
          'Memulihkan backup terbaru akan MENIMPA data tersebut. Lanjutkan?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Pertahankan Data',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmManualBackup(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Backup Sekarang?',
          style: TextStyle(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Data kamu akan disimpan ke Google Drive.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
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
        SnackBar(
          content: const Text('Backup berhasil!'),
          backgroundColor: colorScheme.primary, // success -> primary
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal backup: $e'),
          backgroundColor: colorScheme.error,
        ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                title: Text(
                  'Pilih Backup untuk Dipulihkan',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                            style: TextStyle(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          20.0,
                                        ),
                                      ),
                                      title: Text(
                                        'Hapus Backup?',
                                        style: TextStyle(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Backup $dateLabel akan dihapus permanen dari Google Drive.',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            confirmContext,
                                          ).pop(false),
                                          child: Text(
                                            'Batal',
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: colorScheme.error,
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
                                      SnackBar(
                                        content: const Text('Backup dihapus.'),
                                        backgroundColor: colorScheme.secondary,
                                      ),
                                    );
                                  } catch (e) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menghapus: $e'),
                                        backgroundColor: colorScheme.error,
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
                    child: Text(
                      'Batal',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil list backup: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Restore Data?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'PERINGATAN: Tindakan ini akan MENIMPA data yang ada sekarang dengan data dari backup. Lanjutkan?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

              // Capture colors before async operations
              final primaryColor = Theme.of(context).colorScheme.primary;
              final errorColor = Theme.of(context).colorScheme.error;

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
                  SnackBar(
                    content: const Text('Data berhasil di-restore!'),
                    backgroundColor: primaryColor,
                  ),
                );

                // Navigate using stored router
                router.go(AppRoutes.home);
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal restore: $e'),
                    backgroundColor: errorColor,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Tentang Aplikasi'),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: const Text(
            'Versi Aplikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '1.0.0 (Beta)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          title: Text(
            'Reset Data',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          subtitle: Text(
            'Hapus data di perangkat (backup Drive tetap aman)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          onTap: () => _showResetConfirmDialog(context, ref),
        ),
        const SizedBox(height: 32),
      ],
    );
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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mereset data...'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.deleteAllData();

      final prefService = ref.read(preferencesServiceProvider);
      await prefService.clearAll();

      ref.invalidate(settingsProvider);
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(prayerTimesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data berhasil direset'),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary, // success -> primary
          ),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal reset data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cari Kota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kota (min. 3 huruf)',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _searchCities(_searchController.text),
                ),
              ),
              onSubmitted: _searchCities,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              )
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_cities.isEmpty && _searchController.text.isNotEmpty)
              Text(
                'Kota tidak ditemukan',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      title: Text(
                        city.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setCity(id: city.id, name: city.name);

                        await ref.read(prayerTimesProvider.notifier).refresh();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kota diubah ke ${city.name}'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary, // success -> primary
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
