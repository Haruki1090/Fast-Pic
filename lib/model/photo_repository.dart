import 'package:photo_manager/photo_manager.dart';

class PhotoRepository {
  /// スクリーンショット除外 & 同日複数枚の際は「一番最初に撮影された」ものを優先
  /// key: 日付(yyyy-MM-dd レベルに丸めた DateTime)
  /// value: 代表の1枚 (AssetEntity)
  static Future<Map<DateTime, AssetEntity>> fetchAssetsGroupedByDay() async {
    final Map<DateTime, AssetEntity> result = {};

    // パーミッションリクエスト
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      // 許可されない場合は空を返す
      return {};
    }

    // 画像アルバム一覧を取得
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // スクリーンショット用アルバムの除外 (名称に 'screenshot' が含まれる場合)
    final filteredAlbums = albums.where((album) {
      final name = album.name.toLowerCase();
      return !name.contains('screenshot');
    }).toList();

    for (final album in filteredAlbums) {
      final assetCount = await album.assetCountAsync;
      // 全アセットを取得 (多い場合パフォーマンス注意)
      final assets = await album.getAssetListRange(start: 0, end: assetCount);

      for (final asset in assets) {
        final createdAt = DateTime(
          asset.createDateTime.year,
          asset.createDateTime.month,
          asset.createDateTime.day,
        );

        // 初回なら登録。既存があれば「より早い時間のもの」を優先
        if (!result.containsKey(createdAt)) {
          result[createdAt] = asset;
        } else {
          final existing = result[createdAt]!;
          if (asset.createDateTime.isBefore(existing.createDateTime)) {
            result[createdAt] = asset;
          }
        }
      }
    }

    return result;
  }
}
