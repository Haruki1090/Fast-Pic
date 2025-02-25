import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';

class WeekCalendar extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, AssetEntity> assetsByDay;

  const WeekCalendar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.assetsByDay,
  });

  @override
  Widget build(BuildContext context) {
    // 日本語の曜日表示
    const weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

    // 期間表示用のフォーマッター
    final dateFormat = DateFormat('M月d日');
    final periodText =
        '${dateFormat.format(startDate)} 〜 ${dateFormat.format(endDate)}';

    // 週の日付を生成（日曜始まり）
    final List<DateTime> weekDays = [];
    for (int i = 0; i < 7; i++) {
      // 日曜日のインデックスは0
      final dayOfWeek = (i + 7) % 7; // 0=日曜, 1=月曜, ...

      // startDateから適切な日付を計算
      final dayOffset = dayOfWeek - startDate.weekday % 7;
      weekDays.add(startDate.add(Duration(days: dayOffset)));
    }

    return Column(
      children: [
        // 期間表示
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              periodText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 写真カルーセル
        SizedBox(
          height:
              MediaQuery.of(context).size.width * 0.75 / 7 * 4, // 3:4のアスペクト比
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: weekDays.map((date) {
              final weekdayIndex = date.weekday % 7; // 0=日曜, 1=月曜, ...
              final asset =
                  assetsByDay[DateTime(date.year, date.month, date.day)];

              // 各日付のカードの幅を画面幅の1/5程度に設定
              final cardWidth = MediaQuery.of(context).size.width / 5;

              return Container(
                width: cardWidth,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 曜日ラベル
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        weekdayLabels[weekdayIndex],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: weekdayIndex == 0
                              ? Colors.red
                              : weekdayIndex == 6
                                  ? Colors.blue
                                  : Colors.black54,
                        ),
                      ),
                    ),

                    // 写真表示部分
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 3 / 4, // 3:4のアスペクト比
                        child: asset != null
                            ? FutureBuilder<Uint8List?>(
                                future: asset.thumbnailDataWithSize(
                                  const ThumbnailSize(200, 267), // 3:4比率
                                  quality: 85,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 24),
      ],
    );
  }
}
