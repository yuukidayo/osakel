import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/shop_with_price.dart';
import '../../../../core/utils/ultra_high_quality_marker_generator.dart';

/// 最高画質マーカー対応マップビュー（業界標準）
class UltraQualityMapView extends StatefulWidget {
  final List<ShopWithPrice> shopsWithPrices;
  final ShopWithPrice? selectedShop;
  final Function(ShopWithPrice) onMarkerTap;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback? onCameraIdle;
  final Function(CameraPosition)? onCameraMove;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool mapToolbarEnabled;
  final bool zoomControlsEnabled;
  final CameraPosition? initialCameraPosition;
  final bool isLoading;

  // デフォルト初期位置（東京駅）
  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 15,
  );

  const UltraQualityMapView({
    super.key,
    required this.shopsWithPrices,
    required this.selectedShop,
    required this.onMarkerTap,
    required this.onMapCreated,
    this.onCameraIdle,
    this.onCameraMove,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.mapToolbarEnabled = false,
    this.zoomControlsEnabled = false,
    this.initialCameraPosition,
    this.isLoading = false,
  });

  @override
  State<UltraQualityMapView> createState() => _UltraQualityMapViewState();
}

class _UltraQualityMapViewState extends State<UltraQualityMapView> {
  Set<Marker> _markers = {};
  bool _isGeneratingMarkers = false;

  @override
  void initState() {
    super.initState();
    _generateUltraQualityMarkers();
  }

  @override
  void didUpdateWidget(UltraQualityMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shopsWithPrices != widget.shopsWithPrices ||
        oldWidget.selectedShop != widget.selectedShop) {
      _generateUltraQualityMarkers();
    }
  }

  @override
  void dispose() {
    // メモリ効率のためキャッシュクリア
    UltraHighQualityMarkerGenerator.clearCache();
    super.dispose();
  }

  /// 最高画質マーカーを生成（パフォーマンス最適化済み）
  Future<void> _generateUltraQualityMarkers() async {
    if (_isGeneratingMarkers) return;
    
    setState(() {
      _isGeneratingMarkers = true;
    });

    final newMarkers = <Marker>{};
    
    // 並列処理で高速化
    final futures = widget.shopsWithPrices.map((shopWithPrice) async {
      try {
        final isSelected = widget.selectedShop?.shop.id == shopWithPrice.shop.id;
        
        // 最高画質マーカー生成（キャッシュ活用）
        final markerIcon = await UltraHighQualityMarkerGenerator.createCachedMarker(
          price: shopWithPrice.drinkShopLink.price,
          isSelected: isSelected,
        );

        return Marker(
          markerId: MarkerId(shopWithPrice.shop.id),
          position: LatLng(shopWithPrice.shop.lat, shopWithPrice.shop.lng),
          icon: markerIcon,
          onTap: () => widget.onMarkerTap(shopWithPrice),
          anchor: const Offset(0.5, 0.5), // 完璧な中央アンカー
          consumeTapEvents: true, // タップイベント最適化
        );
      } catch (e) {
        debugPrint('マーカー生成エラー: ${shopWithPrice.shop.name} - $e');
        return null;
      }
    });

    final results = await Future.wait(futures);
    
    for (final marker in results) {
      if (marker != null) {
        newMarkers.add(marker);
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _isGeneratingMarkers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: widget.isLoading
          ? _buildLoadingView()
          : GoogleMap(
              initialCameraPosition: widget.initialCameraPosition ?? 
                  UltraQualityMapView._defaultCameraPosition,
              onMapCreated: (controller) {
                widget.onMapCreated(controller);
                
                // 最高画質設定を適用
                _applyUltraQualitySettings(controller);
              },
              onCameraMove: widget.onCameraMove,
              onCameraIdle: widget.onCameraIdle,
              markers: _markers,
              myLocationEnabled: widget.myLocationEnabled,
              myLocationButtonEnabled: widget.myLocationButtonEnabled,
              mapToolbarEnabled: widget.mapToolbarEnabled,
              zoomControlsEnabled: widget.zoomControlsEnabled,
              style: _ultraQualityMapStyle, // 最高画質マップスタイル
              
              // パフォーマンス最適化設定
              liteModeEnabled: false, // フル機能モード
              compassEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false, // 3D効果無効でパフォーマンス向上
              
              // マーカー最適化（カスタムマーカーでパフォーマンス重視）
            ),
    );
  }

  /// 最高画質設定をマップに適用
  void _applyUltraQualitySettings(GoogleMapController controller) {
    // 地図の画質設定は自動で最適化される
    // カスタムマーカーが既に最高画質なので追加設定不要
  }

  /// 現在地取得中のローディング表示
  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey[50], // より上品な背景色
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF222222)),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              '📍 現在地を取得中...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '最高画質でマップを読み込んでいます',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 最高画質Airbnb風マップスタイル
  static const String _ultraQualityMapStyle = '''
[
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#C8E6F5"
      }
    ]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#FCFCFC"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#F8F9FA"
      }
    ]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#F5F5F5"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#FFFFFF"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#E8E8E8"
      },
      {
        "weight": 1
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#FFFFFF"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#DADADA"
      },
      {
        "weight": 1.2
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#E8F5E8"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "labels.text",
    "stylers": [
      {
        "color": "#666666"
      },
      {
        "weight": 0.8
      }
    ]
  }
]
''';
}