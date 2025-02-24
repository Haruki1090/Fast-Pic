import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../model/photo_repository.dart';
import '../widgets/month_calendar.dart';

class VerticalCalendarScreen extends StatefulWidget {
  const VerticalCalendarScreen({super.key});

  @override
  VerticalCalendarScreenState createState() => VerticalCalendarScreenState();
}

class VerticalCalendarScreenState extends State<VerticalCalendarScreen> {
  late Future<Map<DateTime, AssetEntity>> _futureAssetsByDay;
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
    _futureAssetsByDay = PhotoRepository.fetchAssetsGroupedByDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('縦スクロールカレンダー'),
      ),
      body: FutureBuilder<Map<DateTime, AssetEntity>>(
        future: _futureAssetsByDay,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('写真が見つかりませんでした'));
          }

          final months = _generateAllMonths();
          if (months.isNotEmpty) {
            _scrollToBottom();
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final y = months[index]["year"]!;
              final m = months[index]["month"]!;
              return MonthCalendar(
                year: y,
                month: m,
                assetsByDay: snapshot.data!,
              );
            },
          );
        },
      ),
    );
  }
}
