import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'screens/vertical_calendar_screen.dart';

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
      home: const VerticalCalendarScreen(),
    );
  }
}
