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

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
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

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
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
    if (_titleController.text.trim().isEmpty) return;
    try {
      final reminder = Reminder(
        id: widget.reminder?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _dateTime,
      );
      await ReminderDB.insert(reminder);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SAVE FAILED: $e');
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text('"${widget.reminder!.title}" will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ReminderDB.deleteReminder(widget.reminder!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  String get _formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[_dateTime.month - 1]} ${_dateTime.day}, ${_dateTime.year}';
  }

  String get _formattedTime {
    final h = _dateTime.hour.toString().padLeft(2, '0');
    final m = _dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── DRAG HANDLE ──────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── TITLE ROW ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Edit Reminder' : 'New Reminder',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isEditing)
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── TITLE FIELD ──────────────────────────────
          TextField(
            controller: _titleController,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Take vitamins',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: scheme.surfaceVariant.withOpacity(0.3),
            ),
          ),

          const SizedBox(height: 12),

          // ── NOTE FIELD ───────────────────────────────
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Note',
              hintText: 'Optional details...',
              prefixIcon: const Icon(Icons.notes),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: scheme.surfaceVariant.withOpacity(0.3),
            ),
          ),

          const SizedBox(height: 16),

          // ── DATE & TIME PICKERS ──────────────────────
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _formattedDate,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_outlined,
                  label: 'Time',
                  value: _formattedTime,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── SAVE BUTTON ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isEditing ? 'Save Changes' : 'Add Reminder',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tappable tile for date/time picking
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
