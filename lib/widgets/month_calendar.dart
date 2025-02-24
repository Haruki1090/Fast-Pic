import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MonthCalendar extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, AssetEntity> assetsByDay;

  const MonthCalendar({
    Key? key,
    required this.year,
    required this.month,
    required this.assetsByDay,
  }) : super(key: key);

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
      rowCells.add(_buildDayCell(date));

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

    return Column(
      children: [
        // 月のラベル
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "$year年 $month月",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // テーブルレイアウト
        Table(
          border: TableBorder(
            bottom: BorderSide(color: Colors.grey.shade300),
            horizontalInside: BorderSide(color: Colors.grey.shade200),
          ),
          children: calendarRows,
        ),
      ],
    );
  }

  /// ヘッダ行（日, 月, 火, 水, 木, 金, 土）
  List<Widget> _buildWeekdayHeaderCells() {
    // 日曜始まりの場合、index=0 -> 日, 1->月, 2->火, … 6->土
    const labels = ['日', '月', '火', '水', '木', '金', '土'];
    return labels
        .map(
          (label) => Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  /// 個々の日付セルを作る
  Widget _buildDayCell(DateTime date) {
    final asset = assetsByDay[DateTime(date.year, date.month, date.day)];

    // 正方形っぽくしたいので AspectRatio=1.0 にする
    return AspectRatio(
      aspectRatio: 1.0,
      child: asset != null
          ? FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                100 as ThumbnailSize,
                quality: 80,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Stack(
                    children: [
                      // 背景にサムネ
                      Positioned.fill(
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 日付文字
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${date.day}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
              child: Text("${date.day}"),
            ),
    );
  }
}
