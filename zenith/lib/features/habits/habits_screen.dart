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

  Future<void> _loadRoutines() async {
    final routines = await HabitDB.getAllRoutines();
    final List<Routine> updated = [];

    for (final routine in routines) {
      final streak = await HabitDB.calculateRoutineStreak(routine.id);

      updated.add(
        Routine(
          id: routine.id,
          title: routine.title,
          description: streak.toString(), // store streak as string for UI
          createdAt: routine.createdAt,
        ),
      );
    }

    setState(() {
      _routines = updated;
    });
  }

  Future<void> _addRoutine(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Routine'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Routine name'),
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
      final routine = Routine(
        id: const Uuid().v4(),
        title: controller.text.trim(),
        createdAt: DateTime.now(),
      );

      await HabitDB.addRoutine(routine);
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
                'No routines yet.\nTap + to create one 🔥',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _routines.length,
              itemBuilder: (context, index) {
                final routine = _routines[index];

                return ListTile(
                  title: Text(routine.title),
                  subtitle: Text('${routine.description} day streak 🔥'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineDetailScreen(routine: routine),
                      ),
                    );

                    // 🔥 ALWAYS refresh when coming back
                    _loadRoutines();
                  },
                );
              },
            ),
    );
  }
}
