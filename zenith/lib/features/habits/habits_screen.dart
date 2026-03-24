import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zenith/features/habits/routine_detail_screen.dart';

import 'habit_db.dart';
import 'routine_model.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  // 🔹 Check if routine should run today
  bool _isRoutineScheduledToday(Routine routine) {
    final today = DateTime.now().weekday;

    if (routine.scheduleType == "daily") {
      return true;
    }

    if (routine.scheduleType == "weekly") {
      return routine.scheduleDays?.contains(today) ?? false;
    }

    return false;
  }

  Future<void> _loadRoutines() async {
    final routines = await HabitDB.getAllRoutines();

    setState(() {
      _routines = routines;
    });
  }

  Future<void> _addRoutine(BuildContext context) async {
    final controller = TextEditingController();

    String scheduleType = "daily";
    List<int> selectedDays = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Routine'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Routine name'),
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Schedule"),
                  ),

                  RadioListTile(
                    title: const Text("Daily"),
                    value: "daily",
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setState(() {
                        scheduleType = value!;
                      });
                    },
                  ),

                  RadioListTile(
                    title: const Text("Custom Days"),
                    value: "weekly",
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setState(() {
                        scheduleType = value!;
                      });
                    },
                  ),

                  if (scheduleType == "weekly")
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final day = index + 1;

                        final labels = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun",
                        ];

                        final selected = selectedDays.contains(day);

                        return FilterChip(
                          label: Text(labels[index]),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                ],
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
      },
    );

    if (result == true) {
      final routine = Routine(
        id: const Uuid().v4(),
        title: controller.text.trim(),
        description: null,
        scheduleType: scheduleType,
        scheduleDays: scheduleType == "weekly" ? selectedDays : null,
        reminderTime: null,
        createdAt: DateTime.now(),
      );

      await HabitDB.addRoutine(routine);

      _loadRoutines();
    }
  }

  Future<void> _editRoutine(BuildContext context, Routine routine) async {
    final controller = TextEditingController(text: routine.title);

    String scheduleType = routine.scheduleType;
    List<int> selectedDays = List.from(routine.scheduleDays ?? []);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Routine"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: "Routine name"),
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Schedule"),
                  ),

                  RadioListTile(
                    title: const Text("Daily"),
                    value: "daily",
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setState(() {
                        scheduleType = value!;
                      });
                    },
                  ),

                  RadioListTile(
                    title: const Text("Custom Days"),
                    value: "weekly",
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setState(() {
                        scheduleType = value!;
                      });
                    },
                  ),

                  if (scheduleType == "weekly")
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final day = index + 1;

                        final labels = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun",
                        ];

                        final selected = selectedDays.contains(day);

                        return FilterChip(
                          label: Text(labels[index]),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                ],
              ),

              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context, false),
                ),

                ElevatedButton(
                  child: const Text("Save"),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final updated = Routine(
        id: routine.id,
        title: controller.text.trim(),
        description: routine.description,
        scheduleType: scheduleType,
        scheduleDays: scheduleType == "weekly" ? selectedDays : null,
        reminderTime: routine.reminderTime,
        createdAt: routine.createdAt,
      );

      await HabitDB.updateRoutine(updated);

      _loadRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRoutine(context),
        child: const Icon(Icons.add),
      ),
      body: _routines.isEmpty
          ? const Center(
              child: Text(
                'No routines scheduled for today.\nTap + to create one 🔥',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _routines.length,
              itemBuilder: (context, index) {
                final routine = _routines[index];

                return Dismissible(
                  key: ValueKey(routine.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Routine'),
                        content: Text(
                          'Delete "${routine.title}"?\n\nThis will also delete all its habits and history.',
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
                  onDismissed: (_) async {
                    await HabitDB.deleteRoutine(routine.id);
                    _loadRoutines();
                  },
                  child: ListTile(
                    title: Text(routine.title),
                    subtitle: !_isRoutineScheduledToday(routine)
                        ? const Text(
                            "Not scheduled today",
                            style: TextStyle(color: Colors.grey),
                          )
                        : const Text("Tap to view habits"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoutineDetailScreen(routine: routine),
                        ),
                      );
                      _loadRoutines();
                    },
                    onLongPress: () {
                      _editRoutine(context, routine);
                    },
                  ),
                );
              },
            ),
    );
  }
}
