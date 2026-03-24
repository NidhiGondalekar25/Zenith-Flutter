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
    setState(() => _remindersForSelectedDate = reminders);
  }

  Future<void> _loadMarkedDates() async {
    final dates = await ReminderDB.getAllReminderDates();
    setState(() {
      _markedDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    });
  }

  Future<void> _openSheet({Reminder? reminder}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddReminderSheet(initialDate: _selectedDate, reminder: reminder),
    );
    if (saved == true) _reloadAll();
  }

  bool _hasReminder(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _markedDates.contains(normalized);
  }

  String get _selectedDateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (_selectedDate == today) return 'Today';
    if (_selectedDate == tomorrow) return 'Tomorrow';

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── CALENDAR ────────────────────────────────
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            headerStyle: HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: scheme.outline.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              formatButtonTextStyle: TextStyle(
                fontSize: 13,
                color: scheme.onSurface,
              ),
              titleCentered: false,
              titleTextStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: TextStyle(color: scheme.error.withOpacity(0.7)),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (_hasReminder(day)) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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

          // ── SECTION HEADER ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDateLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_remindersForSelectedDate.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_remindersForSelectedDate.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── REMINDERS LIST ───────────────────────────
          Expanded(
            child: _remindersForSelectedDate.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 40,
                          color: scheme.outline.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No reminders for $_selectedDateLabel',
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add one',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _remindersForSelectedDate.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reminder = _remindersForSelectedDate[index];
                      final timeStr =
                          '${reminder.date.hour.toString().padLeft(2, '0')}:${reminder.date.minute.toString().padLeft(2, '0')}';

                      return Dismissible(
                        key: ValueKey(reminder.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Reminder?'),
                              content: Text(
                                '"${reminder.title}" will be deleted.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          await ReminderDB.deleteReminder(reminder.id);
                          _reloadAll();
                        },
                        child: InkWell(
                          onTap: () => _openSheet(reminder: reminder),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceVariant.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: scheme.outline.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Time badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Title + note
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (reminder.note != null &&
                                          reminder.note!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            reminder.note!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: scheme.onSurface
                                                  .withOpacity(0.55),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: scheme.onSurface.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
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
