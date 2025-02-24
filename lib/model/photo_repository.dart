import 'package:photo_manager/photo_manager.dart';

class PhotoRepository {
  static Future<Map<DateTime, AssetEntity>> fetchAssetsGroupedByDay() async {
    final Map<DateTime, AssetEntity> result = {};

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        print('Permission denied');
        return {};
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      print('Albums count: ${albums.length}');

      // フィルタリング一時無効化（デバッグ用）
      final filteredAlbums = albums;
      // .where((album) {
      //   final name = album.name.toLowerCase();
      //   return !name.contains('screenshot');
      // }).toList();

      print('Filtered albums count: ${filteredAlbums.length}');

      for (final album in filteredAlbums) {
        final assetCount = await album.assetCountAsync;
        print('Album "${album.name}" has $assetCount assets');

        if (assetCount == 0) continue;

        try {
          final assets =
              await album.getAssetListRange(start: 0, end: assetCount);
          print('Fetched ${assets.length} assets from "${album.name}"');

          for (final asset in assets) {
            final localDateTime = asset.createDateTime.toLocal();
            final createdAt = DateTime(
              localDateTime.year,
              localDateTime.month,
              localDateTime.day,
            );

            if (!result.containsKey(createdAt)) {
              result[createdAt] = asset;
            } else {
              final existing = result[createdAt]!;
              if (asset.createDateTime.isBefore(existing.createDateTime)) {
                result[createdAt] = asset;
              }
            }
          }
        } catch (e) {
          print('Error in album "${album.name}": $e');
        }
      }

      print('Total grouped assets: ${result.length}');
      return result;
    } catch (e) {
      print('Critical error in fetchAssetsGroupedByDay: $e');
      return {};
    }
  }
}
