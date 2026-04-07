import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'habit_model.dart';
import 'routine_model.dart';

class HabitDB {
  // ── HELPERS ───────────────────────────────────────────────────

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('HabitDB: No user logged in');
    return uid;
  }

  static CollectionReference get _routines =>
      _db.collection('users').doc(_uid).collection('routines');

  static CollectionReference get _habits =>
      _db.collection('users').doc(_uid).collection('habits');

  static CollectionReference get _logs =>
      _db.collection('users').doc(_uid).collection('habit_logs');

  static DocumentReference get _stats =>
      _db.collection('users').doc(_uid).collection('app_stats').doc('stats');

  // ── INIT (no-op for Firestore — kept for compatibility) ───────
  static Future<void> init() async {}

  // ── ROUTINES ──────────────────────────────────────────────────

  static Future<void> addRoutine(Routine routine) async {
    await _routines.doc(routine.id).set(routine.toMap());
  }

  static Future<List<Routine>> getAllRoutines() async {
    final snapshot = await _routines.orderBy('created_at').get();
    return snapshot.docs
        .map((d) => Routine.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateRoutine(Routine routine) async {
    await _routines.doc(routine.id).update(routine.toMap());
  }

  static Future<void> deleteRoutine(String routineId) async {
    final habitSnap = await _habits
        .where('routineId', isEqualTo: routineId)
        .get();
    for (final doc in habitSnap.docs) {
      await doc.reference.delete();
    }

    final logSnap = await _logs.where('routineId', isEqualTo: routineId).get();
    for (final doc in logSnap.docs) {
      await doc.reference.delete();
    }

    await _routines.doc(routineId).delete();
  }

  // ── HABITS ────────────────────────────────────────────────────

  static Future<void> addHabit(Habit habit) async {
    await _habits.doc(habit.id).set(habit.toMap());
  }

  static Future<List<Habit>> getHabitsForRoutine(String routineId) async {
    final snapshot = await _habits
        .where('routineId', isEqualTo: routineId)
        .get();
    return snapshot.docs
        .map((d) => Habit.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateHabit(Habit habit) async {
    await _habits.doc(habit.id).update(habit.toMap());
  }

  static Future<void> deleteHabit(String habitId) async {
    final logSnap = await _logs.where('habitId', isEqualTo: habitId).get();
    for (final doc in logSnap.docs) {
      await doc.reference.delete();
    }
    await _habits.doc(habitId).delete();
  }

  // ── DAILY LOGS ────────────────────────────────────────────────

  static String _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  static Future<void> markHabitDone({
    required String habitId,
    required String routineId,
    required DateTime date,
  }) async {
    final normalized = _normalizeDate(date);
    final docId = '${habitId}_$normalized';
    await _logs.doc(docId).set({
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
    final normalized = _normalizeDate(date);
    final docId = '${habitId}_$normalized';
    await _logs.doc(docId).delete();
  }

  static Future<Set<String>> getCompletedHabitsForToday(
    String routineId,
  ) async {
    final today = _normalizeDate(DateTime.now());
    final snapshot = await _logs
        .where('routineId', isEqualTo: routineId)
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs
        .map((d) => (d.data() as Map<String, dynamic>)['habitId'] as String)
        .toSet();
  }

  static Future<bool> isRoutineCompletedToday(String routineId) async {
    final habits = await getHabitsForRoutine(routineId);
    if (habits.isEmpty) return false;
    final completed = await getCompletedHabitsForToday(routineId);
    return habits.every((h) => completed.contains(h.id));
  }

  // ── STREAK ────────────────────────────────────────────────────

  static Future<int> getCurrentStreak() async {
    try {
      final doc = await _stats.get();
      if (!doc.exists) return 0;
      return (doc.data() as Map<String, dynamic>?)?['current_streak'] as int? ??
          0;
    } catch (e) {
      debugPrint('getCurrentStreak error: $e');
      return 0;
    }
  }

  static Future<void> incrementStreak() async {
    final today = _normalizeDate(DateTime.now());

    final doc = await _stats.get();
    final data = doc.data() as Map<String, dynamic>?;
    final lastDate = data?['last_streak_date'] as String?;

    if (lastDate == today) return;

    final current = data?['current_streak'] as int? ?? 0;

    await _stats.set({
      'current_streak': current + 1,
      'last_streak_date': today,
    });
  }

  static Future<void> resetStreakForToday() async {
    final today = _normalizeDate(DateTime.now());

    final doc = await _stats.get();
    final data = doc.data() as Map<String, dynamic>?;
    final lastDate = data?['last_streak_date'] as String?;

    if (lastDate != today) return;

    final current = data?['current_streak'] as int? ?? 0;

    await _stats.set({
      'current_streak': (current - 1).clamp(0, 999),
      'last_streak_date': null,
    });
  }

  static Future<int> calculateRoutineStreak(String routineId) async {
    final snapshot = await _logs.where('routineId', isEqualTo: routineId).get();

    if (snapshot.docs.isEmpty) return 0;

    final days =
        snapshot.docs
            .map((d) => (d.data() as Map<String, dynamic>)['date'] as String)
            .map((s) => DateTime.parse(s))
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
