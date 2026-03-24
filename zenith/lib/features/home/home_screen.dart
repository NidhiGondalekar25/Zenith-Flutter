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

  final List<Widget> _screens = const [
    TodayScreen(),
    CalendarScreen(),
    HabitsScreen(),
    AlarmScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zenith'), centerTitle: true),

      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 🔥 important for 4 items
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
