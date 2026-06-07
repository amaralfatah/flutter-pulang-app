import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'prayer_provider.dart';

/// State for prayer times
class PrayerTimesState {
  final PrayerTime? prayerTime;
  final bool isLoading;
  final String? error;
  final String? nextPrayerName;
  final String? nextPrayerTime;
  final Duration? remainingTime;

  const PrayerTimesState({
    this.prayerTime,
    this.isLoading = false,
    this.error,
    this.nextPrayerName,
    this.nextPrayerTime,
    this.remainingTime,
  });

  PrayerTimesState copyWith({
    PrayerTime? prayerTime,
    bool? isLoading,
    String? error,
    String? nextPrayerName,
    String? nextPrayerTime,
    Duration? remainingTime,
  }) {
    return PrayerTimesState(
      prayerTime: prayerTime ?? this.prayerTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }

  /// Check if prayer times are available
  bool get hasData => prayerTime != null;
}

/// Notifier for prayer times and next prayer countdown (Riverpod 3 syntax)
class PrayerTimesNotifier extends Notifier<PrayerTimesState> {
  PrayerApiService get _prayerApiService => ref.read(prayerApiServiceProvider);
  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);
  PreferencesService get _preferencesService =>
      ref.read(preferencesServiceProvider);
  Timer? _countdownTimer;
  Timer? _dayChangeTimer;

  @override
  PrayerTimesState build() {
    _loadTodayPrayerTimes();
    _startCountdownTimer();
    _scheduleDayChange();

    // Cleanup when disposed
    ref.onDispose(() {
      _countdownTimer?.cancel();
      _dayChangeTimer?.cancel();
    });

    return const PrayerTimesState(isLoading: true);
  }

  /// Load prayer times for today
  Future<void> _loadTodayPrayerTimes() async {
    try {
      final prayerTime = await _prayerApiService.getTodayPrayerTimes();
      state = state.copyWith(prayerTime: prayerTime, isLoading: false);
      _updateNextPrayer();

      // Schedule notifications only if the user has them enabled; otherwise
      // make sure any previously-scheduled alarms are cleared. Reading the
      // preference directly (not via settingsProvider) avoids a provider cycle.
      if (prayerTime != null) {
        final notificationsEnabled = await _preferencesService
            .isNotificationEnabled();
        if (notificationsEnabled) {
          await _notificationService.schedulePrayerNotifications(prayerTime);
        } else {
          await _notificationService.cancelAllNotifications();
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Refresh prayer times
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadTodayPrayerTimes();
  }

  /// Update next prayer info
  void _updateNextPrayer() {
    if (state.prayerTime == null) return;

    final now = DateTime.now();
    final pt = state.prayerTime!;

    final prayers = [
      ('Subuh', pt.subuh),
      ('Dzuhur', pt.dzuhur),
      ('Ashar', pt.ashar),
      ('Maghrib', pt.maghrib),
      ('Isya', pt.isya),
    ];

    for (final (name, timeStr) in prayers) {
      final time = _parseTime(timeStr);
      if (time != null && time.isAfter(now)) {
        state = state.copyWith(
          nextPrayerName: name,
          nextPrayerTime: timeStr,
          remainingTime: time.difference(now),
        );
        return;
      }
    }

    // All prayers passed for today
    state = state.copyWith(
      nextPrayerName: 'Subuh (besok)',
      nextPrayerTime: pt.subuh,
      remainingTime: null,
    );
  }

  /// Parse time string to DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Start countdown timer (updates every minute)
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateNextPrayer();
    });
  }

  /// Schedule refresh at midnight for new day
  void _scheduleDayChange() {
    _dayChangeTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _dayChangeTimer = Timer(durationUntilMidnight, () {
      _loadTodayPrayerTimes();
      _scheduleDayChange(); // Reschedule for next day
    });
  }
}

/// Provider for prayer times
final prayerTimesProvider =
    NotifierProvider<PrayerTimesNotifier, PrayerTimesState>(
      PrayerTimesNotifier.new,
    );

/// Provider for next prayer info as formatted string
final nextPrayerInfoProvider = Provider<String>((ref) {
  final state = ref.watch(prayerTimesProvider);

  if (state.nextPrayerName == null) return 'Loading...';

  if (state.remainingTime == null) {
    return '${state.nextPrayerName} - ${state.nextPrayerTime}';
  }

  final hours = state.remainingTime!.inHours;
  final minutes = state.remainingTime!.inMinutes % 60;

  if (hours > 0) {
    return '${state.nextPrayerName} - ${state.nextPrayerTime} ($hours jam $minutes menit lagi)';
  } else {
    return '${state.nextPrayerName} - ${state.nextPrayerTime} ($minutes menit lagi)';
  }
});
