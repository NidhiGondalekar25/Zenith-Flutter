import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'reminder_model.dart';

class ReminderDB {
  static Database? _db;

  // 🔹 INIT (call once from main.dart)
  static Future<void> init() async {
    final path = join(await getDatabasesPath(), 'reminders.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            note TEXT,
            date INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE reminders ADD COLUMN date INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  static Database get _database {
    if (_db == null) {
      throw Exception('ReminderDB not initialized. Call ReminderDB.init()');
    }
    return _db!;
  }

  // 🔹 INSERT (ADD)
  static Future<void> insert(Reminder reminder) async {
    await _database.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🔹 UPDATE (EDIT)
  static Future<void> update(Reminder reminder) async {
    await _database.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // 🔹 GET BY DATE
  static Future<List<Reminder>> getByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await _database.query(
      'reminders',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'date ASC',
    );

    return maps.map((e) => Reminder.fromMap(e)).toList();
  }

  // 🔹 DELETE
  static Future<void> deleteReminder(String id) async {
    await _database.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Set<DateTime>> getAllReminderDates() async {
    final maps = await _database.query('reminders', columns: ['date']);

    return maps.map((m) {
      final dt = DateTime.fromMillisecondsSinceEpoch(m['date'] as int);
      // 🔑 DATE ONLY (NO TIME)
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();
  }
}
