import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'history_provider.dart';
import 'statistics_provider.dart';

/// Database service provider (singleton)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Preferences service provider (singleton)
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Prayer API service provider
final prayerApiServiceProvider = Provider<PrayerApiService>((ref) {
  return PrayerApiService(
    databaseService: ref.watch(databaseServiceProvider),
    preferencesService: ref.watch(preferencesServiceProvider),
  );
});

/// Notification service provider (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Backup service provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    databaseService: ref.watch(databaseServiceProvider),
    preferencesService: ref.watch(preferencesServiceProvider),
  );
});

/// Date change service provider
final dateChangeServiceProvider = Provider<DateChangeService>((ref) {
  final service = DateChangeService(
    ref.watch(databaseServiceProvider),
    onDateChanged: () {
      // Invalidate providers when date changes
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(historyProvider);
    },
  );

  // Start monitoring when provider is created
  service.startMonitoring();

  // Stop monitoring when provider is disposed
  ref.onDispose(() {
    service.stopMonitoring();
  });

  return service;
});

/// State for today's prayers
class TodayPrayersState {
  final List<Prayer> prayers;
  final bool isLoading;
  final String? error;

  const TodayPrayersState({
    this.prayers = const [],
    this.isLoading = false,
    this.error,
  });

  TodayPrayersState copyWith({
    List<Prayer>? prayers,
    bool? isLoading,
    String? error,
  }) {
    return TodayPrayersState(
      prayers: prayers ?? this.prayers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get completed prayers count
  int get completedCount =>
      prayers.where((p) => p.status != PrayerStatus.missed).length;

  /// Get prayer by name
  Prayer? getPrayerByName(PrayerName name) {
    try {
      return prayers.firstWhere((p) => p.prayerName == name);
    } catch (_) {
      return null;
    }
  }

  /// Check if a specific prayer is completed
  bool isPrayerCompleted(PrayerName name) {
    final prayer = getPrayerByName(name);
    return prayer != null && prayer.status != PrayerStatus.missed;
  }
}

/// Notifier for today's prayers (Riverpod 3 syntax)
class TodayPrayersNotifier extends Notifier<TodayPrayersState> {
  DatabaseService get _databaseService => ref.read(databaseServiceProvider);
  String get _today => _formatToday();

  @override
  TodayPrayersState build() {
    // Mark missed prayers for yesterday when app starts
    _initializeAndMarkMissed();
    return const TodayPrayersState(isLoading: true);
  }

  /// Initialize and mark missed prayers
  Future<void> _initializeAndMarkMissed() async {
    try {
      // First, mark any missed prayers from yesterday
      await _databaseService.markMissedPrayers();
      // Then load today's prayers
      await _loadTodayPrayers();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  static String _formatToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Load prayers for today
  Future<void> _loadTodayPrayers() async {
    try {
      final prayers = await _databaseService.getPrayersByDate(_today);
      state = state.copyWith(prayers: prayers, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Refresh prayers
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadTodayPrayers();
  }

  /// Check-in prayer (mark as completed)
  Future<void> checkIn({
    required PrayerName prayerName,
    required PrayerStatus status,
    String? notes,
  }) async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final prayer = Prayer(
      prayerName: prayerName,
      date: _today,
      status: status,
      time: timeStr,
      notes: notes,
    );

    try {
      await _databaseService.upsertPrayer(prayer);
      await _loadTodayPrayers();
      // Invalidate dependent providers to refresh their data
      ref.invalidate(statisticsProvider);
      ref.invalidate(historyProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update prayer status
  Future<void> updatePrayer(Prayer prayer) async {
    try {
      await _databaseService.updatePrayer(prayer);
      await _loadTodayPrayers();
      // Invalidate dependent providers to refresh their data
      ref.invalidate(statisticsProvider);
      ref.invalidate(historyProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete prayer entry
  Future<void> deletePrayer(int id) async {
    try {
      await _databaseService.deletePrayer(id);
      await _loadTodayPrayers();
      // Invalidate dependent providers to refresh their data
      ref.invalidate(statisticsProvider);
      ref.invalidate(historyProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for today's prayers
final todayPrayersProvider =
    NotifierProvider<TodayPrayersNotifier, TodayPrayersState>(
      TodayPrayersNotifier.new,
    );

/// Simplified provider for completed prayers count today
final completedCountProvider = Provider<int>((ref) {
  return ref.watch(todayPrayersProvider).completedCount;
});
