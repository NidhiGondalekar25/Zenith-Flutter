import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'reminder_model.dart';
import 'reminder_db.dart';

class AddReminderSheet extends StatefulWidget {
  final DateTime initialDate;
  final Reminder? reminder;

  const AddReminderSheet({super.key, required this.initialDate, this.reminder});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  late DateTime _dateTime;
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final r = widget.reminder!;
      _dateTime = r.date;
      _titleController.text = r.title;
      _noteController.text = r.note ?? '';
    } else {
      _dateTime = DateTime(
        widget.initialDate.year,
        widget.initialDate.month,
        widget.initialDate.day,
        TimeOfDay.now().hour,
        TimeOfDay.now().minute,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
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

  Future<void> _save() async {
    try {
      if (_titleController.text.trim().isEmpty) return;

      final reminder = Reminder(
        id: widget.reminder?.id ?? const Uuid().v4(), // 👈 keep ID if editing
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        date: _dateTime,
      );

      await ReminderDB.insert(reminder); // replace = update
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("SAVE FAILED: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Wrap(
        children: [
          const Text(
            'Add Reminder',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),

          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              TextButton(
                onPressed: _pickDate,
                child: Text(
                  '${_dateTime.day}/${_dateTime.month}/${_dateTime.year}',
                ),
              ),
              TextButton(
                onPressed: _pickTime,
                child: Text(
                  '${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              'Delete Reminder',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              await ReminderDB.deleteReminder(widget.reminder!.id);
              Navigator.pop(context, true); // refresh calendar
            },
          ),

          ElevatedButton(
            onPressed: _save,
            child: Text(
              widget.reminder == null ? 'Add Reminder' : 'Save Changes',
            ),
          ),
        ],
      ),
    );
  }
}
