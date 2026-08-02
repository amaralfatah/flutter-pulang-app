import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';
import 'preferences_service.dart';
import 'prayer_api_service.dart';

/// Service for handling push notifications and scheduling alarms
///
/// Annotated with `vm:entry-point` because [_alarmCallback] runs in a
/// background isolate spawned by native code (AndroidAlarmManager). Without
/// these annotations the AOT compiler tree-shakes the class/constructors and
/// the alarm callback crashes with "must be annotated" — so the scheduled
/// notification never actually shows.
@pragma('vm:entry-point')
class NotificationService {
  @pragma('vm:entry-point')
  static final NotificationService _instance = NotificationService._internal();

  @pragma('vm:entry-point')
  factory NotificationService() => _instance;

  @pragma('vm:entry-point')
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notifications and alarm manager
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Setup Android Alarm Manager
    await AndroidAlarmManager.initialize();

    // 2. Setup Local Notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
      },
    );

    // Create Notification Channel for Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_channel',
        'Jadwal Solat',
        description: 'Notifikasi saat masuk waktu solat',
        importance: Importance.max,
        playSound: true,
      ),
    );

    _isInitialized = true;
  }

  /// Whether the OS actually permits notifications right now. Used to detect
  /// when the user has "Aktifkan Notifikasi" on in-app but denied the OS
  /// permission — a state where the toggle lies about whether alarms will
  /// ever be seen.
  Future<bool> areNotificationsPermitted() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.areNotificationsEnabled() ?? true;
    }
    // Other platforms: assume permitted rather than block on an unverified
    // check — requestPermissions() still runs its own OS-level prompt.
    return true;
  }

  /// Request permissions
  Future<bool> requestPermissions() async {
    bool? granted = false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      granted = await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    return granted ?? false;
  }

  /// Show immediate notification (for testing)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Jadwal Solat',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      // ignore
    }
  }

  /// Schedule notifications for a specific prayer day
  Future<void> schedulePrayerNotifications(PrayerTime prayerTime) async {
    // 1. Cancel all existing alarms/notifications first to avoid duplicates
    await cancelAllNotifications();

    // 2. Parse date
    final date = DateTime.parse(prayerTime.date); // YYYY-MM-DD
    final now = DateTime.now();

    // If prayer time date is in the past (different day), ignore.
    if (date.year != now.year ||
        date.month != now.month ||
        date.day != now.day) {
      debugPrint(
        '[Notif] Skip schedule: prayer date ${prayerTime.date} != today '
        '${now.toIso8601String().split('T').first}',
      );
      return;
    }

    // 3. Define prayers
    final prayers = [
      ('Subuh', prayerTime.subuh, 1),
      ('Dzuhur', prayerTime.dzuhur, 2),
      ('Ashar', prayerTime.ashar, 3),
      ('Maghrib', prayerTime.maghrib, 4),
      ('Isya', prayerTime.isya, 5),
    ];

    var scheduledCount = 0;
    for (final (name, timeStr, id) in prayers) {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduledTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      // Only schedule if time is in the future
      if (scheduledTime.isAfter(now)) {
        // Schedule using Android Alarm Manager for exact timing
        await AndroidAlarmManager.oneShotAt(
          scheduledTime,
          id,
          _alarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {'title': 'Waktu $name', 'body': 'Sudah masuk waktu $name'},
        );
        scheduledCount++;
        debugPrint('[Notif] Scheduled $name at $timeStr (id=$id)');
      } else {
        debugPrint('[Notif] Skip $name at $timeStr (already passed)');
      }
    }
    debugPrint('[Notif] Done: $scheduledCount alarm(s) scheduled for today.');
  }

  /// Schedule a one-off test notification [delay] from now, using the exact
  /// same AlarmManager path as real prayer alarms. Use this to verify
  /// end-to-end delivery without waiting for an actual prayer time.
  ///
  /// Returns the time the notification is expected to fire.
  Future<DateTime> scheduleTestNotification({
    Duration delay = const Duration(minutes: 1),
  }) async {
    final fireAt = DateTime.now().add(delay);
    await AndroidAlarmManager.oneShotAt(
      fireAt,
      99, // dedicated test id, outside the 1-5 prayer range
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: false,
      params: {
        'title': 'Test Notifikasi Terjadwal',
        'body': 'Jika kamu melihat ini, alarm terjadwal berfungsi.',
      },
    );
    debugPrint('[Notif] Test alarm scheduled at ${fireAt.toIso8601String()}');
    return fireAt;
  }

  /// Callback triggered by AlarmManager
  @pragma('vm:entry-point')
  static void _alarmCallback(int id, Map<String, dynamic> params) async {
    final title = params['title'] as String;
    final body = params['body'] as String;
    debugPrint('[Notif] Alarm fired (id=$id) -> showing "$title"');

    // Show notification immediately
    final service = NotificationService();
    // Re-init mainly for the plugin connection (although usually not needed for background isolate if just showing)
    // But local_notifications needs to be initialized.
    await service.init();
    await service.showNotification(id: id, title: title, body: body);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    // IDs 1-5 reserved for daily prayers
    for (int i = 1; i <= 5; i++) {
      await AndroidAlarmManager.cancel(i);
    }
  }

  /// Alarm id for the daily midnight rescheduler.
  static const int rescheduleAlarmId = 80;

  /// Schedule a daily alarm shortly after midnight that re-schedules today's
  /// prayer notifications from the background, independent of the app being
  /// opened.
  ///
  /// Without this, [schedulePrayerNotifications] only ever runs when
  /// [prayerTimesProvider] loads (i.e. the app is opened) — so a day the user
  /// never opens the app has zero alarms scheduled and no prayer
  /// notifications fire at all. AndroidAlarmManager.periodic survives across
  /// app restarts/kills (unlike the in-memory midnight Timer in
  /// PrayerTimesNotifier), which is what makes this work unattended.
  static Future<void> scheduleDailyReschedule() async {
    if (!Platform.isAndroid) return;
    try {
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        rescheduleAlarmId,
        _rescheduleCallback,
        startAt: _nextMidnightPlus(const Duration(minutes: 5)),
        exact: false,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } catch (e) {
      debugPrint('[Notif] Reschedule alarm setup error: $e');
    }
  }

  static DateTime _nextMidnightPlus(Duration offset) {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.add(offset);
  }

  /// Entry point invoked by AlarmManager in a background isolate. Must build
  /// its own service instances — nothing from the UI isolate is available.
  @pragma('vm:entry-point')
  static Future<void> _rescheduleCallback(
    int id,
    Map<String, dynamic> params,
  ) async {
    try {
      final preferencesService = PreferencesService();
      if (!await preferencesService.isNotificationEnabled()) return;

      final prayerApiService = PrayerApiService(
        preferencesService: preferencesService,
      );
      final prayerTime = await prayerApiService.getTodayPrayerTimes();
      if (prayerTime == null) return; // offline/no city: app will catch up

      await NotificationService().schedulePrayerNotifications(prayerTime);
    } catch (e) {
      // A background reschedule must never crash the isolate; the app will
      // still catch up next time it's opened.
      debugPrint('[Notif] Background reschedule error: $e');
    }
  }
}
