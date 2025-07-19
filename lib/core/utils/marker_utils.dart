import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/shop_with_price.dart';
import '../../shared/widgets/price_marker.dart';

class MarkerUtils {
  // Maximum distance in meters to consider stores as clustered
  static const double CLUSTER_DISTANCE = 300.0;
  
  /// Converts a price to a formatted string (e.g., "¥5,000")
  static String formatPrice(double price) {
    return '¥${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Creates a custom marker with price
  static Future<BitmapDescriptor> createPriceMarker(double price, {bool isSelected = false}) async {
    return PriceMarker.createPriceMarker(price, isSelected: isSelected);
  }
  
  /// Creates a clustered marker with multiple prices
  static Future<BitmapDescriptor> createClusteredMarker(List<int> prices) async {
    return PriceMarker.createClusteredMarker(prices);
  }
  
  /// Calculate distance between two coordinates in meters
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - 
      math.cos(0.5 * (lat2 - lat1) * p) + 
      math.cos(lat1 * p) * math.cos(lat2 * p) * 
      (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a)); // 2 * R * asin(sqrt(a)), R = 6371 km
  }
  
  /// Group nearby shops into clusters (alias for compatibility)
  static List<List<ShopWithPrice>> clusterMarkers(List<ShopWithPrice> shops) {
    return clusterShops(shops);
  }

  /// Group nearby shops into clusters
  static List<List<ShopWithPrice>> clusterShops(List<ShopWithPrice> shops) {
    if (shops.isEmpty) return [];
    
    final List<List<ShopWithPrice>> clusters = [];
    final List<bool> processed = List.filled(shops.length, false);
    
    for (int i = 0; i < shops.length; i++) {
      if (processed[i]) continue;
      
      final List<ShopWithPrice> cluster = [shops[i]];
      processed[i] = true;
      
      for (int j = 0; j < shops.length; j++) {
        if (processed[j] || i == j) continue;
        
        final double distance = calculateDistance(
          shops[i].shop.lat, shops[i].shop.lng,
          shops[j].shop.lat, shops[j].shop.lng
        );
        
        if (distance <= CLUSTER_DISTANCE) {
          cluster.add(shops[j]);
          processed[j] = true;
        }
      }
      
      clusters.add(cluster);
    }
    
    return clusters;
  }
}
