import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'reminder_model.dart';

class ReminderFormScreen extends StatefulWidget {
  final Reminder? reminder;
  final DateTime? initialDate;

  const ReminderFormScreen({super.key, this.reminder, this.initialDate});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  late DateTime _dateTime;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _dateTime = widget.reminder?.date ?? widget.initialDate ?? DateTime.now();

    _controller = TextEditingController(text: widget.reminder?.title ?? '');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dateTime.hour,
          _dateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );

    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _save() {
    if (_controller.text.trim().isEmpty) return;

    Navigator.pop(
      context,
      Reminder(
        id: widget.reminder?.id ?? const Uuid().v4(),
        date: _dateTime,
        title: _controller.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('${_dateTime.toLocal().toString().split(" ")[0]}'),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(TimeOfDay.fromDateTime(_dateTime).format(context)),
              onTap: _pickTime,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save, // 👈 THIS FIXES IT
              child: const Text("Save Reminder"),
            ),
          ],
        ),
      ),
    );
  }
}
