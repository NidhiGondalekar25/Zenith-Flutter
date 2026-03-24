import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String routineId;
  final String title;
  final bool hasReminder;
  final String? reminderTime;

  Habit({
    required this.id,
    required this.routineId,
    required this.title,
    required this.hasReminder,
    this.reminderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'title': title,
      'hasReminder': hasReminder ? 1 : 0,
      'reminderTime': reminderTime,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      routineId: map['routineId'],
      title: map['title'],
      hasReminder: map['hasReminder'] == 1,
      reminderTime: map['reminderTime'],
    );
  }
}
