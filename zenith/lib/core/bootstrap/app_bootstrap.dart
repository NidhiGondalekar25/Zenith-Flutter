import 'package:flutter/material.dart';
import '../../features/alarm/alarm_db.dart';
import '../../features/alarm/alarm_model.dart';
import '../utils/notification_service.dart';
import '../utils/battery_optimization.dart';

class AppBootstrap {
  static Future<void> run() async {
    // 🔋 ask battery optimization AFTER UI exists
    await BatteryOptimization.requestDisable();

    final alarms = await AlarmDB.getAlarms();

    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;

      if (alarm.repeatDays.isEmpty) {
        await NotificationService.scheduleAlarm(
          id: alarm.id.hashCode,
          time: alarm.time,
          title: alarm.label,
        );
      } else {
        await NotificationService.scheduleRepeatingAlarm(
          alarmId: alarm.id,
          time: TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute),
          repeatDays: alarm.repeatDays,
          title: alarm.label,
        );
      }
    }
  }
}
