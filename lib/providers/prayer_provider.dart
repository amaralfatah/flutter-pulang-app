import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'calendar_provider.dart';
import 'ledger_provider.dart';

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
    onDateChanged: () {
      // Invalidate providers when date changes
      ref.invalidate(todayPrayersProvider);
      ref.invalidate(ledgerProvider);
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

  /// Get completed prayers count — hutang yang sudah diqadha ikut terhitung.
  int get completedCount => prayers.where((p) => p.isFulfilled).length;

  /// Get prayer by name
  Prayer? getPrayerByName(PrayerName name) {
    try {
      return prayers.firstWhere((p) => p.prayerName == name);
    } catch (_) {
      return null;
    }
  }

}

/// Notifier for today's prayers (Riverpod 3 syntax)
class TodayPrayersNotifier extends Notifier<TodayPrayersState> {
  DatabaseService get _databaseService => ref.read(databaseServiceProvider);
  String get _today => _formatToday();

  @override
  TodayPrayersState build() {
    _loadTodayPrayers();
    return const TodayPrayersState(isLoading: true);
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

  /// Setiap perubahan catatan hari ini juga mengubah apa yang dibaca layar
  /// Riwayat dan Qadha. Buku besar cukup di-invalidate (dia selalu memuat
  /// ulang dari nol), sedangkan kalender disegarkan lewat notifier-nya supaya
  /// bulan yang sedang dibuka user tidak ikut kembali ke hari ini.
  void _refreshDependents() {
    ref.invalidate(ledgerProvider);
    ref.read(calendarProvider.notifier).refresh();
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
      _refreshDependents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update prayer status
  Future<void> updatePrayer(Prayer prayer) async {
    try {
      await _databaseService.updatePrayer(prayer);
      await _loadTodayPrayers();
      _refreshDependents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete prayer entry
  Future<void> deletePrayer(int id) async {
    try {
      await _databaseService.deletePrayer(id);
      await _loadTodayPrayers();
      _refreshDependents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Re-creates a previously deleted prayer record — the undo path for
  /// [deletePrayer]. Inserts fresh (a new id) rather than reusing the old
  /// one, since the row it belonged to is already gone.
  Future<void> restorePrayer(Prayer prayer) async {
    try {
      await _databaseService.upsertPrayer(
        Prayer(
          prayerName: prayer.prayerName,
          date: prayer.date,
          status: prayer.status,
          time: prayer.time,
          notes: prayer.notes,
        ),
      );
      await _loadTodayPrayers();
      _refreshDependents();
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
