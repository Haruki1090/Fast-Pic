import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widgets/month_calendar.dart';

class VerticalCalendarScreen extends StatefulWidget {
  final Map<DateTime, AssetEntity> assetsByDay;

  const VerticalCalendarScreen({
    super.key,
    required this.assetsByDay,
  });

  @override
  VerticalCalendarScreenState createState() => VerticalCalendarScreenState();
}

class VerticalCalendarScreenState extends State<VerticalCalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final DateTime _currentDate = DateTime.now();

  List<Map<String, int>> _generateAllMonths() {
    final List<Map<String, int>> months = [];
    final currentYear = _currentDate.year;
    final currentMonth = _currentDate.month;

    // 過去5年分を古い順に生成（例: 2020年1月 → 2025年2月）
    for (int year = currentYear - 5; year <= currentYear; year++) {
      final startMonth = year == currentYear - 5 ? 1 : 1;
      final endMonth = year == currentYear ? currentMonth : 12;

      for (int month = startMonth; month <= endMonth; month++) {
        months.add({'year': year, 'month': month});
      }
    }
    return months;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final months = _generateAllMonths();
    if (months.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      body: ListView.builder(
        controller: _scrollController,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final y = months[index]["year"]!;
          final m = months[index]["month"]!;
          return MonthCalendar(
            year: y,
            month: m,
            assetsByDay: widget.assetsByDay,
          );
        },
      ),
    );
  }
}
