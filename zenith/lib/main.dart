import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/utils/notification_service.dart';
import 'features/alarm/alarm_db.dart';
import 'features/calender/reminder_db.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (auth + Firestore)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Local DBs (alarms and reminders stay local for now)
  await AlarmDB.init();
  await ReminderDB.init();
  await NotificationService.init();

  runApp(const ZenithApp());
}
