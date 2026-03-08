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
      version: 2, // 🔥 bump version
      onCreate: (db, _) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS habit_logs');
          await db.execute('DROP TABLE IF EXISTS habits');
          await db.execute('DROP TABLE IF EXISTS routines');
          await _createTables(db);
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

  // ================= STREAK =================

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
}
