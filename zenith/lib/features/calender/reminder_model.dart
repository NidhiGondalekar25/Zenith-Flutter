class Reminder {
  final String id;
  final String title;
  final String? note;
  final DateTime date;

  Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      note: map['note'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
