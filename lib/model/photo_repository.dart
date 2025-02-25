import 'package:photo_manager/photo_manager.dart';
import 'settings_repository.dart';

class PhotoRepository {
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
      final assetCount = await album.assetCountAsync;
      if (assetCount == 0) continue;

      // 大きなアルバムは分割して処理する（1回あたり最大100枚）
      const int batchSize = 100;
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
          if (!showScreenshots && _isScreenshot(asset)) {
            continue; // スクリーンショットを表示しない設定ならスキップ
          }

          final dateTime = asset.createDateTime;
          final dateOnly =
              DateTime(dateTime.year, dateTime.month, dateTime.day);

          // 既存のアセットがない場合のみ追加（各日1枚のみ保持）
          if (!assetsByDay.containsKey(dateOnly)) {
            assetsByDay[dateOnly] = asset;
          }
        }

        processed += fetchCount;
      }
    }

    return assetsByDay;
  }

  // スクリーンショットかどうかを判定するヘルパーメソッド
  static bool _isScreenshot(AssetEntity asset) {
    // ファイル名に基づく判定（iOS/Androidの一般的なスクリーンショット命名規則）
    final String? title = asset.title?.toLowerCase();
    if (title == null) return false;

    return title.contains('screenshot') ||
        title.contains('スクリーンショット') ||
        title.startsWith('screen') ||
        title.contains('capture') ||
        // iOS特有の命名パターン
        title.startsWith('img_') && title.length > 20;
  }
}
