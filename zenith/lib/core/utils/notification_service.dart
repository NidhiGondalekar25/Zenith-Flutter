import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import '../../navigation/navigation_service.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Initialize timezone (uses device local timezone automatically)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          final parts = payload.split('|');
          final id = int.parse(parts[0]);
          final title = parts[1];

          navigatorKey.currentState?.pushNamed(
            '/ring',
            arguments: {'id': id, 'title': title},
          );
        }
      },
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();

      const AndroidNotificationChannel alarmChannel =
          AndroidNotificationChannel(
            'alarm_channel',
            'Alarms',
            description: 'Alarm notifications',
            importance: Importance.max,
            playSound: true,
          );

      await androidPlugin.createNotificationChannel(alarmChannel);
    }
  }

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime time,
    required String title,
  }) async {
    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      id,
      title,
      'Alarm ringing ⏰',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          channelDescription: 'Alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          fullScreenIntent: true, // 🔥 REQUIRED
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$id|$title',
    );
  }

  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
  }

  static DateTime _nextDateForWeekday(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
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

  static Future<void> scheduleRepeatingAlarm({
    required String alarmId,
    required TimeOfDay time,
    required List<int> repeatDays,
    required String title,
  }) async {
    for (final day in repeatDays) {
      final next = _nextWeekdayDate(day, time);

      final notificationId = '${alarmId}_$day'.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        title,
        'Alarm ringing ⏰',
        next,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarms',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
        payload: jsonEncode({
          'type': 'repeat',
          'alarmId': alarmId,
          'weekday': day,
          'hour': time.hour,
          'minute': time.minute,
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelRepeatingAlarm(
    String alarmId,
    List<int> repeatDays,
  ) async {
    for (final day in repeatDays) {
      await cancelAlarm(alarmId.hashCode + day);
    }
  }

  static Future<void> _rescheduleNextRepeat(Map<String, dynamic> data) async {
    final alarmId = data['alarmId'];
    final weekday = data['weekday'];
    final hour = data['hour'];
    final minute = data['minute'];

    final nextTime = _nextWeekdayDate(
      weekday,
      TimeOfDay(hour: hour, minute: minute),
      fromNextWeek: true,
    );

    final notificationId = '${alarmId}_$weekday'.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      'Alarm',
      'Alarm ringing ⏰',
      nextTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      payload: jsonEncode(data),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.payload == null) return;

    final data = jsonDecode(response.payload!);

    if (data['type'] == 'repeat') {
      await _rescheduleNextRepeat(data);
    }
  }
}
