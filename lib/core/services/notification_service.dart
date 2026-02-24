import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> init() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
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
    if (!enabled) {
      await _plugin.cancel(100);
      return;
    }
    await _plugin.periodicallyShow(
      100,
      'Daily check-in',
      'Log your mood and symptoms for today.',
      RepeatInterval.daily,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
      await _plugin.show(
        101,
        'Upcoming period',
        'Expected around ${nextPeriod.month}/${nextPeriod.day}.',
        _details,
      );
    }

    if (!ovulationEnabled) {
      await _plugin.cancel(102);
    } else if (ovulation != null) {
      await _plugin.show(
        102,
        'Fertility reminder',
        'Predicted ovulation around ${ovulation.month}/${ovulation.day}.',
        _details,
      );
    }
  }
}
