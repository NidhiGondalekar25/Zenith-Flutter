import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import '../features/home/home_screen.dart';
import '../features/alarm/add_edit_alarm_screen.dart';
import '../features/alarm/alarm_screen.dart';
import '../screens/ringing_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/add_edit_alarm':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddEditAlarmScreen(
            existingId: args?['id'],
            existingTime: args?['time'],
            existingLabel: args?['label'],
            existingRepeatDays: args?['repeatDays'] ?? [],
          ),
        );

      case '/alarm_screen':
        return MaterialPageRoute(builder: (_) => const AlarmScreen());

      case '/ring':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RingingScreen(
            alarmId: args['id'],
            title: args['title'],
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const AuthGate());
    }
  }
}