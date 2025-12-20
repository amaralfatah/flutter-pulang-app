import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences helper for app settings
class PreferencesService {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyCityId = 'city_id';
  static const String _keyCityName = 'city_name';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keyLastBackupDate = 'last_backup_date';
  static const String _keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String _keyGoogleAccountEmail = 'google_account_email';

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ CITY SETTINGS ============

  /// Get saved city ID
  Future<String?> getCityId() async {
    final p = await prefs;
    return p.getString(_keyCityId);
  }

  /// Set city ID
  Future<bool> setCityId(String cityId) async {
    final p = await prefs;
    return p.setString(_keyCityId, cityId);
  }

  /// Get saved city name
  Future<String?> getCityName() async {
    final p = await prefs;
    return p.getString(_keyCityName);
  }

  /// Set city name
  Future<bool> setCityName(String cityName) async {
    final p = await prefs;
    return p.setString(_keyCityName, cityName);
  }

  /// Set city (both ID and name)
  Future<void> setCity({required String id, required String name}) async {
    await setCityId(id);
    await setCityName(name);
  }

  // ============ NOTIFICATION SETTINGS ============

  /// Check if notifications are enabled
  Future<bool> isNotificationEnabled() async {
    final p = await prefs;
    return p.getBool(_keyNotificationEnabled) ?? true;
  }

  /// Set notification enabled/disabled
  Future<bool> setNotificationEnabled(bool enabled) async {
    final p = await prefs;
    return p.setBool(_keyNotificationEnabled, enabled);
  }

  // ============ BACKUP SETTINGS ============

  /// Get last backup date
  Future<String?> getLastBackupDate() async {
    final p = await prefs;
    return p.getString(_keyLastBackupDate);
  }

  /// Set last backup date
  Future<bool> setLastBackupDate(String date) async {
    final p = await prefs;
    return p.setString(_keyLastBackupDate, date);
  }

  /// Check if auto backup is enabled
  Future<bool> isAutoBackupEnabled() async {
    final p = await prefs;
    return p.getBool(_keyAutoBackupEnabled) ?? true;
  }

  /// Set auto backup enabled/disabled
  Future<bool> setAutoBackupEnabled(bool enabled) async {
    final p = await prefs;
    return p.setBool(_keyAutoBackupEnabled, enabled);
  }

  // ============ GOOGLE ACCOUNT ============

  /// Get connected Google account email
  Future<String?> getGoogleAccountEmail() async {
    final p = await prefs;
    return p.getString(_keyGoogleAccountEmail);
  }

  /// Set connected Google account email
  Future<bool> setGoogleAccountEmail(String? email) async {
    final p = await prefs;
    if (email == null) {
      return p.remove(_keyGoogleAccountEmail);
    }
    return p.setString(_keyGoogleAccountEmail, email);
  }

  // ============ UTILITY METHODS ============

  /// Get all settings as a Map (for backup)
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'city_id': await getCityId(),
      'city_name': await getCityName(),
      'notification_enabled': await isNotificationEnabled(),
      'auto_backup_enabled': await isAutoBackupEnabled(),
      'last_backup_date': await getLastBackupDate(),
    };
  }

  /// Restore settings from backup
  Future<void> restoreSettings(Map<String, dynamic> settings) async {
    if (settings['city_id'] != null) {
      await setCityId(settings['city_id'] as String);
    }
    if (settings['city_name'] != null) {
      await setCityName(settings['city_name'] as String);
    }
    if (settings['notification_enabled'] != null) {
      await setNotificationEnabled(settings['notification_enabled'] as bool);
    }
    if (settings['auto_backup_enabled'] != null) {
      await setAutoBackupEnabled(settings['auto_backup_enabled'] as bool);
    }
  }

  /// Clear all settings
  Future<bool> clearAll() async {
    final p = await prefs;
    return p.clear();
  }
}
