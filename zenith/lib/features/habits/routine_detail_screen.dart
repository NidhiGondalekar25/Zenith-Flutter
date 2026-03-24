import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'habit_db.dart';
import 'habit_model.dart';
import 'routine_model.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  List<Habit> _habits = [];
  Set<String> _completedToday = {};
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final habits = await HabitDB.getHabitsForRoutine(widget.routine.id);
    final completed = await HabitDB.getCompletedHabitsForToday(
      widget.routine.id,
    );
    final streak = await HabitDB.calculateRoutineStreak(widget.routine.id);

    setState(() {
      _habits = habits;
      _completedToday = completed;
      _streak = streak;
    });
  }

  Future<void> _addHabit() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Habit'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Habit name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final habit = Habit(
        id: const Uuid().v4(),
        routineId: widget.routine.id,
        title: controller.text.trim(),
        hasReminder: false, // ✅ REQUIRED
        reminderTime: null,
      );

      await HabitDB.addHabit(habit);
      _loadData();
    }
  }

  Future<void> _toggleHabit(Habit habit, bool checked) async {
    final today = DateUtils.dateOnly(DateTime.now());

    if (checked) {
      await HabitDB.markHabitDone(
        habitId: habit.id,
        routineId: widget.routine.id,
        date: today,
      );
    } else {
      await HabitDB.unmarkHabitDone(
        habitId: habit.id,
        routineId: widget.routine.id,
        date: today,
      );
    }

    _loadData();
  }

  Future<void> _setReminder(Habit habit) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final formatted =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    final updated = Habit(
      id: habit.id,
      routineId: habit.routineId,
      title: habit.title,
      hasReminder: true,
      reminderTime: formatted,
    );

    await HabitDB.updateHabit(updated);

    _loadData();
  }

  Future<void> _editHabit(Habit habit) async {
    final controller = TextEditingController(text: habit.title);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Habit"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Habit name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final updated = Habit(
        id: habit.id,
        routineId: habit.routineId,
        title: controller.text.trim(),
        hasReminder: habit.hasReminder,
        reminderTime: habit.reminderTime,
      );

      await HabitDB.updateHabit(updated);

      _loadData();
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: Text(
            'Delete "${habit.title}"?\n\n'
            'This will remove its entire history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await HabitDB.deleteHabit(habit.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_streak > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$_streak day streak 🔥',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          Expanded(
            child: _habits.isEmpty
                ? const Center(
                    child: Text(
                      'No habits yet.\nAdd one to start building streaks 💪',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
                      final checked = _completedToday.contains(habit.id);

                      return Dismissible(
                        key: ValueKey(habit.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await _deleteHabit(habit);
                          return false;
                        },
                        child: ListTile(
                          title: Text(habit.title),
                          subtitle: habit.hasReminder
                              ? Text("Reminder: ${habit.reminderTime}")
                              : null,
                          trailing: IconButton(
                            icon: Icon(
                              habit.hasReminder
                                  ? Icons.alarm_on
                                  : Icons.alarm_add,
                            ),
                            onPressed: () {
                              _setReminder(habit);
                            },
                          ),
                          onLongPress: () {
                            _editHabit(habit);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
