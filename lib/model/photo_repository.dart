import 'package:photo_manager/photo_manager.dart';

class PhotoRepository {
  static Future<Map<DateTime, AssetEntity>> fetchAssetsGroupedByDay() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      // 権限がない場合
      return {};
    }

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
}
