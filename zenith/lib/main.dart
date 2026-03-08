import 'package:flutter/material.dart';
import 'package:zenith/features/habits/habit_db.dart';
import 'app.dart';
import 'core/utils/notification_service.dart';
import 'features/alarm/alarm_db.dart';
import 'features/calender/reminder_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ SAFE minimal init ONLY
  await AlarmDB.init();
  await ReminderDB.init();
  await HabitDB.init();
  await NotificationService.init();

  runApp(const ZenithApp());
}
