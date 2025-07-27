import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// マップビューコンポーネント
/// 
/// GoogleMapの表示とマーカー管理を担当
class MapView extends StatelessWidget {
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback? onCameraIdle;
  final Function(CameraPosition)? onCameraMove;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool mapToolbarEnabled;
  final bool zoomControlsEnabled;
  final CameraPosition? initialCameraPosition;
  final bool isLoading;

  // デフォルトの初期カメラ位置（東京駅）
  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 15,
  );

  const MapView({
    super.key,
    required this.markers,
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

  /// Airbnb風マップスタイル
  /// 水域: 明るいティール/アクアブルー (#B3E5FC)
  /// 陸地: 非常に薄いベージュ/クリーム (#FAFAF9)
  /// 道路: ソフトなグレー (#E8E8E8)
  /// 公園: 薄いミントグリーン (#E8F5E8)
  /// 建物: 極薄グレー (#F5F5F5)
  static const String _airbnbMapStyle = '''
[
  {
    "featureType": "water",
    "stylers": [
      {
        "color": "#B3E5FC"
      }
    ]
  },
  {
    "featureType": "landscape",
    "stylers": [
      {
        "color": "#FAFAF9"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "stylers": [
      {
        "color": "#FAFAF9"
      }
    ]
  },
  {
    "featureType": "landscape.man_made",
    "stylers": [
      {
        "color": "#F5F5F5"
      }
    ]
  },
  {
    "featureType": "road",
    "stylers": [
      {
        "color": "#E8E8E8"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "stylers": [
      {
        "color": "#E0E0E0"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "stylers": [
      {
        "color": "#E8E8E8"
      }
    ]
  },
  {
    "featureType": "road.local",
    "stylers": [
      {
        "color": "#EEEEEE"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#E0E0E0"
      },
      {
        "weight": 0.5
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text",
    "stylers": [
      {
        "color": "#9E9E9E"
      },
      {
        "weight": 0.4
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text",
    "stylers": [
      {
        "color": "#757575"
      },
      {
        "weight": 0.5
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "stylers": [
      {
        "color": "#BDBDBD"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "on"
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
    "stylers": [
      {
        "color": "#E8F5E8"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "simplified"
      },
      {
        "color": "#7CB342"
      }
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "poi.attraction",
    "stylers": [
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "poi.government",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.medical",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.place_of_worship",
    "stylers": [
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "poi.school",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.sports_complex",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: isLoading
          ? _buildLoadingView()
          : GoogleMap(
              initialCameraPosition: initialCameraPosition ?? _defaultCameraPosition,
              markers: markers,
              myLocationEnabled: myLocationEnabled,
              myLocationButtonEnabled: myLocationButtonEnabled,
              mapToolbarEnabled: mapToolbarEnabled,
              zoomControlsEnabled: zoomControlsEnabled,
              style: _airbnbMapStyle,
              onMapCreated: onMapCreated,
              onCameraMove: onCameraMove,
              onCameraIdle: onCameraIdle,
      ),
    );
  }

  /// 現在地取得中のローディング表示
  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              '📍 現在地を取得中...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'マップを読み込んでいます',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
