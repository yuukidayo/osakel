import 'package:google_maps_flutter/google_maps_flutter.dart';

class PriceMarker {
  // Cache for markers to avoid recreating them
  static final Map<String, BitmapDescriptor> _markerCache = {};

  /// Creates a custom marker with price in Airbnb style
  static Future<BitmapDescriptor> createPriceMarker(double price, {bool isSelected = false}) async {
    // Create a cache key
    final String cacheKey = 'price_${price}_${isSelected ? 'selected' : 'normal'}';
    
    // Check if we already have this marker in cache
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }
    
    // Create custom marker based on price and selection state
    final BitmapDescriptor marker;
    
    if (isSelected) {
      // Selected marker (red with price in info window)
      marker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      // Regular marker (blue)
      marker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    
    // Store in cache
    _markerCache[cacheKey] = marker;
    return marker;
  }
  
  /// Creates a clustered marker with multiple prices
  static Future<BitmapDescriptor> createClusteredMarker(List<int> prices) async {
    if (prices.isEmpty) return BitmapDescriptor.defaultMarker;
    
    // Sort prices in descending order
    prices.sort((a, b) => b.compareTo(a));
    
    // Create a cache key
    final String cacheKey = 'cluster_${prices.first}_${prices.length}';
    
    // Check if we already have this marker in cache
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }
    
    // Cluster marker (yellow)
    final BitmapDescriptor marker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    
    // Store in cache
    _markerCache[cacheKey] = marker;
    return marker;
  }
  
  /// Formats a price with yen symbol and thousand separators
  static String formatPrice(double price) {
    return '¥${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    )}';
  }
}
