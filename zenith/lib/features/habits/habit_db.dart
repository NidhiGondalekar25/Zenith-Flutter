import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'habit_model.dart';
import 'routine_model.dart';

class HabitDB {
  static Database? _db;

  // ================= INIT =================

  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'habits.db');

    _db = await openDatabase(
      path,
      version: 3, // 🔥 bump version
      onCreate: (db, _) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS habit_logs');
          await db.execute('DROP TABLE IF EXISTS habits');
          await db.execute('DROP TABLE IF EXISTS routines');
          await db.execute('DROP TABLE IF EXISTS app_stats');
          await _createTables(db);
        } else if (oldVersion < 3) {
          // Just add app_stats if upgrading from v2
          await db.execute('DROP TABLE IF EXISTS app_stats');
          await db.execute('''
            CREATE TABLE app_stats (
              id INTEGER PRIMARY KEY,
              current_streak INTEGER DEFAULT 0,
              last_streak_date TEXT
            )
          ''');
          await db.insert('app_stats', {
            'id': 1,
            'current_streak': 0,
            'last_streak_date': null,
          });
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
        CREATE TABLE routines (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          scheduleType TEXT,
          scheduleDays TEXT,
          reminderTime TEXT,
          created_at TEXT
        )
      ''');

    await db.execute('''
        CREATE TABLE habits (
          id TEXT PRIMARY KEY,
          routineId TEXT,
          title TEXT,
          hasReminder INTEGER,
          reminderTime TEXT
        )
      ''');

    await db.execute('''
        CREATE TABLE habit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          routineId TEXT,
          habitId TEXT,
          date TEXT
        )
      ''');

    await db.execute('''
        CREATE TABLE app_stats (
          id INTEGER PRIMARY KEY,
          current_streak INTEGER DEFAULT 0,
          last_streak_date TEXT
        )
      ''');

    // Insert default row
    await db.insert('app_stats', {
      'id': 1,
      'current_streak': 0,
      'last_streak_date': null,
    });
  }

  static Database get _database => _db!;

  // ================= ROUTINES =================

  static Future<void> addRoutine(Routine routine) async {
    await _database.insert('routines', routine.toMap());
  }

  static Future<List<Routine>> getAllRoutines() async {
    final rows = await _database.query('routines');
    return rows.map(Routine.fromMap).toList();
  }

  static Future<void> updateRoutine(Routine routine) async {
    await _database.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  static Future<void> deleteRoutine(String routineId) async {
    await _database.delete(
      'habit_logs',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    await _database.delete(
      'habits',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    await _database.delete('routines', where: 'id = ?', whereArgs: [routineId]);
  }

  // ================= HABITS =================

  static Future<void> addHabit(Habit habit) async {
    await _database.insert('habits', habit.toMap());
  }

  static Future<List<Habit>> getHabitsForRoutine(String routineId) async {
    final rows = await _database.query(
      'habits',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    return rows.map(Habit.fromMap).toList();
  }

  static Future<void> updateHabit(Habit habit) async {
    await _database.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  static Future<void> deleteHabit(String habitId) async {
    await _database.delete(
      'habit_logs',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    await _database.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  // ================= DAILY LOGS =================

  static Future<void> markHabitDone({
    required String habitId,
    required String routineId,
    required DateTime date,
  }) async {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    await _database.insert('habit_logs', {
      'habitId': habitId,
      'routineId': routineId,
      'date': normalized,
    });
  }

  static Future<void> unmarkHabitDone({
    required String habitId,
    required String routineId,
    required DateTime date,
  }) async {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    await _database.delete(
      'habit_logs',
      where: 'habitId = ? AND routineId = ? AND date = ?',
      whereArgs: [habitId, routineId, normalized],
    );
  }

  static Future<Set<String>> getCompletedHabitsForToday(
    String routineId,
  ) async {
    final today = DateTime.now();
    final normalized = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final rows = await _database.query(
      'habit_logs',
      where: 'routineId = ? AND date = ?',
      whereArgs: [routineId, normalized],
    );

    return rows.map((e) => e['habitId'] as String).toSet();
  }

  static Future<bool> isRoutineCompletedToday(String routineId) async {
    final habits = await getHabitsForRoutine(routineId);

    if (habits.isEmpty) return false;

    final completed = await getCompletedHabitsForToday(routineId);

    for (final habit in habits) {
      if (!completed.contains(habit.id)) {
        return false;
      }
    }

    return true;
  }

  // ================= STREAK =================

  static Future<int> getCurrentStreak() async {
    try {
      final rows = await _database.query(
        'app_stats',
        where: 'id = ?',
        whereArgs: [1],
      );

      if (rows.isEmpty) return 0;
      return (rows.first['current_streak'] as int?) ?? 0;
    } catch (e) {
      debugPrint('getCurrentStreak error: $e');
      return 0;
    }
  }

  static Future<int> calculateRoutineStreak(String routineId) async {
    final rows = await _database.query(
      'habit_logs',
      where: 'routineId = ?',
      whereArgs: [routineId],
      orderBy: 'date DESC',
    );

    if (rows.isEmpty) return 0;

    final days =
        rows
            .map((e) => DateTime.parse(e['date'] as String))
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime current = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    for (final day in days) {
      if (day == current) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  static Future<void> incrementStreak() async {
    final db = _db!;
    final today = DateTime.now();
    final todayStr = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final rows = await db.query('app_stats', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return;

    final lastDate = rows.first['last_streak_date'] as String?;

    // Don't increment if already incremented today
    if (lastDate == todayStr) return;

    await db.rawUpdate(
      '''
      UPDATE app_stats
      SET current_streak = current_streak + 1,
          last_streak_date = ?
      WHERE id = 1
    ''',
      [todayStr],
    );
  }

  /// Call this when a habit is unchecked — if streak was earned today, roll it back
  static Future<void> resetStreakForToday() async {
    final db = _db!;
    final today = DateTime.now();
    final todayStr = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final rows = await db.query('app_stats', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return;

    final lastDate = rows.first['last_streak_date'] as String?;

    // Only roll back if the streak was earned today
    if (lastDate != todayStr) return;

    final current = (rows.first['current_streak'] as int?) ?? 0;

    await db.rawUpdate(
      '''
      UPDATE app_stats
      SET current_streak = ?,
          last_streak_date = NULL
      WHERE id = 1
    ''',
      [(current - 1).clamp(0, 999)],
    );
  }
}
// APPEND PLACEHOLDER