import 'package:flutter/material.dart';
import 'navigation/app_router.dart';
import 'navigation/navigation_service.dart';

class ZenithApp extends StatelessWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // required for notifications
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/', // start at HomeScreen
    );
  }
}
