import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/notification_service.dart';

class RingingScreen extends StatefulWidget {
  final String alarmId;
  final String title;

  const RingingScreen({
    super.key,
    required this.alarmId,
    required this.title,
  });

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen> {
  @override
  void initState() {
    super.initState();

    // 🔒 Keep screen on + fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _dismiss() async {
    await NotificationService.stopAlarmSound();
    Navigator.pop(context);
  }

  void _snooze() async {
    await NotificationService.snoozeAlarm(widget.alarmId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.now().format(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),

            Text(
              time,
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              widget.title,
              style: const TextStyle(fontSize: 22, color: Colors.white70),
            ),

            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _snooze,
                  child: const Text('Snooze'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _dismiss,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
