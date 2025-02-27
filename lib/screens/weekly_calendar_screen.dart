import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widgets/week_calendar.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  final Map<DateTime, AssetEntity> assetsByDay;
  final ScrollController scrollController;

  const WeeklyCalendarScreen({
    super.key,
    required this.assetsByDay,
    required this.scrollController,
  });

  @override
  WeeklyCalendarScreenState createState() => WeeklyCalendarScreenState();
}

class WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final DateTime _currentDate = DateTime.now();

  List<Map<String, dynamic>> _generateWeeks() {
    final List<Map<String, dynamic>> weeks = [];

    // 現在の日付から12週間前まで遡る
    DateTime currentDay = _currentDate;

    // 現在の日付を含む週の日曜日を見つける
    final int daysUntilSunday = currentDay.weekday % 7;
    DateTime currentSunday =
        currentDay.subtract(Duration(days: daysUntilSunday));

    for (int i = 0; i < 12; i++) {
      // 週の開始日（日曜日）
      final weekStartDate = currentSunday.subtract(Duration(days: 7 * i));
      // 週の終了日（土曜日）
      final weekEndDate = weekStartDate.add(const Duration(days: 6));

      weeks.add({
        'startDate': weekStartDate,
        'endDate': weekEndDate,
      });
    }

    return weeks;
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _generateWeeks();
    if (weeks.isNotEmpty) {
      _scrollToTop();
    }

    return Scaffold(
      body: ListView.builder(
        controller: _scrollController,
        itemCount: weeks.length,
        itemBuilder: (context, index) {
          final startDate = weeks[index]["startDate"] as DateTime;
          final endDate = weeks[index]["endDate"] as DateTime;

          return WeekCalendar(
            startDate: startDate,
            endDate: endDate,
            assetsByDay: widget.assetsByDay,
          );
        },
      ),
    );
  }
}
