import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:typed_data';

import '../model/settings_repository.dart';

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

      // スクリーンショット表示設定を取得
      final showScreenshots = await SettingsRepository.getShowScreenshots();

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

      if (albums.isEmpty) {
        return [];
      }

      // 最初のアルバムから全ての写真を取得
      final assets = await albums.first.getAssetListRange(
        start: 0,
        end: 1000, // 十分大きな数
      );

      // スクリーンショットフィルタリング
      final filteredAssets = assets.where((asset) {
        if (!showScreenshots && _isScreenshot(asset)) {
          return false;
        }
        return true;
      }).toList();

      // 時間順にソート（古い順）
      filteredAssets
          .sort((a, b) => a.createDateTime.compareTo(b.createDateTime));

      return filteredAssets;
    } catch (e) {
      print('Error fetching daily assets: $e');
      return [];
    }
  }

  // スクリーンショット判定
  bool _isScreenshot(AssetEntity asset) {
    final String? title = asset.title?.toLowerCase();
    if (title == null) return false;

    return title.contains('screenshot') ||
        title.contains('スクリーンショット') ||
        title.startsWith('screen') ||
        title.contains('capture') ||
        title.startsWith('img_') && title.length > 20;
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
                              child:
                                  _buildMainImageArea(assets[_selectedIndex]),
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
                        child: _buildThumbnailGrid(assets),
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

  Widget _buildThumbnailGrid(List<AssetEntity> assets) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: assets.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FutureBuilder<Uint8List?>(
                        // 小さいサムネイルに変更
                        future: asset.thumbnailDataWithSize(
                          const ThumbnailSize(160, 160),
                          quality: 80,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              cacheWidth: 160,
                              cacheHeight: 160,
                            );
                          }
                          return Container(color: Colors.grey[200]);
                        },
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 3),
                            borderRadius: BorderRadius.circular(10),
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

  Widget _buildMainImageArea(AssetEntity asset) {
    return Expanded(
      child: Center(
        child: FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(
            // フル解像度ではなく、画面サイズに合わせた適切なサイズに
            ThumbnailSize(
              MediaQuery.of(context).size.width.toInt() *
                  2, // 2倍の解像度（Retinaディスプレイ対応）
              MediaQuery.of(context).size.height.toInt() * 2,
            ),
            quality: 90,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
