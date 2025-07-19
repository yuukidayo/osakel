import 'package:flutter/material.dart';

/// マップ制御ボタンコンポーネント
/// 
/// 現在地、ズームイン、ズームアウト、検索ボタンを提供
class MapControlButtons extends StatelessWidget {
  final VoidCallback onCurrentLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onSearch;

  const MapControlButtons({
    Key? key,
    required this.onCurrentLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 現在位置ボタン
        FloatingActionButton.small(
          heroTag: 'location',
          onPressed: onCurrentLocation,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 4,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        
        // ズームインボタン
        FloatingActionButton.small(
          heroTag: 'zoomIn',
          onPressed: onZoomIn,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 4,
          child: const Icon(Icons.zoom_in),
        ),
        const SizedBox(height: 8),
        
        // ズームアウトボタン
        FloatingActionButton.small(
          heroTag: 'zoomOut',
          onPressed: onZoomOut,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 4,
          child: const Icon(Icons.zoom_out),
        ),
        const SizedBox(height: 8),
        
        // 検索ボタン
        FloatingActionButton.small(
          heroTag: 'search',
          onPressed: onSearch,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 4,
          child: const Icon(Icons.search),
        ),
      ],
    );
  }
}
