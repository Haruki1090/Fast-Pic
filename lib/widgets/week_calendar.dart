import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import '../screens/daily_photos_screen.dart';

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
    final weekdayColors = [
      Colors.red.shade300, // 日曜
      Colors.black87, // 月曜
      Colors.black87, // 火曜
      Colors.black87, // 水曜
      Colors.black87, // 木曜
      Colors.black87, // 金曜
      Colors.blue.shade300, // 土曜
    ];

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // 期間表示
                  Padding(
                    padding: const EdgeInsets.all(8),
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
                    height: MediaQuery.of(context).size.width *
                        0.75 /
                        7 *
                        4, // 3:4のアスペクト比
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: weekDays.map((date) {
                        final weekdayIndex =
                            date.weekday % 7; // 0=日曜, 1=月曜, ...
                        final asset = assetsByDay[
                            DateTime(date.year, date.month, date.day)];

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
                                padding:
                                    const EdgeInsets.only(bottom: 4, left: 4),
                                child: Text(
                                  weekdayLabels[weekdayIndex],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: weekdayColors[weekdayIndex],
                                  ),
                                ),
                              ),

                              // 写真表示部分
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 3 / 4, // 3:4のアスペクト比
                                  child: GestureDetector(
                                    onTap: asset != null
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DailyPhotosScreen(
                                                  date: date,
                                                  highlightedAsset: asset,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    child: asset != null
                                        ? FutureBuilder<Uint8List?>(
                                            future: asset.thumbnailDataWithSize(
                                              const ThumbnailSize(
                                                  200, 267), // 3:4比率
                                              quality: 85,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                      ConnectionState.done &&
                                                  snapshot.hasData) {
                                                return Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Image.memory(
                                                        snapshot.data!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    // ガラスモーフィズム効果の日付表示
                                                    Positioned(
                                                      top: 4,
                                                      left: 4,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: BackdropFilter(
                                                          filter:
                                                              ImageFilter.blur(
                                                                  sigmaX: 4,
                                                                  sigmaY: 4),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.3),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.5),
                                                                  width: 0.5),
                                                            ),
                                                            child: Text(
                                                              "${date.day}",
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                shadows: [
                                                                  Shadow(
                                                                    color: Colors
                                                                        .black45,
                                                                    blurRadius:
                                                                        2,
                                                                    offset:
                                                                        Offset(
                                                                            1,
                                                                            1),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade200),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "${date.day}",
                                                style: TextStyle(
                                                  color: weekdayColors[
                                                      weekdayIndex],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
