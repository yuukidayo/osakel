import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String? imageUrl;
  final String? imageURL; // 大文字のimageURLフィールドを追加
  final List<String> imageUrls; // 画像URL配列フィールドを追加
  final String? category;
  final String? distance;
  final String? openTime;

  Shop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    this.imageUrl,
    this.imageURL, // 大文字のimageURLフィールドを追加
    this.imageUrls = const [], // 画像URL配列フィールド（デフォルト空配列）
    this.category,
    this.distance,
    this.openTime,
  });

  factory Shop.fromMap(String id, Map<String, dynamic> data) {
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
          debugPrint('GeoPoint形式の位置情報: lat=$lat, lng=$lng');
        }
        // Map型の場合（古いデータ形式との互換性のため）
        else if (data['location'] is Map) {
          final location = data['location'] as Map<dynamic, dynamic>;
          lat = (location['lat'] is num) ? (location['lat'] as num).toDouble() : 0.0;
          lng = (location['lng'] is num) ? (location['lng'] as num).toDouble() : 0.0;
          debugPrint('Map形式の位置情報: lat=$lat, lng=$lng');
        }
      }
    } catch (e) {
      debugPrint('位置情報の処理エラー: $e');
    }
    
    // デバッグ出力
    debugPrint('データ全体: $data');
    debugPrint('imageUrlフィールド: ${data['imageUrl']}');
    debugPrint('imageURLフィールド: ${data['imageURL']}');
    
    // imageUrls配列の処理
    List<String> imageUrls = [];
    if (data['imageUrls'] != null) {
      if (data['imageUrls'] is List) {
        imageUrls = List<String>.from(data['imageUrls']);
      }
    }
    
    return Shop(
      id: id,
      name: data['name'] ?? '',
      lat: lat,
      lng: lng,
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'],
      imageURL: data['imageURL'], // 大文字のimageURLフィールドを追加
      imageUrls: imageUrls, // 画像URL配列フィールドを追加
      category: data['category'],
      distance: data['distance'],
      openTime: data['openTime'],
    );
  }
  
  // FirestoreのDocumentSnapshotからShopオブジェクトを作成するファクトリーメソッド
  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shop.fromMap(doc.id, data);
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
      'imageURL': imageURL, // 大文字のimageURLフィールドを追加
      'imageUrls': imageUrls, // 画像URL配列フィールドを追加
      'category': category,
      'distance': distance,
      'openTime': openTime,
    };
  }
  
  /// JSONへ変換（toMapと同じだがidを含む）
  Map<String, dynamic> toJson() {
    final map = toMap();
    map['id'] = id;
    return map;
  }
  
  /// JSONからShopオブジェクトを生成
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['location']?['lat'] ?? 0.0).toDouble(),
      lng: (json['location']?['lng'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      imageUrl: json['imageUrl'],
      imageURL: json['imageURL'],
      category: json['category'],
      distance: json['distance'],
      openTime: json['openTime'],
    );
  }
}
