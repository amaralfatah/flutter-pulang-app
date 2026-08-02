import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/services.dart';
import 'prayer_provider.dart';
import 'prayer_times_provider.dart';

/// App version/build info, read once from the platform.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Whether the OS currently permits notifications — separate from the
/// in-app "notificationEnabled" preference, which only reflects what the
/// user asked for, not whether the OS actually grants it.
final notificationsPermittedProvider = FutureProvider<bool>((ref) {
  return ref.watch(notificationServiceProvider).areNotificationsPermitted();
});

/// State for app settings
class SettingsState {
  final String? cityId;
  final String? cityName;
  final bool notificationEnabled;
  final bool autoBackupEnabled;
  final String? lastBackupDate;
  final String? googleAccountEmail;
  final String themeMode; // 'system', 'light', 'dark'
  final bool isLoading;

  const SettingsState({
    this.cityId,
    this.cityName,
    this.notificationEnabled = true,
    this.autoBackupEnabled = true,
    this.lastBackupDate,
    this.googleAccountEmail,
    this.themeMode = 'system',
    this.isLoading = false,
  });

  SettingsState copyWith({
    String? cityId,
    String? cityName,
    bool? notificationEnabled,
    bool? autoBackupEnabled,
    String? lastBackupDate,
    String? googleAccountEmail,
    String? themeMode,
    bool? isLoading,
  }) {
    return SettingsState(
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      googleAccountEmail: googleAccountEmail ?? this.googleAccountEmail,
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Check if city is selected
  bool get hasCitySelected => cityId != null && cityId!.isNotEmpty;

  /// Check if Google account is connected
  bool get isGoogleConnected =>
      googleAccountEmail != null && googleAccountEmail!.isNotEmpty;
}

/// Notifier for settings (Riverpod 3 syntax)
class SettingsNotifier extends Notifier<SettingsState> {
  PreferencesService get _preferencesService =>
      ref.read(preferencesServiceProvider);
  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState(isLoading: true);
  }

  /// Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    final cityId = await _preferencesService.getCityId();
    final cityName = await _preferencesService.getCityName();
    final notificationEnabled = await _preferencesService
        .isNotificationEnabled();
    final autoBackupEnabled = await _preferencesService.isAutoBackupEnabled();
    final lastBackupDate = await _preferencesService.getLastBackupDate();
    final googleAccountEmail = await _preferencesService
        .getGoogleAccountEmail();
    final themeMode = await _preferencesService.getThemeMode();

    state = SettingsState(
      cityId: cityId,
      cityName: cityName,
      notificationEnabled: notificationEnabled,
      autoBackupEnabled: autoBackupEnabled,
      lastBackupDate: lastBackupDate,
      googleAccountEmail: googleAccountEmail,
      themeMode: themeMode,
      isLoading: false,
    );
  }

  /// Set city
  Future<void> setCity({required String id, required String name}) async {
    await _preferencesService.setCity(id: id, name: name);
    state = state.copyWith(cityId: id, cityName: name);
  }

  /// Set notification enabled
  Future<void> setNotificationEnabled(bool enabled) async {
    await _preferencesService.setNotificationEnabled(enabled);
    state = state.copyWith(notificationEnabled: enabled);

    if (enabled) {
      // Request permission, then schedule immediately using the prayer times
      // already loaded — no need to wait for the next fetch. prayerTimesProvider
      // doesn't depend on settingsProvider, so reading it here is safe.
      await _notificationService.requestPermissions();
      final prayerTime = ref.read(prayerTimesProvider).prayerTime;
      if (prayerTime != null) {
        await _notificationService.schedulePrayerNotifications(prayerTime);
      }
      // Also arm the daily background rescheduler, in case the user enables
      // this without an app restart (app.dart only schedules it on launch).
      await NotificationService.scheduleDailyReschedule();
    } else {
      await _notificationService.cancelAllNotifications();
    }
  }

  /// Set auto backup enabled
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _preferencesService.setAutoBackupEnabled(enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  /// Set last backup date
  Future<void> setLastBackupDate(String date) async {
    await _preferencesService.setLastBackupDate(date);
    state = state.copyWith(lastBackupDate: date);
  }

  /// Set Google account email
  Future<void> setGoogleAccountEmail(String? email) async {
    await _preferencesService.setGoogleAccountEmail(email);
    state = state.copyWith(googleAccountEmail: email);
  }

  /// Clear Google account
  Future<void> clearGoogleAccount() async {
    await _preferencesService.setGoogleAccountEmail(null);
    state = state.copyWith(googleAccountEmail: null);
  }

  /// Set theme mode ('system', 'light', 'dark')
  Future<void> setThemeMode(String mode) async {
    await _preferencesService.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  /// Refresh settings
  Future<void> refresh() => _loadSettings();
}

/// Provider for settings
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Provider for city name display
final cityDisplayProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.cityName ?? 'Pilih Kota';
});

/// Provider for checking if setup is complete
final isSetupCompleteProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.hasCitySelected;
});
