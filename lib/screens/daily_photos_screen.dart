import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class DailyPhotosScreen extends StatefulWidget {
  final DateTime date;
  final AssetEntity? highlightedAsset;

  const DailyPhotosScreen({
    super.key,
    required this.date,
    this.highlightedAsset,
  });

  @override
  DailyPhotosScreenState createState() => DailyPhotosScreenState();
}

class DailyPhotosScreenState extends State<DailyPhotosScreen> {
  late Future<List<AssetEntity>> _futureAssets;
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _futureAssets = _fetchDailyAssets();

    // ハイライト表示する写真がある場合、そのインデックスを特定
    if (widget.highlightedAsset != null) {
      _futureAssets.then((assets) {
        for (int i = 0; i < assets.length; i++) {
          if (assets[i].id == widget.highlightedAsset!.id) {
            setState(() {
              _selectedIndex = i;
            });
            break;
          }
        }
      });
    }
  }

  Future<List<AssetEntity>> _fetchDailyAssets() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        return [];
      }

      // 指定された日付の開始と終了
      final startTime = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      );
      final endTime = startTime.add(const Duration(days: 1));

      // 日付でフィルタリングしたアルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          createTimeCond: DateTimeCond(
            min: startTime,
            max: endTime,
          ),
        ),
      );

      final List<AssetEntity> allAssets = [];

      for (final album in albums) {
        final assetCount = await album.assetCountAsync;
        if (assetCount == 0) continue;

        final assets = await album.getAssetListRange(start: 0, end: assetCount);
        allAssets.addAll(assets);
      }

      // 時間順にソート
      allAssets.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));

      return allAssets;
    } catch (e) {
      print('Error fetching daily assets: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja_JP');
    final formattedDate = dateFormat.format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: _selectedIndex >= 0
                ? () {
                    // 共有機能の実装
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('共有機能は準備中です')),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景にわずかなグラデーション効果
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
          ),

          FutureBuilder<List<AssetEntity>>(
            future: _futureAssets,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              }

              final assets = snapshot.data ?? [];

              if (assets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_album_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'この日の写真はありません',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // 大きな写真表示エリア
                  Expanded(
                    flex: 3,
                    child: _selectedIndex >= 0 && _selectedIndex < assets.length
                        ? GestureDetector(
                            onTap: () {
                              // 全画面表示などの機能を追加可能
                            },
                            child: Hero(
                              tag: 'photo_${assets[_selectedIndex].id}',
                              child: AssetEntityImage(
                                assets[_selectedIndex],
                                isOriginal: true,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              '写真をタップして表示',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                  ),

                  // 時間表示
                  if (_selectedIndex >= 0 && _selectedIndex < assets.length)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Text(
                              DateFormat('HH:mm').format(
                                  assets[_selectedIndex].createDateTime),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // サムネイルリスト
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 110,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          border: Border(
                            top: BorderSide(
                                color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: assets.length,
                          itemBuilder: (context, index) {
                            final asset = assets[index];
                            final isSelected = index == _selectedIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              child: Container(
                                width: 80,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AssetEntityImage(
                                          asset,
                                          isOriginal: false,
                                          thumbnailSize:
                                              const ThumbnailSize(200, 200),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.blue, width: 3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // 時間軸表示
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        child: assets.length > 1
                            ? _buildTimelineSlider(assets)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSlider(List<AssetEntity> assets) {
    // 最初と最後の時間を取得
    final firstTime = assets.first.createDateTime;
    final lastTime = assets.last.createDateTime;

    // 全体の時間範囲（分単位）
    final totalMinutes = lastTime.difference(firstTime).inMinutes.toDouble();
    if (totalMinutes <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('HH:mm').format(firstTime)),
            Text(DateFormat('HH:mm').format(lastTime)),
          ],
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: Colors.blue.withOpacity(0.7),
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
              thumbColor: Colors.blue,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: Colors.blue.withOpacity(0.1),
            ),
            child: Slider(
              min: 0,
              max: assets.length - 1.0,
              divisions: assets.length > 1 ? assets.length - 1 : 1,
              value: _selectedIndex >= 0 ? _selectedIndex.toDouble() : 0,
              onChanged: (value) {
                setState(() {
                  _selectedIndex = value.round();
                  // サムネイルリストでも選択位置を表示
                  _scrollToSelectedThumbnail();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _scrollToSelectedThumbnail() {
    if (_selectedIndex >= 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        _selectedIndex * 88.0, // サムネイルの幅+マージン
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
