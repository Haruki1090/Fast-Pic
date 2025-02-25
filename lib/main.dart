import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'screens/vertical_calendar_screen.dart';
import 'screens/weekly_calendar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PhotoManager.setLog(true); // ログ有効化
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertical Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    VerticalCalendarScreen(),
    WeeklyCalendarScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_month),
            label: '月表示',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: '週表示',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
