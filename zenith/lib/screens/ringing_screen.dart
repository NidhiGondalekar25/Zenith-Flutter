import 'package:flutter/material.dart';
import '../core/utils/notification_service.dart';

class RingingScreen extends StatelessWidget {
  final int alarmId;
  final String title;

  const RingingScreen({
    super.key,
    required this.alarmId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, size: 120, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                ),
                onPressed: () async {
                  await NotificationService.cancelAlarm(alarmId);
                  Navigator.pop(context);
                },
                child: const Text("STOP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
