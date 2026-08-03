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

  /// Jadwal besok, dipakai hanya saat semua solat hari ini sudah lewat.
  /// Disimpan di luar state karena bukan bagian dari jadwal yang ditampilkan —
  /// perannya sebatas sumber waktu Subuh besok yang sahih.
  PrayerTime? _tomorrowPrayerTime;

  /// Tanggal yang diwakili [_tomorrowPrayerTime]. Tanpa ini, jadwal yang
  /// diambil semalam masih akan dianggap "besok" setelah lewat tengah malam.
  DateTime? _tomorrowDate;

  /// Penjaga agar _updateNextPrayer dan _loadTomorrowPrayerTimes tidak saling
  /// memanggil berulang saat jadwal besok belum tersedia.
  bool _loadingTomorrow = false;

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

  /// Ambil jadwal besok, dipakai untuk menghitung mundur ke Subuh besok.
  ///
  /// Hampir selalu dilayani dari cache lokal karena [prefetchPrayerTimes]
  /// sudah menyimpan beberapa hari ke depan, jadi ini biasanya tidak menyentuh
  /// jaringan sama sekali.
  Future<void> _loadTomorrowPrayerTimes() async {
    if (_loadingTomorrow) return;
    _loadingTomorrow = true;
    try {
      final cityId = await _preferencesService.getCityId();
      if (cityId == null) return;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final prayerTime = await _prayerApiService.getPrayerTimes(
        cityId: cityId,
        date: tomorrow,
      );
      if (prayerTime == null) return;

      _tomorrowPrayerTime = prayerTime;
      _tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _updateNextPrayer();
    } catch (_) {
      // Dibiarkan kosong: kartu akan menampilkan "waktu tidak diketahui",
      // yang lebih jujur daripada menampilkan angka hasil tebakan.
    } finally {
      _loadingTomorrow = false;
    }
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

    // Semua solat hari ini sudah lewat, jadi yang berikutnya adalah Subuh
    // besok. Waktunya TIDAK boleh diambil dari Subuh hari ini: jadwal solat
    // bergeser setiap hari, sehingga angka itu hanya tebakan yang tampil di
    // layar seolah pasti. Pakai jadwal besok yang sebenarnya — biasanya sudah
    // ada di cache lokal berkat prefetch — dan bila memang belum tersedia,
    // tampilkan tanpa jam dan tanpa hitungan mundur.
    final tomorrow = now.add(const Duration(days: 1));
    final hasFreshTomorrow =
        _tomorrowDate != null &&
        _tomorrowDate!.year == tomorrow.year &&
        _tomorrowDate!.month == tomorrow.month &&
        _tomorrowDate!.day == tomorrow.day;
    final subuhBesok = hasFreshTomorrow ? _tomorrowPrayerTime?.subuh : null;

    if (subuhBesok == null) {
      unawaited(_loadTomorrowPrayerTimes());
    }

    final subuhBesokTime = subuhBesok == null
        ? null
        : _parseTime(subuhBesok, onDate: tomorrow);

    // Dibangun langsung, bukan lewat copyWith: copyWith memakai `??` sehingga
    // nilai null justru mempertahankan angka lama — persis yang harus dihindari
    // di sini, karena tujuannya adalah tidak menampilkan angka apa pun.
    state = PrayerTimesState(
      prayerTime: state.prayerTime,
      isLoading: state.isLoading,
      error: state.error,
      nextPrayerName: 'Subuh (besok)',
      nextPrayerTime: subuhBesok,
      remainingTime: subuhBesokTime?.difference(now),
    );
  }

  /// Parse time string to DateTime
  ///
  /// [onDate] menentukan tanggal yang dipasangkan ke jam tersebut; bila tidak
  /// diisi, dipakai hari ini.
  DateTime? _parseTime(String timeStr, {DateTime? onDate}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final now = onDate ?? DateTime.now();
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
