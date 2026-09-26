import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:googleapis/drive/v3.dart' as drive;

import '../../app/extensions/context_extensions.dart';
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
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        children: [
          // Cards carry the grouping on their own now that most sections
          // dropped their header, so they need more air between them.
          _buildLocationSection(context, ref, settings),
          const SizedBox(height: 12),
          _buildNotificationSection(context, ref, settings, notifier),
          const SizedBox(height: 12),
          _buildAppearanceSection(context, ref, settings, notifier),
          const SizedBox(height: 12),
          _buildBackupSection(context, ref, settings, notifier),
          const SizedBox(height: 12),
          _buildAboutSection(context, ref, settings),
        ],
      ),
    );
  }

  /// [raw] is stored as ISO 8601; older installs may still have the legacy
  /// "yyyy-MM-dd HH:mm:ss" text, which also parses fine via [DateTime.tryParse].
  String _formatBackupDate(BuildContext context, String? raw) {
    if (raw == null) return context.l10n.settingsNeverBackedUp;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy, HH:mm', context.localeTag).format(parsed);
  }

  /// M3 list subheader: `titleSmall` in the primary colour (no ad-hoc bold).
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      // Top spacing comes from the gap between cards now, so keep this tight.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Groups a section's tiles inside a single M3 card surface.
  ///
  /// [title] is optional: most sections here hold a single self-describing
  /// tile, so a header would just repeat the tile's own label. Pass one only
  /// when the grouping isn't obvious from the tiles themselves.
  Widget _buildSection(
    BuildContext context,
    List<Widget> tiles, {
    String? title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _buildSectionHeader(context, title),
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
    return _buildSection(context, [
      ListTile(
        leading: _leadingIcon(context, Icons.location_on_outlined),
        title: Text(settings.cityName ?? context.l10n.settingsNoCitySelected),
        subtitle: Text(context.l10n.settingsLocationSubtitle),
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
    // The in-app toggle only reflects intent; the OS can still be silently
    // blocking every alarm behind it, which the toggle alone can't reveal.
    final osPermitted = ref.watch(notificationsPermittedProvider);
    final showBlockedBanner =
        settings.notificationEnabled && (osPermitted.value == false);

    return _buildSection(context, [
      SwitchListTile(
        secondary: _leadingIcon(context, Icons.notifications_active_outlined),
        title: Text(context.l10n.settingsNotifTitle),
        subtitle: Text(context.l10n.settingsNotifSubtitle),
        value: settings.notificationEnabled,
        onChanged: (value) async {
          await notifier.setNotificationEnabled(value);
          ref.invalidate(notificationsPermittedProvider);
        },
      ),
      if (showBlockedBanner)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_off_rounded,
                      size: 18,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.settingsNotifBlockedBanner,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .requestPermissions();
                      ref.invalidate(notificationsPermittedProvider);
                    },
                    child: Text(context.l10n.settingsRequestPermissionAgain),
                  ),
                ),
              ],
            ),
          ),
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
          return context.l10n.settingsThemeLight;
        case 'dark':
          return context.l10n.settingsThemeDark;
        default:
          return context.l10n.commonFollowSystem;
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

    return _buildSection(context, [
      ListTile(
        leading: _leadingIcon(context, getThemeModeIcon(settings.themeMode)),
        title: Text(context.l10n.settingsThemeModeTitle),
        subtitle: Text(getThemeModeLabel(settings.themeMode)),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showThemeModeDialog(context, settings, notifier),
      ),
      ListTile(
        leading: _leadingIcon(context, Icons.translate_rounded),
        title: Text(context.l10n.settingsLanguageTitle),
        subtitle: Text(_languageLabel(context, settings.languageCode)),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showLanguageDialog(context, settings, notifier),
      ),
    ]);
  }

  /// Nama bahasa sengaja tidak diterjemahkan, supaya user yang salah pilih
  /// tetap bisa mengenali bahasanya sendiri.
  String _languageLabel(BuildContext context, String code) {
    switch (code) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      default:
        return context.l10n.commonFollowSystem;
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settingsLanguageDialogTitle),
        content: RadioGroup<String>(
          groupValue: settings.languageCode,
          onChanged: (selected) {
            if (selected != null) notifier.setLanguage(selected);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RadioOption(
                title: context.l10n.commonFollowSystem,
                subtitle: context.l10n.settingsLanguageSystemSubtitle,
                value: 'system',
              ),
              const _RadioOption(title: 'Bahasa Indonesia', value: 'id'),
              const _RadioOption(title: 'English', value: 'en'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonClose),
          ),
        ],
      ),
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
        title: Text(context.l10n.settingsThemeDialogTitle),
        content: RadioGroup<String>(
          groupValue: settings.themeMode,
          onChanged: (selected) {
            if (selected != null) notifier.setThemeMode(selected);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RadioOption(
                title: context.l10n.commonFollowSystem,
                subtitle: context.l10n.settingsThemeSystemSubtitle,
                value: 'system',
              ),
              _RadioOption(
                title: context.l10n.settingsThemeLight,
                subtitle: context.l10n.settingsThemeLightSubtitle,
                value: 'light',
              ),
              _RadioOption(
                title: context.l10n.settingsThemeDark,
                subtitle: context.l10n.settingsThemeDarkSubtitle,
                value: 'dark',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonClose),
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

    return _buildSection(context, [
      ListTile(
        leading: _leadingIcon(context, Icons.account_circle_outlined),
        title: Text(
          settings.googleAccountEmail ?? context.l10n.settingsGoogleNotLoggedIn,
        ),
        subtitle: Text(context.l10n.settingsGoogleLoginSubtitle),
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
              message: context.l10n.settingsSigningOut,
              task: () => backupService.signOut(),
            );
            // Refresh settings to update UI with new account status
            ref.invalidate(settingsProvider);
          } catch (e) {
            if (!context.mounted) return;
            messenger.showSnackBar(
              AppSnackBar.error(
                colorScheme,
                context.l10n.settingsSignOutFailed(e.toString()),
              ),
            );
          }
        },
      ),
      if (settings.googleAccountEmail != null) ...[
        SwitchListTile(
          secondary: _leadingIcon(context, Icons.backup_outlined),
          title: Text(context.l10n.settingsAutoBackupTitle),
          subtitle: Text(context.l10n.settingsAutoBackupSubtitle),
          value: settings.autoBackupEnabled,
          onChanged: (value) => notifier.setAutoBackupEnabled(value),
        ),
        ListTile(
          leading: _leadingIcon(context, Icons.cloud_upload_outlined),
          title: Text(context.l10n.settingsBackupDataTitle),
          subtitle: Text(
            context.l10n.settingsBackupDataSubtitle(
              _formatBackupDate(context, settings.lastBackupDate),
            ),
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
          title: Text(context.l10n.settingsRestoreDataTitle),
          subtitle: Text(context.l10n.settingsRestoreDataSubtitle),
          onTap: () => _showRestoreDialog(context, ref),
        ),
      ],
    ], title: context.l10n.settingsBackupSectionTitle);
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
            message: context.l10n.settingsConnectingGoogle,
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
        if (!context.mounted) return;
        messenger.showSnackBar(
          AppSnackBar.success(
            colorScheme,
            context.l10n.settingsLoginSuccessNoBackup,
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
          if (!context.mounted) return;
          messenger.showSnackBar(
            AppSnackBar.success(
              colorScheme,
              context.l10n.settingsLoginSuccessKeptLocal,
            ),
          );
          return;
        }
      }

      // 4. Restore the latest backup.
      if (!context.mounted) return;
      await LoadingDialog.run(
        context,
        message: context.l10n.settingsRestoringLatest,
        task: () => backupService.restore(result.latestId!),
      );

      ref.invalidate(settingsProvider);
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(prayerTimesProvider);

      if (!context.mounted) return;
      messenger.showSnackBar(
        AppSnackBar.success(
          colorScheme,
          context.l10n.settingsLoginRestoredSuccess,
        ),
      );
    } catch (e) {
      // Login may have succeeded even if a later step failed, so refresh the
      // account status regardless. Sign-in cancellation also lands here.
      ref.invalidate(settingsProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(
        AppSnackBar.error(colorScheme, context.l10n.settingsSignInFailed(e.toString())),
      );
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
        title: Text(context.l10n.settingsRestoreOnLoginTitle),
        content: Text(context.l10n.settingsRestoreOnLoginBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.settingsKeepLocalData),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.settingsRestoreCta),
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
        title: Text(context.l10n.settingsBackupNowTitle),
        content: Text(context.l10n.settingsBackupNowBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.settingsBackupCta),
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
    final l10n = context.l10n;

    try {
      await LoadingDialog.run(
        context,
        message: l10n.settingsBackingUp,
        task: () async {
          await backupService.init();
          await backupService.backup();
          await notifier.refresh();
        },
      );

      messenger.showSnackBar(
        AppSnackBar.success(colorScheme, l10n.settingsBackupSuccess),
      );
    } catch (e) {
      messenger.showSnackBar(
        AppSnackBar.error(colorScheme, l10n.settingsBackupFailed(e.toString())),
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    // Capture references before any async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = context.l10n;

    await backupService.init();
    if (!context.mounted) return;

    try {
      final List<drive.File> backups = await LoadingDialog.run(
        context,
        message: l10n.settingsLoadingBackupList,
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
                // Wider than the default 40px inset so each row fits the
                // full "d MMM yyyy, HH:mm" label alongside the delete button.
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                title: Text(l10n.settingsChooseBackupTitle),
                content: SizedBox(
                  width: double.maxFinite,
                  child: items.isEmpty
                      ? Text(
                          l10n.settingsNoBackupsSaved,
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
                                    context.localeTag,
                                  ).format(createdLocal)
                                : l10n.settingsUnknownDate;
                            final isLatest = index == 0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              horizontalTitleGap: 8,
                              minLeadingWidth: 24,
                              leading: Icon(
                                Icons.restore_rounded,
                                color: colorScheme.primary,
                              ),
                              // Wrap instead of ellipsizing: the dialog is
                              // narrow and the date is the whole point here.
                              title: Text(dateLabel, softWrap: true),
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
                                            l10n.settingsLatestBadge,
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
                                visualDensity: VisualDensity.compact,
                                tooltip: l10n.settingsDeleteBackupTooltip,
                                onPressed: () async {
                                  final fileId = file.id;
                                  if (fileId == null) return;

                                  final confirmed = await showDialog<bool>(
                                    context: statefulContext,
                                    useRootNavigator: true,
                                    builder: (confirmContext) => AlertDialog(
                                      title: Text(l10n.settingsDeleteBackupTitle),
                                      content: Text(
                                        l10n.settingsDeleteBackupBody(dateLabel),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            confirmContext,
                                          ).pop(false),
                                          child: Text(l10n.commonCancel),
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
                                          child: Text(l10n.settingsDeleteCta),
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
                                        l10n.settingsBackupDeleted,
                                      ),
                                    );
                                  } catch (e) {
                                    scaffoldMessenger.showSnackBar(
                                      AppSnackBar.error(
                                        colorScheme,
                                        l10n.settingsDeleteFailed(e.toString()),
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
                    child: Text(l10n.commonCancel),
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
          l10n.settingsListBackupFailed(e.toString()),
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
        title: Text(context.l10n.settingsRestoreConfirmTitle),
        content: Text(context.l10n.settingsRestoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

              // Capture colors and text before async operations
              final colorScheme = Theme.of(context).colorScheme;
              final l10n = context.l10n;

              try {
                await LoadingDialog.run(
                  context,
                  message: l10n.settingsRestoringData,
                  task: () => backupService.restore(fileId),
                );

                ref.invalidate(settingsProvider);
                ref.invalidate(todayPrayersProvider);
                ref.invalidate(prayerTimesProvider);

                scaffoldMessenger.showSnackBar(
                  AppSnackBar.success(colorScheme, l10n.settingsRestoreSuccess),
                );

                // Navigate using stored router
                router.go(AppRoutes.home);
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  AppSnackBar.error(colorScheme, l10n.settingsRestoreFailed(e.toString())),
                );
              }
            },
            child: Text(context.l10n.settingsRestoreCta),
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
    final packageInfo = ref.watch(packageInfoProvider);
    return _buildSection(context, [
      ListTile(
        leading: _leadingIcon(
          context,
          Icons.info_outline_rounded,
          container: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        ),
        title: Text(context.l10n.settingsAppVersionTitle),
        subtitle: Text(
          packageInfo.when(
            data: (info) => '${info.version} (${info.buildNumber})',
            loading: () => '...',
            error: (_, _) => '-',
          ),
        ),
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
        title: Text(
          context.l10n.settingsResetDataTitle,
          style: TextStyle(color: colorScheme.error),
        ),
        subtitle: Text(context.l10n.settingsResetDataSubtitle),
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
          context.l10n.settingsResetConfirmTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(context.l10n.settingsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
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
            child: Text(context.l10n.settingsResetCta),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    try {
      // Blocking progress for the destructive op (matches backup/restore).
      await LoadingDialog.run(
        context,
        message: l10n.settingsResetting,
        task: () async {
          await ref.read(databaseServiceProvider).deleteAllData();
          await ref.read(preferencesServiceProvider).clearAll();
        },
      );

      ref.invalidate(settingsProvider);
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(prayerTimesProvider);

      messenger.showSnackBar(
        AppSnackBar.success(colorScheme, l10n.settingsResetSuccess),
      );
      if (context.mounted) context.go(AppRoutes.home);
    } catch (e) {
      messenger.showSnackBar(
        AppSnackBar.error(colorScheme, l10n.settingsResetFailed(e.toString())),
      );
    }
  }
}

/// Single-select radio option backed by the accessible M3 [RadioListTile].
/// Selection state is announced to screen readers automatically (unlike the
/// previous check-icon approach). The enclosing [RadioGroup] handles changes.
/// Used by both the theme and language dialogs.
class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.title, this.subtitle, required this.value});

  final String title;
  final String? subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
    );
  }
}

class _CitySearchDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends ConsumerState<_CitySearchDialog> {
  static const _minQueryLength = 3;

  final _searchController = TextEditingController();
  List<City> _cities = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Ketikan dijeda 400ms sebelum menembak API, supaya tiap huruf yang
  /// diketik tidak memicu request sendiri-sendiri.
  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < _minQueryLength) {
      setState(() {
        _cities = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchCities(query);
    });
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().length < _minQueryLength) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(prayerApiServiceProvider);
      final cities = await apiService.searchCities(query);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCity(City city) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    await ref
        .read(settingsProvider.notifier)
        .setCity(id: city.id, name: city.name);
    await ref.read(prayerTimesProvider.notifier).refresh();
    // Best-effort: warm the offline cache for the newly chosen city too.
    unawaited(
      ref
          .read(prayerApiServiceProvider)
          .prefetchPrayerTimes(cityId: city.id),
    );

    if (!mounted) return;
    final message = context.l10n.settingsCityChanged(city.name);
    Navigator.pop(context);
    messenger.showSnackBar(AppSnackBar.success(colorScheme, message));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchController.text.trim();

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.settingsCitySearchTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.settingsCitySearchHint(_minQueryLength),
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
                  tooltip: context.l10n.settingsCitySearchTooltip,
                  onPressed: _isLoading
                      ? null
                      : () => _searchCities(_searchController.text),
                ),
              ),
              onChanged: _onQueryChanged,
              onSubmitted: _searchCities,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: TextStyle(color: colorScheme.error))
            else if (query.length < _minQueryLength && query.isNotEmpty)
              Text(
                context.l10n.settingsCitySearchMinChars(_minQueryLength),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else if (_cities.isEmpty && query.isNotEmpty)
              Text(
                context.l10n.onboardingCityNotFound,
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
                      onTap: () => _selectCity(city),
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
