import 'dart:convert';

class Routine {
  final String id;
  final String title;
  final String? description;
  final String scheduleType;
  final List<int>? scheduleDays;
  final String? reminderTime;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.title,
    this.description,
    required this.scheduleType,
    this.scheduleDays,
    this.reminderTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduleType': scheduleType,
      'scheduleDays': scheduleDays == null ? null : jsonEncode(scheduleDays),
      'reminderTime': reminderTime,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      scheduleType: map['scheduleType'],
      scheduleDays: map['scheduleDays'] == null
          ? null
          : List<int>.from(jsonDecode(map['scheduleDays'])),
      reminderTime: map['reminderTime'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}