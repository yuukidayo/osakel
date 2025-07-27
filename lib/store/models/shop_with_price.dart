import './shop.dart';
import '../../drink/models/drink_shop_link.dart';

class ShopWithPrice {
  final Shop shop;
  final DrinkShopLink drinkShopLink;
  final double distance; // 現在地からの距離（km）

  ShopWithPrice({
    required this.shop,
    required this.drinkShopLink,
    this.distance = 0.0,
  });
  
  /// JSONへ変換
  Map<String, dynamic> toJson() => {
    'shop': shop.toJson(),
    'drinkShopLink': drinkShopLink.toJson(),
    'distance': distance,
  };
  
  /// JSONからオブジェクトを生成
  factory ShopWithPrice.fromJson(Map<String, dynamic> json) => ShopWithPrice(
    shop: Shop.fromJson(json['shop']),
    drinkShopLink: DrinkShopLink.fromJson(json['drinkShopLink']),
    distance: (json['distance'] ?? 0.0).toDouble(),
  );
  
  /// 距離付きでコピーを作成
  ShopWithPrice copyWithDistance(double newDistance) => ShopWithPrice(
    shop: shop,
    drinkShopLink: drinkShopLink,
    distance: newDistance,
  );
}
