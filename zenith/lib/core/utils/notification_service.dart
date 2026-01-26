import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../navigation/navigation_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🔔 INIT
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();

      if (canScheduleExact == false) {
        await androidPlugin.requestExactAlarmsPermission();
      }

      const alarmChannel = AndroidNotificationChannel(
        'alarm_channel',
        'Alarms',
        description: 'Alarm notifications',
        importance: Importance.max,
        playSound: true,
      );

      await androidPlugin.createNotificationChannel(alarmChannel);
    }
  }

  // ------------------------------------------------------------
  // 🔔 ONE-TIME ALARM
  // ------------------------------------------------------------
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime time,
    required String title,
  }) async {
    final scheduled = tz.TZDateTime.from(time, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final diff = scheduled.difference(tz.TZDateTime.now(tz.local));
    await showAlarmConfirmation(diff);

    await _notifications.zonedSchedule(
      id,
      title,
      'Alarm ringing ⏰',
      scheduled,
      _alarmDetails(),
      payload: jsonEncode({
        'type': 'single',
        'alarmId': id.toString(),
        'title': title,
      }),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ------------------------------------------------------------
  // 🔁 REPEATING ALARM
  // ------------------------------------------------------------
  static Future<void> scheduleRepeatingAlarm({
    required String alarmId,
    required TimeOfDay time,
    required List<int> repeatDays,
    required String title,
  }) async {
    for (final weekday in repeatDays) {
      final next = _nextWeekdayDate(weekday, time);
      final notificationId = '${alarmId}_$weekday'.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        title,
        'Alarm ringing ⏰',
        next,
        _alarmDetails(),
        payload: jsonEncode({
          'type': 'repeat',
          'alarmId': alarmId,
          'weekday': weekday,
          'hour': time.hour,
          'minute': time.minute,
          'title': title,
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ------------------------------------------------------------
  // ❌ CANCEL
  // ------------------------------------------------------------
  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelRepeatingAlarm(
    String alarmId,
    List<int> repeatDays,
  ) async {
    for (final day in repeatDays) {
      await _notifications.cancel('${alarmId}_$day'.hashCode);
    }
  }

  // ------------------------------------------------------------
  // 🔁 AUTO-RESCHEDULE NEXT WEEK
  // ------------------------------------------------------------
  static Future<void> _rescheduleNextRepeat(Map<String, dynamic> data) async {
    final alarmId = data['alarmId'];
    final weekday = data['weekday'];
    final hour = data['hour'];
    final minute = data['minute'];
    final title = data['title'];

    final next = _nextWeekdayDate(
      weekday,
      TimeOfDay(hour: hour, minute: minute),
      fromNextWeek: true,
    );

    final notificationId = '${alarmId}_$weekday'.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      title,
      'Alarm ringing ⏰',
      next,
      _alarmDetails(),
      payload: jsonEncode(data),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ------------------------------------------------------------
  // 📦Show “Alarm set for X minutes” (like real apps)
  // ------------------------------------------------------------
  static Future<void> showAlarmConfirmation(Duration diff) async {
    final minutes = diff.inMinutes;
    await _notifications.show(
      999999,
      'Alarm set',
      'Alarm will ring in $minutes minutes',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 📦 NOTIFICATION TAP HANDLER
  // ------------------------------------------------------------
  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.payload == null) return;

    final data = jsonDecode(response.payload!);

    // 🔁 reschedule repeating alarm
    if (data['type'] == 'repeat') {
      await _rescheduleNextRepeat(data);
    }

    // 🔔 open fullscreen ringing UI
    NavigationService.openRingingScreen(
      alarmId: data['alarmId'],
      title: data['title'],
    );
  }

  // ------------------------------------------------------------
  // 🧠 HELPERS
  // ------------------------------------------------------------
  static NotificationDetails _alarmDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  static tz.TZDateTime _nextWeekdayDate(
    int weekday,
    TimeOfDay time, {
    bool fromNextWeek = false,
  }) {
    var now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday ||
        scheduled.isBefore(now) ||
        fromNextWeek) {
      scheduled = scheduled.add(const Duration(days: 1));
      fromNextWeek = false;
    }

    return scheduled;
  }

  // ------------------------------------------------------------
  // 🛑 STOP SOUND (for RingingScreen)
  // ------------------------------------------------------------
  static Future<void> stopAlarmSound() async {
    // Cancels all alarm sounds immediately
    await _notifications.cancelAll();
  }

  static Future<void> snoozeAlarm(String alarmId) async {
    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 5));

    await _notifications.zonedSchedule(
      alarmId.hashCode,
      'Snoozed Alarm',
      'Alarm ringing ⏰',
      snoozeTime,
      _alarmDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
