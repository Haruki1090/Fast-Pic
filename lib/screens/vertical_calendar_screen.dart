import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart'; // AssetEntity 型を使うため

import '../model/photo_repository.dart';
import '../widgets/month_calendar.dart';

class VerticalCalendarScreen extends StatefulWidget {
  const VerticalCalendarScreen({super.key});

  @override
  VerticalCalendarScreenState createState() => VerticalCalendarScreenState();
}

class VerticalCalendarScreenState extends State<VerticalCalendarScreen> {
  late Future<Map<DateTime, AssetEntity>> _futureAssetsByDay;

  @override
  void initState() {
    super.initState();
    // 起動時に一度だけ読み込み (スクリーンショット除外、同日最初の1枚だけ)
    _futureAssetsByDay = PhotoRepository.fetchAssetsGroupedByDay();
  }

  @override
  Widget build(BuildContext context) {
    // この例では 2025年1月～2月 のみを並べる
    // 必要に応じて動的に対象月を増やす / 現在月を基準にする など柔軟に調整してください
    final months = [
      {"year": 2025, "month": 1},
      {"year": 2025, "month": 2},
    ];

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

          if (!snapshot.hasData) {
            return const Center(child: Text('Failed to fetch photos'));
          }

          final assetsByDay = snapshot.data!;
          if (assetsByDay.isEmpty) {
            return const Center(child: Text('No photos found'));
          }

          return ListView.builder(
            itemCount: months.length,
            itemBuilder: (context, index) {
              final y = months[index]["year"]!;
              final m = months[index]["month"]!;
              return MonthCalendar(
                year: y,
                month: m,
                assetsByDay: assetsByDay,
              );
            },
          );
        },
      ),
    );
  }
}
