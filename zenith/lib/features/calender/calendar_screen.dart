import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_reminder_sheet.dart';
import 'reminder_db.dart';
import 'reminder_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  List<Reminder> _remindersForSelectedDate = [];
  Set<DateTime> _markedDates = {};

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    await _loadMarkedDates();
    await _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await ReminderDB.getByDate(_selectedDate);
    setState(() {
      _remindersForSelectedDate = reminders;
    });
  }

  Future<void> _loadMarkedDates() async {
    final dates = await ReminderDB.getAllReminderDates();
    setState(() {
      _markedDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    });
  }

  Future<void> _addReminder() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddReminderSheet(initialDate: _selectedDate),
    );

    if (saved == true) {
      _reloadAll();
    }
  }

  Future<bool> _confirmDelete(Reminder reminder) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Reminder?'),
            content: Text('“${reminder.title ?? ''}” will be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool _hasReminder(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _markedDates.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 📅 CALENDAR
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (_hasReminder(day)) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }
                return null;
              },
            ),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
                _focusedDay = focusedDay;
              });
              _loadReminders();
            },
          ),

          const Divider(),

          // 📝 REMINDERS LIST
          Expanded(
            child: _remindersForSelectedDate.isEmpty
                ? const Center(child: Text('No reminders for this day'))
                : ListView.builder(
                    itemCount: _remindersForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final reminder = _remindersForSelectedDate[index];

                      return Dismissible(
                        key: ValueKey(reminder.id),
                        direction: DismissDirection.endToStart,

                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        confirmDismiss: (_) async {
                          return await _confirmDelete(reminder);
                        },

                        onDismissed: (_) async {
                          await ReminderDB.deleteReminder(reminder.id);
                          _reloadAll();
                        },

                        child: ListTile(
                          title: Text(reminder.title ?? ''),
                          subtitle: Text(
                            '${reminder.date.hour.toString().padLeft(2, '0')}:${reminder.date.minute.toString().padLeft(2, '0')}',
                          ),
                          onTap: () async {
                            final updated = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => AddReminderSheet(
                                initialDate: _selectedDate,
                                reminder: reminder,
                              ),
                            );

                            if (updated == true) {
                              _reloadAll();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
