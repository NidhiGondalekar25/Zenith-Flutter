import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

class NavigationService {
  static void openRingingScreen({
    required String alarmId,
    required String title,
  }) {
    navigatorKey.currentState?.pushNamed(
      '/ring',
      arguments: {
        'id': alarmId,
        'title': title,
      },
    );
  }
}
