import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';

/// Service for handling push notifications and scheduling alarms
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

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
      }
    }
  }

  /// Callback triggered by AlarmManager
  @pragma('vm:entry-point')
  static void _alarmCallback(int id, Map<String, dynamic> params) async {
    final title = params['title'] as String;
    final body = params['body'] as String;

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
}
