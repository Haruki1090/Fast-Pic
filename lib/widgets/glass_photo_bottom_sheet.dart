import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import '../model/settings_repository.dart';

void showDailyPhotosBottomSheet(
  BuildContext context,
  DateTime date,
  AssetEntity highlightedAsset,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (context) => GlassPhotoBottomSheet(
      date: date,
      highlightedAsset: highlightedAsset,
    ),
  );
}

class GlassPhotoBottomSheet extends StatefulWidget {
  final DateTime date;
  final AssetEntity highlightedAsset;

  const GlassPhotoBottomSheet({
    Key? key,
    required this.date,
    required this.highlightedAsset,
  }) : super(key: key);

  @override
  GlassPhotoBottomSheetState createState() => GlassPhotoBottomSheetState();
}

class GlassPhotoBottomSheetState extends State<GlassPhotoBottomSheet>
    with TickerProviderStateMixin {
  late Future<List<AssetEntity>> _futureAssets;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  int _selectedIndex = -1;
  double _sheetHeight = 0.7; // 初期高さ（画面の70%）
  double _initialSheetHeight = 0.7;

  // シート展開時のアニメーション
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // サムネイルが現れるアニメーション
  late AnimationController _thumbnailsController;
  late Animation<double> _thumbnailsAnimation;

  // スクリーンショット判定結果のキャッシュ
  final Map<String, bool> _screenshotCache = {};

  @override
  void initState() {
    super.initState();
    _futureAssets = _fetchDailyAssets();

    // 展開アニメーション設定
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
    _expandController.forward();

    // サムネイルアニメーション設定
    _thumbnailsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _thumbnailsAnimation = CurvedAnimation(
      parent: _thumbnailsController,
      curve: Curves.easeOutQuart,
    );

    // 少し遅らせてサムネイルを表示
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _thumbnailsController.forward();
      }
    });

    // ハイライト表示する写真のインデックスを特定
    _futureAssets.then((assets) {
      if (mounted) {
        for (int i = 0; i < assets.length; i++) {
          if (assets[i].id == widget.highlightedAsset.id) {
            setState(() {
              _selectedIndex = i;
            });
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainScrollController.dispose();
    _expandController.dispose();
    _thumbnailsController.dispose();
    super.dispose();
  }

  // シートの高さを調整する関数
  void _toggleSheetHeight() {
    setState(() {
      if (_sheetHeight == _initialSheetHeight) {
        _sheetHeight = 0.95; // 拡大時（95%）
      } else {
        _sheetHeight = _initialSheetHeight; // 元のサイズに戻す
      }
    });
  }

  Future<List<AssetEntity>> _fetchDailyAssets() async {
    try {
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

      final List<AssetEntity> allAssets = [];

      // スクリーンショットアルバムを除外またはリストに含めるか
      for (final album in albums) {
        // スクリーンショットアルバムを判定（軽量判定）
        final isScreenshotAlbum = _isScreenshotAlbum(album);

        // スクリーンショットを表示しない設定で、スクリーンショットアルバムならスキップ
        if (!showScreenshots && isScreenshotAlbum) {
          continue;
        }

        // アルバムから全ての写真を取得
        final int assetCount = await album.assetCountAsync;
        if (assetCount == 0) continue;

        // 大きなアルバムは分割して処理（メモリ最適化）
        const int batchSize = 50;
        int processed = 0;

        while (processed < assetCount) {
          final int fetchCount = (processed + batchSize) > assetCount
              ? (assetCount - processed)
              : batchSize;

          final assets = await album.getAssetListRange(
            start: processed,
            end: processed + fetchCount,
          );

          if (!showScreenshots) {
            // スクリーンショットアルバムでなければ個別判定
            if (!isScreenshotAlbum) {
              for (final asset in assets) {
                if (!await _isScreenshotAssetLightweight(asset)) {
                  allAssets.add(asset);
                }
              }
            }
            // スクリーンショットアルバムなら全てスキップ
          } else {
            // 全ての写真を追加
            allAssets.addAll(assets);
          }

          processed += fetchCount;
        }
      }

      // 重複を除去
      final Map<String, AssetEntity> uniqueAssets = {};
      for (final asset in allAssets) {
        uniqueAssets[asset.id] = asset;
      }

      // 時間順にソート（古い順）
      final List<AssetEntity> sortedAssets = uniqueAssets.values.toList()
        ..sort((a, b) => a.createDateTime.compareTo(b.createDateTime));

      return sortedAssets;
    } catch (e) {
      print('Error fetching daily assets: $e');
      return [];
    }
  }

  // 他のヘルパーメソッド
  bool _isScreenshotAlbum(AssetPathEntity album) {
    final String albumName = album.name.toLowerCase();
    return albumName.contains('スクリーンショット') ||
        albumName.contains('screenshot') ||
        albumName.contains('screen shot');
  }

  Future<bool> _isScreenshotAssetLightweight(AssetEntity asset) async {
    // キャッシュをチェック
    if (_screenshotCache.containsKey(asset.id)) {
      return _screenshotCache[asset.id]!;
    }

    bool isScreenshot = false;

    // ファイル名による判定
    final String? title = asset.title?.toLowerCase();
    if (title != null) {
      if (title.contains('screenshot') ||
          title.contains('スクリーンショット') ||
          title.startsWith('screen') ||
          title.contains('capture')) {
        _screenshotCache[asset.id] = true;
        return true;
      }
    }

    // iOS標準のスクリーンショットサイズによる判定
    if (asset.width == 1170 ||
        asset.width == 1284 ||
        asset.width == 1080 ||
        asset.width == 1125) {
      _screenshotCache[asset.id] = true;
      return true;
    }

    // キャッシュに保存
    _screenshotCache[asset.id] = isScreenshot;
    return isScreenshot;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja_JP');
    final formattedDate = dateFormat.format(widget.date);
    // final size = MediaQuery.of(context).size; 使ってないのでコメントアウト

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return FractionallySizedBox(
          heightFactor: _sheetHeight * _expandAnimation.value,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              // 下方向へのスワイプで閉じる
              if (details.velocity.pixelsPerSecond.dy > 200) {
                Navigator.of(context).pop();
              }
            },
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.75),
                  Colors.white.withOpacity(0.65),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // ハンドルバー + ヘッダー
                _buildHeader(formattedDate),

                // メインコンテンツ
                Expanded(
                  child: FutureBuilder<List<AssetEntity>>(
                    future: _futureAssets,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('エラーが発生しました: ${snapshot.error}'),
                        );
                      }

                      final assets = snapshot.data ?? [];

                      if (assets.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_album_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'この日の写真はありません',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // メイン写真表示エリア
                          Expanded(
                            flex: 5,
                            child: _selectedIndex >= 0 &&
                                    _selectedIndex < assets.length
                                ? GestureDetector(
                                    onTap: _toggleSheetHeight,
                                    child: Hero(
                                      tag: 'photo_${assets[_selectedIndex].id}',
                                      child: _buildMainImageArea(
                                          assets[_selectedIndex]),
                                    ),
                                  )
                                : const Center(
                                    child: Text('写真を選択してください'),
                                  ),
                          ),

                          // 時間表示
                          if (_selectedIndex >= 0 &&
                              _selectedIndex < assets.length)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat('HH:mm').format(
                                        assets[_selectedIndex].createDateTime,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // サムネイルリスト
                          SizeTransition(
                            sizeFactor: _thumbnailsAnimation,
                            axisAlignment: 0.0,
                            child: Container(
                              height: 100,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: _buildThumbnailGrid(assets),
                            ),
                          ),
                        ],
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

  Widget _buildHeader(String formattedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // スワイプハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // 共有ボタン
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 22),
                    onPressed: _selectedIndex >= 0
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('共有機能は準備中です')),
                            );
                          }
                        : null,
                    tooltip: '共有',
                  ),
                  // 閉じるボタン
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '閉じる',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageArea(AssetEntity asset) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(
              ThumbnailSize(
                MediaQuery.of(context).size.width.toInt() * 2,
                MediaQuery.of(context).size.height.toInt(),
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
              return Container(
                color: Colors.grey[200]!.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailGrid(List<AssetEntity> assets) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: assets.length,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) {
        final asset = assets[index];
        final isSelected = index == _selectedIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(140, 140),
                        quality: 80,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            cacheWidth: 140,
                            cacheHeight: 140,
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
                          border: Border.all(
                            color: Colors.blue,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
