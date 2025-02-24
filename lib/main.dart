import 'package:flutter/material.dart';

import 'screens/vertical_calendar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertical Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VerticalCalendarScreen(),
    );
  }
}
