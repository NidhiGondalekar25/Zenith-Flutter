import 'package:flutter/material.dart';

import '../habits/habit_db.dart';
import '../habits/habit_model.dart';
import '../habits/routine_model.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<Routine> _todayRoutines = [];
  Map<String, List<Habit>> _habits = {};
  Map<String, Set<String>> _completed = {};
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  bool _isRoutineScheduledToday(Routine routine) {
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    if (routine.scheduleType == "daily") return true;

    if (routine.scheduleType == "weekly") {
      return routine.scheduleDays?.contains(today) ?? false;
    }

    return true; // fallback: show it
  }

  Future<void> _loadToday() async {
    final routines = await HabitDB.getAllRoutines();
    final todayRoutines = routines.where(_isRoutineScheduledToday).toList();

    // Load habits and completion state for each routine
    final Map<String, List<Habit>> habitsMap = {};
    final Map<String, Set<String>> completedMap = {};

    for (final routine in todayRoutines) {
      habitsMap[routine.id] = await HabitDB.getHabitsForRoutine(routine.id);
      completedMap[routine.id] = await HabitDB.getCompletedHabitsForToday(
        routine.id,
      );
    }

    // Calculate streak from app_stats
    final streak = await HabitDB.getCurrentStreak();

    setState(() {
      _todayRoutines = todayRoutines;
      _habits = habitsMap;
      _completed = completedMap;
      _streak = streak;
      _loading = false;
    });
  }

  /// Check if all habits across all routines are done → increment streak
  Future<void> _checkDailyCompletion() async {
    if (_todayRoutines.isEmpty) return;

    for (final routine in _todayRoutines) {
      final habits = _habits[routine.id] ?? [];
      final completed = _completed[routine.id] ?? {};

      // If any routine has no habits or is incomplete → not done
      if (habits.isEmpty || completed.length < habits.length) return;
    }

    await HabitDB.incrementStreak();
    await _loadToday(); // refresh streak display
  }

  Future<void> _toggleHabit(Routine routine, Habit habit, bool done) async {
    if (done) {
      // Unchecking — remove log, then roll back streak if it was earned today
      await HabitDB.unmarkHabitDone(
        habitId: habit.id,
        routineId: routine.id,
        date: DateTime.now(),
      );
      await HabitDB.resetStreakForToday();
    } else {
      await HabitDB.markHabitDone(
        habitId: habit.id,
        routineId: routine.id,
        date: DateTime.now(),
      );
    }

    await _loadToday();
    await _checkDailyCompletion();
  }

  int _totalHabits() =>
      _todayRoutines.fold(0, (sum, r) => sum + (_habits[r.id]?.length ?? 0));

  int _totalCompleted() =>
      _todayRoutines.fold(0, (sum, r) => sum + (_completed[r.id]?.length ?? 0));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayRoutines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Nothing scheduled today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text('Enjoy your rest day!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final total = _totalHabits();
    final done = _totalCompleted();
    final progress = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── STREAK BANNER ──────────────────────────────
        if (_streak > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_streak Day Streak',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

        // ── DAILY PROGRESS SUMMARY ─────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$done / $total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (progress == 1.0)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '✅ All done for today!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── ROUTINE CARDS ──────────────────────────────
        ..._todayRoutines.map((routine) {
          final habits = _habits[routine.id] ?? [];
          final completed = _completed[routine.id] ?? {};
          final allDone =
              habits.isNotEmpty && completed.length == habits.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: allDone
                    ? Colors.green.withOpacity(0.4)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        routine.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (allDone)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                  ],
                ),
                subtitle: Text(
                  '${completed.length} of ${habits.length} done',
                  style: TextStyle(
                    fontSize: 12,
                    color: allDone ? Colors.green : Colors.grey,
                  ),
                ),
                children: habits.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No habits in this routine yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ]
                    : habits.map((habit) {
                        final isDone = completed.contains(habit.id);

                        return CheckboxListTile(
                          value: isDone,
                          onChanged: (_) =>
                              _toggleHabit(routine, habit, isDone),
                          title: Text(
                            habit.title,
                            style: TextStyle(
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isDone ? Colors.grey : null,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }).toList(),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
