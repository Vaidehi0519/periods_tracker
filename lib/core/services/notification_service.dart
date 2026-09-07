import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
    if (kIsWeb) {
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'periods_tracker_channel',
      'Periods Tracker',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> scheduleDailyLogReminder(bool enabled) async {
    await _plugin.cancel(100);
    if (!enabled) {
      return;
    }
    await _plugin.zonedSchedule(
      100,
      'Daily check-in',
      'Log your mood and symptoms for today.',
      _nextDailyReminderAt(hour: 20),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> updateCyclePredictionReminders({
    required bool periodEnabled,
    required bool ovulationEnabled,
    required DateTime? nextPeriod,
    required DateTime? ovulation,
  }) async {
    if (!periodEnabled) {
      await _plugin.cancel(101);
    } else if (nextPeriod != null) {
      await _scheduleOneDayBefore(
        101,
        'Upcoming period',
        'Expected around ${nextPeriod.month}/${nextPeriod.day}.',
        nextPeriod,
      );
    }

    if (!ovulationEnabled) {
      await _plugin.cancel(102);
    } else if (ovulation != null) {
      await _scheduleOneDayBefore(
        102,
        'Fertility reminder',
        'Predicted ovulation around ${ovulation.month}/${ovulation.day}.',
        ovulation,
      );
    }
  }

  Future<void> _scheduleOneDayBefore(
    int id,
    String title,
    String body,
    DateTime date,
  ) async {
    await _plugin.cancel(id);
    final reminderDate = date.subtract(const Duration(days: 1));
    final scheduled = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
    );
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  tz.TZDateTime _nextDailyReminderAt({required int hour}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
