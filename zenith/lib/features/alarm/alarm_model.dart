class Alarm {
  final String id;
  final DateTime time;
  final String label;
  final String ringtone;
  final String screen;
  final bool isEnabled;
  final List<int> repeatDays; // 1 = Mon ... 7 = Sun

  Alarm({
    required this.id,
    required this.time,
    required this.label,
    required this.ringtone,
    required this.screen,
    required this.isEnabled,
    required this.repeatDays,
  });

  Alarm copyWith({
    DateTime? time,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
  }) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      label: label ?? this.label,
      ringtone: ringtone,
      screen: screen,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  void operator [](String other) {}
}
