import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SaunaFacility {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String? imageUrl;
  final double saunaTemperature;
  final double waterBathTemperature;
  final double? distance; // 現在地からの距離（km）

  SaunaFacility({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    this.imageUrl,
    required this.saunaTemperature,
    required this.waterBathTemperature,
    this.distance,
  });

  factory SaunaFacility.fromMap(String id, Map<String, dynamic> data) {
    // 位置情報の処理
    double lat = 0.0;
    double lng = 0.0;
    
    try {
      if (data['location'] != null) {
        // GeoPoint型の場合
        if (data['location'] is GeoPoint) {
          final geoPoint = data['location'] as GeoPoint;
          lat = geoPoint.latitude;
          lng = geoPoint.longitude;
        }
        // Map型の場合
        else if (data['location'] is Map) {
          final location = data['location'] as Map<dynamic, dynamic>;
          lat = (location['lat'] is num) ? (location['lat'] as num).toDouble() : 0.0;
          lng = (location['lng'] is num) ? (location['lng'] as num).toDouble() : 0.0;
        }
      }
    } catch (e) {
      debugPrint('位置情報の処理エラー: $e');
    }
    
    return SaunaFacility(
      id: id,
      name: data['name'] ?? '',
      lat: lat,
      lng: lng,
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'],
      saunaTemperature: (data['saunaTemperature'] ?? 90.0).toDouble(),
      waterBathTemperature: (data['waterBathTemperature'] ?? 15.0).toDouble(),
      distance: data['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': {
        'lat': lat,
        'lng': lng,
      },
      'address': address,
      'imageUrl': imageUrl,
      'saunaTemperature': saunaTemperature,
      'waterBathTemperature': waterBathTemperature,
    };
  }

  // 現在地からの距離を計算して新しいインスタンスを返す
  SaunaFacility copyWithDistance(double distance) {
    return SaunaFacility(
      id: id,
      name: name,
      lat: lat,
      lng: lng,
      address: address,
      imageUrl: imageUrl,
      saunaTemperature: saunaTemperature,
      waterBathTemperature: waterBathTemperature,
      distance: distance,
    );
  }
}
