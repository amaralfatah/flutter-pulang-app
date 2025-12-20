import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

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
          color: AppColors.secondary,
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            settings.cityName ?? 'Belum pilih kota',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Digunakan untuk jadwal solat',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
          ),
          title: const Text(
            'Aktifkan Notifikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Notifikasi saat masuk waktu solat',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          value: settings.notificationEnabled,
          onChanged: (value) => notifier.setNotificationEnabled(value),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notification_important_outlined,
              color: AppColors.accent,
            ),
          ),
          title: const Text(
            'Test Notifikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Kirim notifikasi sekarang (Debug)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                const SnackBar(
                  content: Text('Notifikasi dikirim (Tunggu beberapa detik)'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            }
          },
        ),
      ],
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            settings.googleAccountEmail ?? 'Belum Login Google',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Untuk backup ke Google Drive',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          trailing: settings.googleAccountEmail == null
              ? const Icon(Icons.login_rounded, color: AppColors.primary)
              : const Icon(Icons.logout_rounded, color: AppColors.error),
          onTap: () async {
            if (settings.googleAccountEmail == null) {
              await backupService.signIn();
            } else {
              await backupService.signOut();
            }
            // Refresh settings to update UI with new account status
            ref.invalidate(settingsProvider);
          },
        ),
        if (settings.googleAccountEmail != null) ...[
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.backup_outlined,
                color: AppColors.primary,
              ),
            ),
            title: const Text(
              'Auto Backup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Backup otomatis ke Google Drive',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            value: settings.autoBackupEnabled,
            onChanged: (value) => notifier.setAutoBackupEnabled(value),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.primary,
              ),
            ),
            title: const Text(
              'Backup Sekarang',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              settings.lastBackupDate != null
                  ? 'Terakhir: ${settings.lastBackupDate}'
                  : 'Belum pernah backup',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            onTap: () => _performManualBackup(context, ref),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_download_outlined,
                color: AppColors.accent,
              ),
            ),
            title: const Text(
              'Restore Data',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Kembalikan data dari Google Drive',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            onTap: () => _showRestoreDialog(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _performManualBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final notifier = ref.read(settingsProvider.notifier);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sedang melakukan backup...'),
        backgroundColor: AppColors.secondary,
      ),
    );

    try {
      await backupService.init();
      await backupService.backup();
      await notifier.refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup berhasil!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    // Capture references before any async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await backupService.init();
    if (!context.mounted) return;

    // Show Loading Dialog on Root Navigator
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final backups = await backupService.listBackups();

      // Pop Loading Dialog from Root Navigator
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      // Show Selection Dialog on Root Navigator
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          title: const Text(
            'Pilih File Backup',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: backups.isEmpty
                ? const Text(
                    'Tidak ada file backup ditemukan.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    itemBuilder: (listContext, index) {
                      final file = backups[index];
                      final created = file.createdTime != null
                          ? file.createdTime!.toLocal().toString().split('.')[0]
                          : 'Unknown Date';
                      return ListTile(
                        title: Text(
                          'Backup $created',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          file.name ?? 'No Name',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          final fileId = file.id!;
                          // Pop Selection Dialog from Root Navigator
                          Navigator.of(context, rootNavigator: true).pop();

                          // Use stored router and scaffoldMessenger
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
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Pop Loading Dialog if error
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil list backup: $e'),
          backgroundColor: AppColors.error,
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
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        title: const Text(
          'Restore Data?',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'PERINGATAN: Tindakan ini akan MENIMPA data yang ada sekarang dengan data dari backup. Lanjutkan?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Sedang me-restore data...'),
                  backgroundColor: AppColors.secondary,
                ),
              );

              try {
                await backupService.restore(fileId);

                ref.invalidate(settingsProvider);
                ref.invalidate(todayPrayersProvider);
                ref.invalidate(prayerTimesProvider);

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Data berhasil di-restore!'),
                    backgroundColor: AppColors.success,
                  ),
                );

                // Navigate using stored router
                router.go(AppRoutes.home);
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal restore: $e'),
                    backgroundColor: AppColors.error,
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
              color: AppColors.textSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          title: const Text(
            'Versi Aplikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            '1.0.0 (Beta)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_forever_outlined,
              color: AppColors.error,
            ),
          ),
          title: const Text(
            'Reset Data',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          subtitle: const Text(
            'Hapus semua data dan kembali ke awal',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        title: const Text(
          'Reset Data?',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus SEMUA data solat dan setting? Tindakan ini tidak bisa dibatalkan.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
      const SnackBar(
        content: Text('Mereset data...'),
        backgroundColor: AppColors.secondary,
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
          const SnackBar(
            content: Text('Data berhasil direset'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal reset data: $e'),
            backgroundColor: AppColors.error,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cari Kota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kota (min. 3 huruf)',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _searchCities(_searchController.text),
                ),
              ),
              onSubmitted: _searchCities,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error))
            else if (_cities.isEmpty && _searchController.text.isNotEmpty)
              const Text(
                'Kota tidak ditemukan',
                style: TextStyle(color: AppColors.textSecondary),
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
                              backgroundColor: AppColors.success,
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
