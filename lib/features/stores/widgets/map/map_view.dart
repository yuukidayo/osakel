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
    Key? key,
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
  }) : super(key: key);

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
