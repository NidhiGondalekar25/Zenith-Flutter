import 'package:flutter/material.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final String? existingId;
  final TimeOfDay? existingTime;
  final String? existingLabel;
  final List<int>? existingRepeatDays; // ✅ ADD

  const AddEditAlarmScreen({
    super.key,
    this.existingId,
    this.existingTime,
    this.existingLabel,
    this.existingRepeatDays, // ✅ ADD
  });

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late List<int> _repeatDays;

  final weekDays = const [
    {'label': 'Mon', 'value': 1},
    {'label': 'Tue', 'value': 2},
    {'label': 'Wed', 'value': 3},
    {'label': 'Thu', 'value': 4},
    {'label': 'Fri', 'value': 5},
    {'label': 'Sat', 'value': 6},
    {'label': 'Sun', 'value': 7},
  ];

  @override
  void initState() {
    super.initState();

    _time = widget.existingTime ?? TimeOfDay.now();
    _labelController = TextEditingController(
      text: widget.existingLabel ?? 'Alarm',
    );
    _repeatDays = List.from(widget.existingRepeatDays ?? []);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _toggleRepeatDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  void _saveAlarm() {
    Navigator.pop(context, {
      'id': widget.existingId,
      'time': _time,
      'label': _labelController.text,
      'repeatDays': _repeatDays, // ✅ RETURN
    });
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: const Text('Are you sure you want to delete this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      Navigator.pop(context, {'delete': true, 'id': widget.existingId});
    }
  }

  String _format24Hour(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTime != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Alarm' : 'Add Alarm'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAlarm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Time'),
              subtitle: Text(
                _format24Hour(_time),
                style: const TextStyle(fontSize: 20),
              ),
              onTap: _pickTime,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),

            const SizedBox(height: 20),

            const Text(
              'Repeat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: weekDays.map((day) {
                final value = day['value'] as int;
                final selected = _repeatDays.contains(value);

                return ChoiceChip(
                  label: Text(day['label'] as String),
                  selected: selected,
                  onSelected: (_) => _toggleRepeatDay(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
