import 'package:flutter/material.dart';
import 'alarm_model.dart';
import 'add_edit_alarm_screen.dart';
import 'alarm_db.dart';
import '../../core/utils/notification_service.dart';
import 'package:zenith/core/utils/time_utils.dart';

class AlarmScreen extends StatefulWidget {
  final String? alarmId;
  final TimeOfDay? time;
  final List<int>? repeatDays;
  final String? title;

  const AlarmScreen({
    super.key,
    this.alarmId,
    this.time,
    this.repeatDays,
    this.title,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final List<Alarm> alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final storedAlarms = await AlarmDB.getAlarms();
    debugPrint('📦 Loaded alarms count: ${storedAlarms.length}');
    setState(() {
      alarms
        ..clear()
        ..addAll(storedAlarms);
    });
  }

  String _formatRepeatDays(List<int> days) {
    if (days.isEmpty) return 'Once';

    const map = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return days.map((d) => map[d]).join(', ');
  }

  // ➕ ADD OR ✏️ EDIT ALARM
  Future<void> _openAddEditAlarm({Alarm? alarm}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAlarmScreen(
          existingId: alarm?.id,
          existingTime: alarm == null
              ? null
              : TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute),
          existingLabel: alarm?.label,
          existingRepeatDays: alarm == null
              ? []
              : List<int>.from(alarm.repeatDays),
        ),
      ),
    );

    // 🗑️ DELETE FROM EDIT SCREEN
    if (result == null) return;

    if (result['delete'] == true) {
      final index = alarms.indexWhere((a) => a.id == result['id']);
      if (index != -1) {
        await _deleteAlarm(index);
      }
      return;
    }

    if (result == null) return;

    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      result['time'].hour,
      result['time'].minute,
    );

    final isEdit = result['id'] != null;

    if (isEdit) {
      // ✏️ EDIT
      final index = alarms.indexWhere((a) => a.id == result['id']);
      if (index == -1) return;

      final updatedAlarm = alarms[index].copyWith(
        time: alarmTime,
        label: result['label'],
        repeatDays: List<int>.from(result['repeatDays']),
      );

      // ❌ Cancel old alarm
      await NotificationService.cancelAlarm(updatedAlarm.id.hashCode);

      // ✅ Update UI
      setState(() {
        alarms[index] = updatedAlarm;
      });

      // 💾 Update DB
      await AlarmDB.updateAlarm(updatedAlarm);

      // 🔔 Reschedule if enabled
      if (updatedAlarm.isEnabled) {
        await NotificationService.scheduleAlarm(
          id: updatedAlarm.id.hashCode,
          time: updatedAlarm.time,
          title: updatedAlarm.label,
        );
      }
    } else {
      // ➕ ADD
      final newAlarm = Alarm(
        id: DateTime.now().toString(),
        time: alarmTime,
        label: result['label'],
        ringtone: 'default',
        screen: 'default',
        isEnabled: true,
        repeatDays: List<int>.from(result['repeatDays']),
      );

      setState(() {
        alarms.add(newAlarm);
      });

      await AlarmDB.insertAlarm(newAlarm);

      await NotificationService.scheduleAlarm(
        id: newAlarm.id.hashCode,
        time: newAlarm.time,
        title: newAlarm.label,
      );
    }
  }

  // Delete ALARM
  Future<void> _deleteAlarm(int index) async {
    final alarm = alarms[index];

    // ❌ Cancel notification
    if (alarm.repeatDays.isEmpty) {
      await NotificationService.cancelAlarm(alarm.id.hashCode);
    } else {
      await NotificationService.cancelRepeatingAlarm(
        alarm.id,
        alarm.repeatDays,
      );
    }

    // 💾 Delete from DB
    await AlarmDB.deleteAlarm(alarm.id);

    // 🧹 Update UI
    setState(() {
      alarms.removeAt(index);
    });
  }

  /// 🔘 TOGGLE ALARM
  Future<void> _toggleAlarm(int index, bool value) async {
    final alarm = alarms[index];
    final updated = alarm.copyWith(isEnabled: value);

    setState(() {
      alarms[index] = updated;
    });

    await AlarmDB.updateAlarm(updated);

    if (value) {
      await NotificationService.scheduleAlarm(
        id: updated.id.hashCode,
        time: updated.time,
        title: updated.label,
      );
    } else {
      await NotificationService.cancelAlarm(updated.id.hashCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: alarms.isEmpty
          ? const Center(
              child: Text('No alarms yet ⏰', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];

                return Dismissible(
                  key: ValueKey(alarm.id),
                  direction: DismissDirection.endToStart,

                  // 🔔 CONFIRM DELETE
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Alarm'),
                        content: const Text(
                          'Are you sure you want to delete this alarm?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },

                  // 🗑️ DELETE
                  onDismissed: (_) => _deleteAlarm(index),

                  // 🔴 RED DELETE BACKGROUND
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),

                  child: ListTile(
                    title: Text(
                      format24Hour(alarm.time),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${alarm.label} • ${_formatRepeatDays(alarm.repeatDays)}',
                    ),
                    // 🕒 24H format
                    trailing: Switch(
                      value: alarm.isEnabled,
                      onChanged: (value) => _toggleAlarm(index, value),
                    ),
                    onTap: () => _openAddEditAlarm(alarm: alarm), // ✏️ EDIT
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditAlarm(), // ➕ ADD
        child: const Icon(Icons.add),
      ),
    );
  }
}
