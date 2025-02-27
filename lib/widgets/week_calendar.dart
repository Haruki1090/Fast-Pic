import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import '../widgets/glass_photo_bottom_sheet.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 期間表示
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                  child: Text(
                    periodText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 写真カルーセル - パディング無し、画面全体使用
                SizedBox(
                  height: MediaQuery.of(context).size.width *
                      4 /
                      3 *
                      0.25, // 3:4のアスペクト比で高さ計算
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero, // パディング無し
                    itemCount: weekDays.length,
                    itemBuilder: (context, index) {
                      final date = weekDays[index];
                      final weekdayIndex = date.weekday % 7; // 0=日曜, 1=月曜, ...
                      final asset = assetsByDay[
                          DateTime(date.year, date.month, date.day)];

                      // 各日付のカードの幅を画面幅の1/5程度に設定
                      final cardWidth = MediaQuery.of(context).size.width / 5;

                      return Container(
                        width: cardWidth,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 曜日ラベル
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 2, left: 4),
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
                                aspectRatio: 3 / 4, // 強制的に3:4比率
                                child: GestureDetector(
                                  onTap: asset != null
                                      ? () {
                                          showDailyPhotosBottomSheet(
                                            context,
                                            date,
                                            asset,
                                          );
                                        }
                                      : null,
                                  child: asset != null
                                      ? FutureBuilder<Uint8List?>(
                                          future: _getOptimizedThumbnail(asset),
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
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      cacheWidth:
                                                          200, // キャッシュサイズを指定
                                                      cacheHeight: 267,
                                                    ),
                                                  ),
                                                  // ガラスモーフィズム効果の日付表示
                                                  Positioned(
                                                    top: 4,
                                                    left: 4,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 4,
                                                                sigmaY: 4),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
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
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              shadows: [
                                                                Shadow(
                                                                  color: Colors
                                                                      .black45,
                                                                  blurRadius: 2,
                                                                  offset:
                                                                      Offset(
                                                                          1, 1),
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
                                            } else if (snapshot
                                                    .connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                              );
                                            } else {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                                color:
                                                    weekdayColors[weekdayIndex],
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // メモリ効率のよいサムネイル取得方法
  Future<Uint8List?> _getOptimizedThumbnail(AssetEntity asset) async {
    // 画像のアスペクト比情報を取得（メタデータから）
    final aspectRatio = await _getAssetAspectRatio(asset);

    // アスペクト比に基づいて適切なサムネイルサイズを決定
    if (aspectRatio > 1.0) {
      // 横長の場合
      return asset.thumbnailDataWithSize(
        const ThumbnailSize(267, 200), // 横長用サイズ
        quality: 80,
      );
    } else {
      // 縦長または正方形の場合
      return asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 267), // 縦長用サイズ
        quality: 80,
      );
    }
  }

  // アセットのアスペクト比を取得する（width / height）
  Future<double> _getAssetAspectRatio(AssetEntity asset) async {
    // 画像の詳細情報をメタデータから取得
    final width = asset.width;
    final height = asset.height;

    // 0 除算を防ぐ
    if (height == 0) return 1.0;

    return width / height;
  }
}
