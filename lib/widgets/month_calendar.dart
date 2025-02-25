import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../screens/daily_photos_screen.dart';

class MonthCalendar extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, AssetEntity> assetsByDay;

  const MonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.assetsByDay,
  });

  @override
  Widget build(BuildContext context) {
    // 月初日
    final firstDayOfMonth = DateTime(year, month, 1);
    // 月の日数
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    // 週ラベル行
    final weekdayHeaderRow = TableRow(
      children: _buildWeekdayHeaderCells(),
    );

    // 以下で「月の実際の日付セル」を作る
    final List<TableRow> calendarRows = [];
    calendarRows.add(weekdayHeaderRow);

    // 1週間分を貯めるための一時配列
    List<Widget> rowCells = [];

    // 1日の曜日インデックス（日曜=0, 月曜=1, …, 土曜=6）
    // Dart の weekday: 月=1, 火=2, … 日=7 なので、 (weekday % 7) で日曜が0になる
    final firstDayWeekIndex = (firstDayOfMonth.weekday % 7);
    // firstDayWeekIndex = 0 → 1日は日曜
    // firstDayWeekIndex = 3 → 1日は水曜 (例)

    // 先に空セルを入れて、月初を正しい曜日列へ合わせる
    for (int i = 0; i < firstDayWeekIndex; i++) {
      rowCells.add(const SizedBox.shrink());
    }

    // 1日〜月末までループ
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      rowCells.add(_buildDayCell(context, date));

      // 7列埋まったら1行分として確定
      if (rowCells.length == 7) {
        calendarRows.add(TableRow(children: rowCells));
        rowCells = [];
      }
    }

    // 末日に達した後、週の残りがあれば空セルで埋める
    if (rowCells.isNotEmpty) {
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox.shrink());
      }
      calendarRows.add(TableRow(children: rowCells));
    }

    return Card(
      margin: const EdgeInsets.all(12),
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
                  // 月のラベル
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "$year年 $month月",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // テーブルレイアウト
                  Table(
                    border: TableBorder(
                      bottom: BorderSide(color: Colors.grey.shade200),
                      horizontalInside: BorderSide(color: Colors.grey.shade100),
                    ),
                    children: calendarRows,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダ行（日, 月, 火, 水, 木, 金, 土）
  List<Widget> _buildWeekdayHeaderCells() {
    // 日曜始まりの場合、index=0 -> 日, 1->月, 2->火, … 6->土
    const labels = ['日', '月', '火', '水', '木', '金', '土'];
    final colors = [
      Colors.red.shade300, // 日曜
      Colors.black54, // 月曜
      Colors.black54, // 火曜
      Colors.black54, // 水曜
      Colors.black54, // 木曜
      Colors.black54, // 金曜
      Colors.blue.shade300, // 土曜
    ];

    return List.generate(
        7,
        (index) => Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors[index],
                  ),
                ),
              ),
            ));
  }

  /// 個々の日付セルを作る
  Widget _buildDayCell(BuildContext context, DateTime date) {
    final asset = assetsByDay[DateTime(date.year, date.month, date.day)];

    // 縦長長方形にしたいので AspectRatio=3/4 にする
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: GestureDetector(
        onTap: asset != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailyPhotosScreen(
                      date: date,
                      highlightedAsset: asset,
                    ),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: asset != null
              ? FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(
                    const ThumbnailSize(128, 128),
                    quality: 80,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Stack(
                        children: [
                          // 背景にサムネ
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // ガラスモーフィズム効果の日付表示
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 0.5),
                                    ),
                                    child: Text(
                                      "${date.day}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            blurRadius: 2,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // 読み込み中など
                      return Center(child: Text("${date.day}"));
                    }
                  },
                )
              : Center(
                  child: Text(
                    "${date.day}",
                    style: TextStyle(
                      color: date.weekday % 7 == 0
                          ? Colors.red.shade300
                          : date.weekday % 7 == 6
                              ? Colors.blue.shade300
                              : Colors.black54,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
