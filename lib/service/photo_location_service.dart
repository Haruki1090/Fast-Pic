import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

// 写真の位置情報を管理するサービスクラス
class PhotoLocationService {
  // シングルトンパターンを使用
  static final PhotoLocationService _instance =
      PhotoLocationService._internal();

  factory PhotoLocationService() => _instance;

  PhotoLocationService._internal();

  // 位置情報のキャッシュ
  final Map<String, gm.LatLng> _photoLocationCache = {};

  // マーカー情報
  final Map<gm.MarkerId, gm.Marker> _markers = {};

  // マップコントローラー
  gm.GoogleMapController? mapController;

  // マーカー情報を取得
  Map<gm.MarkerId, gm.Marker> get markers => _markers;

  // マーカーをクリア
  void clearMarkers() {
    _markers.clear();
  }

  // 写真の位置情報をロードしてマーカーを作成
  Future<MapInfo> loadPhotoLocations(
    Map<DateTime, AssetEntity> assetsByDay,
    Function(AssetEntity asset, DateTime date) onMarkerTap,
  ) async {
    // マーカーをクリア
    clearMarkers();

    // 地図の中心位置を計算するための値
    double totalLat = 0;
    double totalLng = 0;
    int locationCount = 0;

    try {
      // 全ての写真を走査
      for (final entry in assetsByDay.entries) {
        final date = entry.key;
        final asset = entry.value;

        // 位置情報がある写真のみ処理
        if (asset.latitude != 0 && asset.longitude != 0) {
          // キャッシュをチェック
          if (_photoLocationCache.containsKey(asset.id)) {
            _addMarker(
              asset,
              date,
              _photoLocationCache[asset.id]!,
              onMarkerTap,
            );
            totalLat += _photoLocationCache[asset.id]!.latitude;
            totalLng += _photoLocationCache[asset.id]!.longitude;
            locationCount++;
          } else {
            final latLng = gm.LatLng(asset.latitude!, asset.longitude!);
            _photoLocationCache[asset.id] = latLng;
            _addMarker(asset, date, latLng, onMarkerTap);
            totalLat += asset.latitude!;
            totalLng += asset.longitude!;
            locationCount++;
          }
        }
      }

      // 地図の中心とズームレベルを計算
      gm.LatLng center = const gm.LatLng(35.6812, 139.7671); // デフォルトは東京
      double zoom = 5.0;

      if (locationCount > 0) {
        center = gm.LatLng(totalLat / locationCount, totalLng / locationCount);

        // 写真が1枚だけの場合は高いズームレベル
        zoom = locationCount == 1 ? 15.0 : 10.0;
      }

      return MapInfo(center: center, zoom: zoom, markerCount: locationCount);
    } catch (e) {
      debugPrint('Error loading photo locations: $e');
      return MapInfo(
        center: const gm.LatLng(35.6812, 139.7671),
        zoom: 5.0,
        markerCount: locationCount,
      );
    }
  }

  // マーカーを追加
  void _addMarker(AssetEntity asset, DateTime date, gm.LatLng position,
      Function(AssetEntity asset, DateTime date) onMarkerTap) {
    final markerId = gm.MarkerId(asset.id);

    // サムネイル画像を取得（オプション、高度な実装の場合）
    // この例ではデフォルトのマーカーアイコンを使用

    // マーカーを作成
    final marker = gm.Marker(
      markerId: markerId,
      position: position,
      infoWindow: gm.InfoWindow(
        title: '${date.year}/${date.month}/${date.day}',
        snippet: '${asset.createDateTime.hour}:${asset.createDateTime.minute}',
      ),
      onTap: () {
        onMarkerTap(asset, date);
      },
    );

    _markers[markerId] = marker;
  }

  // マップの表示領域を更新
  void updateCameraPosition(gm.LatLng center, double zoom) {
    mapController?.animateCamera(
      gm.CameraUpdate.newLatLngZoom(center, zoom),
    );
  }
}

// マップ情報を格納するデータクラス
class MapInfo {
  final gm.LatLng center;
  final double zoom;
  final int markerCount;

  MapInfo({
    required this.center,
    required this.zoom,
    required this.markerCount,
  });
}
