import 'package:flutter/material.dart';
import 'alarm_model.dart';
import 'add_edit_alarm_screen.dart';
import 'alarm_db.dart';
import '../../core/utils/notification_service.dart';
import 'package:zenith/core/utils/time_utils.dart';
import '../habits/habit_db.dart';
import '../habits/habit_model.dart';
import '../habits/routine_model.dart';

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
  State<AlarmScreen> createState() => AlarmScreenState();
}

class AlarmScreenState extends State<AlarmScreen> {
  Future<void> refresh() async {
    await _loadAlarms();
    await _loadHabitReminders();
  }

  final List<Alarm> alarms = [];
  // habitId -> (habit, routine) for all habits with reminders
  List<(Habit, Routine)> _habitReminders = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _loadHabitReminders();
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

  Future<void> _loadHabitReminders() async {
    final routines = await HabitDB.getAllRoutines();
    final List<(Habit, Routine)> result = [];

    for (final routine in routines) {
      final habits = await HabitDB.getHabitsForRoutine(routine.id);
      for (final habit in habits) {
        if (habit.hasReminder && habit.reminderTime != null) {
          result.add((habit, routine));
        }
      }
    }

    setState(() {
      _habitReminders = result;
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

  Widget _sectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasManual = alarms.isNotEmpty;
    final hasHabit = _habitReminders.isNotEmpty;
    final isEmpty = !hasManual && !hasHabit;

    return Scaffold(
      body: isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⏰', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text(
                    'No alarms yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to add one',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // ── MANUAL ALARMS SECTION ─────────────────────
                if (hasManual) ...[
                  _sectionHeader('ALARMS', icon: Icons.alarm),
                  ...alarms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final alarm = entry.value;

                    return Dismissible(
                      key: ValueKey(alarm.id),
                      direction: DismissDirection.endToStart,
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
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _deleteAlarm(index),
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
                        trailing: Switch(
                          value: alarm.isEnabled,
                          onChanged: (value) => _toggleAlarm(index, value),
                        ),
                        onTap: () => _openAddEditAlarm(alarm: alarm),
                      ),
                    );
                  }),
                ],

                // ── HABIT REMINDERS SECTION ───────────────────
                if (hasHabit) ...[
                  _sectionHeader(
                    'HABIT REMINDERS',
                    icon: Icons.self_improvement,
                  ),
                  ..._habitReminders.map((entry) {
                    final (habit, routine) = entry;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.outline.withOpacity(0.15),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            habit.reminderTime!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          habit.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          routine.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                        trailing: Icon(
                          Icons.self_improvement,
                          size: 18,
                          color: scheme.onSurface.withOpacity(0.35),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditAlarm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
