import 'package:photo_manager/photo_manager.dart';
import 'settings_repository.dart';

class PhotoRepository {
  // スクリーンショット判定結果のキャッシュ
  static final Map<String, bool> _screenshotCache = {};

  static Future<Map<DateTime, AssetEntity>> fetchAssetsGroupedByDay() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      // 権限がない場合
      return {};
    }

    // スクリーンショット表示設定を取得
    final showScreenshots = await SettingsRepository.getShowScreenshots();

    // 写真のみを取得
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    final Map<DateTime, AssetEntity> assetsByDay = {};

    // メモリ使用量を削減するために処理を分割
    for (final album in albums) {
      // スクリーンショットのアルバム判定（軽量処理）
      final isScreenshotAlbum = _isScreenshotAlbum(album);

      // スクリーンショットを表示しない設定で、スクリーンショットアルバムならスキップ
      if (!showScreenshots && isScreenshotAlbum) {
        continue;
      }

      final assetCount = await album.assetCountAsync;
      if (assetCount == 0) continue;

      // 大きなアルバムは分割して処理する（1回あたり最大50枚に削減）
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

        // 各アセットをその撮影日で分類
        for (final asset in assets) {
          // スクリーンショットをフィルタリング
          if (!showScreenshots) {
            // アルバムがスクリーンショットアルバムなら自動的にスキップ
            if (isScreenshotAlbum) {
              continue;
            }

            // 個別の写真判定（軽量バージョン）
            if (await _isScreenshotAssetLightweight(asset)) {
              continue;
            }
          }

          final dateTime = asset.createDateTime;
          final dateOnly =
              DateTime(dateTime.year, dateTime.month, dateTime.day);

          // 既存のアセットがない場合のみ追加（各日1枚のみ保持）
          if (!assetsByDay.containsKey(dateOnly)) {
            assetsByDay[dateOnly] = asset;
          }
        }

        // バッチ処理後にキャッシュを整理
        if (_screenshotCache.length > 1000) {
          _screenshotCache.clear();
        }

        processed += fetchCount;
      }
    }

    return assetsByDay;
  }

  // アルバム名からスクリーンショットアルバムかどうかを判定（軽量処理）
  static bool _isScreenshotAlbum(AssetPathEntity album) {
    final String albumName = album.name.toLowerCase();
    return albumName.contains('スクリーンショット') ||
        albumName.contains('screenshot') ||
        albumName.contains('screen shot');
  }

  // 軽量なスクリーンショット判定（ファイル名と基本属性のみ）
  static Future<bool> _isScreenshotAssetLightweight(AssetEntity asset) async {
    // キャッシュをチェック
    if (_screenshotCache.containsKey(asset.id)) {
      return _screenshotCache[asset.id]!;
    }

    bool isScreenshot = false;

    // 1. ファイル名による判定（基本的な判定・軽量）
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

    // 2. iOS標準のスクリーンショットサイズによる判定（軽量）
    // 特定の解像度はスクリーンショットの可能性が高い
    if (asset.width == 1170 || // iPhone 12/13 サイズ
        asset.width == 1284 || // iPhone 12/13 Pro Max サイズ
        asset.width == 1080 || // iPhone 11 サイズ
        asset.width == 1125) {
      // iPhone X/XS/11 Pro サイズ
      _screenshotCache[asset.id] = true;
      return true;
    }

    // 3. 関連属性による軽量判定
    // iOSのスクリーンショットはGPS情報が含まれない
    if (asset.latitude == 0 && asset.longitude == 0) {
      // さらにExifの特別な属性が欠落していることが多い
      final String? mimeType = asset.mimeType?.toLowerCase();
      // スクリーンショットは通常PNG形式
      if (mimeType != null && mimeType.contains('png')) {
        isScreenshot = true;
      }
    }

    // キャッシュに保存
    _screenshotCache[asset.id] = isScreenshot;
    return isScreenshot;
  }
}
