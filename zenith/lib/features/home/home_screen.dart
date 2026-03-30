import 'package:flutter/material.dart';

import '../alarm/alarm_screen.dart';
import '../calender/calendar_screen.dart';
import '../habits/habits_screen.dart';
import '../today/today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // GlobalKeys let us call refresh() on the live state of each screen
  final _todayKey = GlobalKey<TodayScreenState>();
  final _alarmKey = GlobalKey<AlarmScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TodayScreen(key: _todayKey),
      const CalendarScreen(),
      const HabitsScreen(),
      AlarmScreen(key: _alarmKey),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    // Refresh data when switching to Today or Alarm tabs
    switch (index) {
      case 0:
        _todayKey.currentState?.refresh();
        break;
      case 3:
        _alarmKey.currentState?.refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zenith'), centerTitle: true),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Routines'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarm'),
        ],
      ),
    );
  }
}