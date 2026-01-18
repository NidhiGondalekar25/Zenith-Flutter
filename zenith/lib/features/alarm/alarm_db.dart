import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'alarm_model.dart';

class AlarmDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'alarms.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE alarms(
            id TEXT PRIMARY KEY,
            time INTEGER,
            label TEXT,
            ringtone TEXT,
            screen TEXT,
            isEnabled INTEGER,
            repeatDays TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertAlarm(Alarm alarm) async {
    final db = await database;
    await db.insert('alarms', {
      'id': alarm.id,
      'time': alarm.time.millisecondsSinceEpoch,
      'label': alarm.label,
      'ringtone': alarm.ringtone,
      'screen': alarm.screen,
      'isEnabled': alarm.isEnabled ? 1 : 0,
      'repeatDays': alarm.repeatDays.join(','),
    });
  }

  static Future<List<Alarm>> getAlarms() async {
    final db = await database;
    final maps = await db.query('alarms');

    return maps.map((m) {
      return Alarm(
        id: m['id'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(m['time'] as int),
        label: m['label'] as String,
        ringtone: m['ringtone'] as String,
        screen: m['screen'] as String,
        isEnabled: (m['isEnabled'] as int) == 1,
        repeatDays: (m['repeatDays'] as String)
            .split(',')
            .where((e) => e.isNotEmpty)
            .map(int.parse)
            .toList(),
      );
    }).toList();
  }

  static Future<void> updateAlarm(Alarm alarm) async {
    final db = await database;
    await db.update(
      'alarms',
      {
        'time': alarm.time.millisecondsSinceEpoch,
        'label': alarm.label,
        'ringtone': alarm.ringtone,
        'screen': alarm.screen,
        'isEnabled': alarm.isEnabled ? 1 : 0,
        'repeatDays': alarm.repeatDays.join(','),
      },
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  static Future<void> deleteAlarm(String id) async {
    final db = await database;
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }
}
