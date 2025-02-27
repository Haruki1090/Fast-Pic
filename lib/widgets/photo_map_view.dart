import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import '../service/photo_location_service.dart';

class PhotoMapView extends StatefulWidget {
  final Map<DateTime, AssetEntity> assetsByDay;
  final VoidCallback onClose;
  final Function(AssetEntity asset, DateTime date) onMarkerTap;
  final Animation<double> animation;

  const PhotoMapView({
    Key? key,
    required this.assetsByDay,
    required this.onClose,
    required this.onMarkerTap,
    required this.animation,
  }) : super(key: key);

  @override
  PhotoMapViewState createState() => PhotoMapViewState();
}

class PhotoMapViewState extends State<PhotoMapView> {
  // 位置情報サービス
  final PhotoLocationService _locationService = PhotoLocationService();

  // 読み込み状態
  bool _isMapLoading = true;
  bool _isLoadingPhotoLocations = true;

  // マップ情報
  MapInfo? _mapInfo;

  @override
  void initState() {
    super.initState();
    // 写真の位置情報をロード
    _loadPhotoLocations();
  }

  // 写真の位置情報をロード
  Future<void> _loadPhotoLocations() async {
    setState(() {
      _isLoadingPhotoLocations = true;
    });

    // 位置情報サービスを使用してマーカーを作成
    final mapInfo = await _locationService.loadPhotoLocations(
      widget.assetsByDay,
      widget.onMarkerTap,
    );

    if (mounted) {
      setState(() {
        _mapInfo = mapInfo;
        _isLoadingPhotoLocations = false;
      });

      // マップコントローラーが初期化されていれば中心位置を更新
      if (_locationService.mapController != null) {
        _locationService.updateCameraPosition(mapInfo.center, mapInfo.zoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        // アニメーション値に応じてスクリーンの位置を計算
        return Positioned(
          top: MediaQuery.of(context).size.height * widget.animation.value,
          left: 0,
          right: 0,
          bottom: 0,
          child: child!,
        );
      },
      child: Stack(
        children: [
          // GoogleMap
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mapInfo?.center ??
                  const gm.LatLng(35.6812, 139.7671), // デフォルトは東京
              zoom: _mapInfo?.zoom ?? 5.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            markers: Set<gm.Marker>.of(_locationService.markers.values),
            onMapCreated: (GoogleMapController controller) {
              _locationService.mapController = controller;

              if (mounted) {
                setState(() {
                  _isMapLoading = false;
                });
              }

              // マップ情報が既に読み込まれていれば中心位置を更新
              if (_mapInfo != null) {
                _locationService.updateCameraPosition(
                    _mapInfo!.center, _mapInfo!.zoom);
              }
            },
          ),

          // 読み込み中インジケーター
          if (_isMapLoading || _isLoadingPhotoLocations)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // ヘッダー（ガラスモーフィズム）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '撮影場所マップ',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                          tooltip: '閉じる',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📷 位置情報のある写真: ${_mapInfo?.markerCount ?? 0}枚',
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
