import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// マップビューコンポーネント
/// 
/// GoogleMapの表示とマーカー管理を担当
class MapView extends StatelessWidget {
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback? onCameraIdle;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool mapToolbarEnabled;
  final bool zoomControlsEnabled;

  // 東京駅を中心とした初期カメラ位置
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 15,
  );

  const MapView({
    Key? key,
    required this.markers,
    required this.onMapCreated,
    this.onCameraIdle,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.mapToolbarEnabled = false,
    this.zoomControlsEnabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: markers,
        myLocationEnabled: myLocationEnabled,
        myLocationButtonEnabled: myLocationButtonEnabled,
        mapToolbarEnabled: mapToolbarEnabled,
        zoomControlsEnabled: zoomControlsEnabled,
        onMapCreated: onMapCreated,
        onCameraMove: (_) {},
        onCameraIdle: onCameraIdle,
      ),
    );
  }
}
