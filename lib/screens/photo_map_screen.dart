import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:photo_manager/photo_manager.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../widgets/glass_photo_bottom_sheet.dart';

class PhotoMapScreen extends StatefulWidget {
  final Map<DateTime, AssetEntity> assetsByDay;

  const PhotoMapScreen({
    Key? key,
    required this.assetsByDay,
  }) : super(key: key);

  @override
  PhotoMapScreenState createState() => PhotoMapScreenState();
}

class PhotoMapScreenState extends State<PhotoMapScreen> {
  // 地図関連
  gm.GoogleMapController? _mapController;
  final Map<gm.MarkerId, gm.Marker> _markers = {};

  // 読み込み状態
  bool _isLoading = true;

  // 位置情報のキャッシュ
  final Map<String, gm.LatLng> _photoLocationCache = {};

  // 地図表示情報
  gm.LatLng _mapCenter = const gm.LatLng(35.6812, 139.7671); // デフォルトは東京
  double _mapZoom = 5.0;
  int _markerCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotoLocations();
  }

  // 写真の位置情報をロード
  Future<void> _loadPhotoLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 地図の中心位置を計算するための値
      double totalLat = 0;
      double totalLng = 0;
      int locationCount = 0;

      // 全ての写真を走査
      for (final entry in widget.assetsByDay.entries) {
        final date = entry.key;
        final asset = entry.value;

        // 位置情報がある写真のみ処理
        if (asset.latitude != 0 && asset.longitude != 0) {
          // キャッシュをチェック
          if (_photoLocationCache.containsKey(asset.id)) {
            _addMarker(asset, date, _photoLocationCache[asset.id]!);
            totalLat += _photoLocationCache[asset.id]!.latitude;
            totalLng += _photoLocationCache[asset.id]!.longitude;
            locationCount++;
          } else {
            final latLng = gm.LatLng(asset.latitude!, asset.longitude!);
            _photoLocationCache[asset.id] = latLng;
            _addMarker(asset, date, latLng);
            totalLat += asset.latitude!;
            totalLng += asset.longitude!;
            locationCount++;
          }
        }
      }

      // 位置情報がある写真がある場合、マップの中心を設定
      if (locationCount > 0) {
        _mapCenter =
            gm.LatLng(totalLat / locationCount, totalLng / locationCount);
        _mapZoom = locationCount == 1 ? 15.0 : 10.0;
        _markerCount = locationCount;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // マップが初期化されていれば中心位置を更新
        if (_mapController != null) {
          _updateMapCamera();
        }
      }
    } catch (e) {
      print('Error loading photo locations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // マーカーを追加
  void _addMarker(AssetEntity asset, DateTime date, gm.LatLng position) {
    final markerId = gm.MarkerId(asset.id);

    // 日付文字列を作成
    final dateStr = DateFormat('yyyy/MM/dd').format(date);

    // マーカーを作成
    final marker = gm.Marker(
      markerId: markerId,
      position: position,
      infoWindow: gm.InfoWindow(
        title: dateStr,
        snippet: DateFormat('HH:mm').format(asset.createDateTime),
      ),
      onTap: () {
        // マーカータップ時に写真を表示
        showDailyPhotosBottomSheet(
          context,
          date,
          asset,
        );
      },
    );

    setState(() {
      _markers[markerId] = marker;
    });
  }

  // 地図表示を更新
  void _updateMapCamera() {
    _mapController?.animateCamera(
      gm.CameraUpdate.newLatLngZoom(_mapCenter, _mapZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        title: const Text(
          '撮影場所マップ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '戻る',
        ),
      ),
      body: Stack(
        children: [
          // マップ表示
          gm.GoogleMap(
            initialCameraPosition: gm.CameraPosition(
              target: _mapCenter,
              zoom: _mapZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: true,
            markers: Set<gm.Marker>.of(_markers.values),
            onMapCreated: (gm.GoogleMapController controller) {
              _mapController = controller;

              if (!_isLoading) {
                _updateMapCamera();
              }
            },
          ),

          // 読み込み中インジケーター
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // インフォメーションパネル
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📷 位置情報のある写真: $_markerCount枚',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'マーカーをタップすると写真を閲覧できます',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
