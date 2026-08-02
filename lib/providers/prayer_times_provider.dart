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
    // Without this flag, a failed reload could never clear a previously
    // loaded schedule — `prayerTime ?? this.prayerTime` always keeps the old
    // one once it's set, so a city change followed by an error would silently
    // keep showing the old city's (wrong) times.
    bool clearPrayerTime = false,
    bool? isLoading,
    String? error,
    String? nextPrayerName,
    String? nextPrayerTime,
    Duration? remainingTime,
  }) {
    return PrayerTimesState(
      prayerTime: clearPrayerTime ? null : (prayerTime ?? this.prayerTime),
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

        // Best-effort: cache the next few days so the schedule still reads
        // if the app is opened later without a connection.
        final cityId = await _preferencesService.getCityId();
        if (cityId != null) {
          unawaited(_prayerApiService.prefetchPrayerTimes(cityId: cityId));
        }
      }
    } catch (e) {
      // A thrown error (e.g. offline) must not leave a stale schedule on
      // screen — clear it so the UI shows the actual error state instead of
      // silently keeping whatever was loaded before.
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        clearPrayerTime: true,
      );
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

    // All prayers passed for today — count down to tomorrow's Subuh instead of
    // dropping the countdown, which used to leave the card showing a stale
    // duration next to a "besok" label.
    final tomorrowSubuh = _parseTime(pt.subuh)?.add(const Duration(days: 1));
    state = state.copyWith(
      nextPrayerName: 'Subuh (besok)',
      nextPrayerTime: pt.subuh,
      remainingTime: tomorrowSubuh?.difference(now),
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
