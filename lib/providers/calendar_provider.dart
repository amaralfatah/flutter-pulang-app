import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import 'providers.dart';

/// Prayer status for a single day (all 5 prayers)
class DayPrayerStatus {
  final PrayerStatus? subuh;
  final PrayerStatus? dzuhur;
  final PrayerStatus? ashar;
  final PrayerStatus? maghrib;
  final PrayerStatus? isya;

  const DayPrayerStatus({
    this.subuh,
    this.dzuhur,
    this.ashar,
    this.maghrib,
    this.isya,
  });

  /// Create from list of prayers
  factory DayPrayerStatus.fromPrayers(List<Prayer> prayers) {
    PrayerStatus? getStatus(PrayerName name) {
      final prayer = prayers.where((p) => p.prayerName == name).firstOrNull;
      return prayer?.status;
    }

    return DayPrayerStatus(
      subuh: getStatus(PrayerName.subuh),
      dzuhur: getStatus(PrayerName.dzuhur),
      ashar: getStatus(PrayerName.ashar),
      maghrib: getStatus(PrayerName.maghrib),
      isya: getStatus(PrayerName.isya),
    );
  }

  /// Get status list for segments [Subuh, Dzuhur, Ashar, Maghrib, Isya]
  List<PrayerStatus?> get statusList => [subuh, dzuhur, ashar, maghrib, isya];

  /// Count completed prayers
  int get completedCount => statusList
      .where((s) => s == PrayerStatus.onTime || s == PrayerStatus.late)
      .length;
}

/// State for Calendar Screen
class CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<String, DayPrayerStatus>
  monthPrayerStatus; // date -> status for all prayers
  final List<Prayer> selectedDayPrayers;
  final bool isLoading;
  final String? error;

  const CalendarState({
    required this.focusedDay,
    this.selectedDay,
    this.monthPrayerStatus = const {},
    this.selectedDayPrayers = const [],
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<String, DayPrayerStatus>? monthPrayerStatus,
    List<Prayer>? selectedDayPrayers,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      monthPrayerStatus: monthPrayerStatus ?? this.monthPrayerStatus,
      selectedDayPrayers: selectedDayPrayers ?? this.selectedDayPrayers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get prayer status for a specific date
  DayPrayerStatus? getPrayerStatus(DateTime date) {
    final dateStr = _formatDate(date);
    return monthPrayerStatus[dateStr];
  }

  /// Get completed count for a specific date (for backward compat)
  int getCompletedCount(DateTime date) {
    return getPrayerStatus(date)?.completedCount ?? 0;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Calendar Provider
final calendarProvider = NotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);

class CalendarNotifier extends Notifier<CalendarState> {
  DatabaseService get _databaseService => ref.read(databaseServiceProvider);

  @override
  CalendarState build() {
    final now = DateTime.now();
    // Auto-select today on initialization
    _initializeWithToday(now);
    return CalendarState(focusedDay: now, selectedDay: now, isLoading: true);
  }

  /// Initialize calendar with today's data
  Future<void> _initializeWithToday(DateTime today) async {
    await _loadMonthPrayerStatus(today.year, today.month);
    await _loadSelectedDayPrayers(today);
  }

  /// Load prayers for a selected day (internal helper)
  Future<void> _loadSelectedDayPrayers(DateTime selectedDay) async {
    try {
      final dateStr = CalendarState._formatDate(selectedDay);
      final prayers = await _databaseService.getPrayersByDate(dateStr);
      state = state.copyWith(selectedDayPrayers: prayers, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load prayer status for all days in a month
  Future<void> _loadMonthPrayerStatus(int year, int month) async {
    try {
      final prayers = await _databaseService.getMonthPrayers(year, month);

      // Group prayers by date
      final Map<String, List<Prayer>> prayersByDate = {};
      for (final prayer in prayers) {
        prayersByDate.putIfAbsent(prayer.date, () => []).add(prayer);
      }

      // Convert to DayPrayerStatus
      final Map<String, DayPrayerStatus> monthStatus = {};
      for (final entry in prayersByDate.entries) {
        monthStatus[entry.key] = DayPrayerStatus.fromPrayers(entry.value);
      }

      state = state.copyWith(monthPrayerStatus: monthStatus, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Change focused month (when user swipes calendar)
  Future<void> onPageChanged(DateTime focusedDay) async {
    state = state.copyWith(focusedDay: focusedDay, isLoading: true);
    await _loadMonthPrayerStatus(focusedDay.year, focusedDay.month);
  }

  /// Select a day
  Future<void> selectDay(DateTime selectedDay) async {
    state = state.copyWith(selectedDay: selectedDay, isLoading: true);
    await _loadSelectedDayPrayers(selectedDay);
  }

  /// Refresh current month
  Future<void> refresh() async {
    final focused = state.focusedDay;
    state = state.copyWith(isLoading: true);
    await _loadMonthPrayerStatus(focused.year, focused.month);

    // Also refresh selected day if any
    if (state.selectedDay != null) {
      await selectDay(state.selectedDay!);
    }
  }

  /// Check-in prayer for a specific date (retroactive)
  Future<void> checkInForDate({
    required DateTime date,
    required PrayerName prayerName,
    required PrayerStatus status,
  }) async {
    try {
      final dateStr = CalendarState._formatDate(date);
      final prayer = Prayer(
        prayerName: prayerName,
        date: dateStr,
        status: status,
      );
      await _databaseService.upsertPrayer(prayer);

      // Refresh data
      await _loadMonthPrayerStatus(date.year, date.month);
      await selectDay(date);

      // Invalidate related providers
      ref.invalidate(statisticsProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete prayer for a specific date
  Future<void> deletePrayerForDate(int prayerId, DateTime date) async {
    try {
      await _databaseService.deletePrayer(prayerId);

      // Refresh data
      await _loadMonthPrayerStatus(date.year, date.month);
      await selectDay(date);

      // Invalidate related providers
      ref.invalidate(statisticsProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
