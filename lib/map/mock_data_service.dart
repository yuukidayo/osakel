import '../../../../models/shop.dart';
import '../../../../models/shop_with_price.dart';
import '../../../../models/drink_shop_link.dart';

/// モックデータ生成サービス
class MockDataService {
  /// モックデータを生成
  static List<ShopWithPrice> generateMockShops({String? drinkId}) {
    List<ShopWithPrice> mockShops = [];
    
    for (int i = 1; i <= 10; i++) {
      final shop = Shop(
        id: 'shop_$i',
        name: 'Shop $i',
        address: 'Tokyo, Japan',
        lat: 35.681236 + (i * 0.001),
        lng: 139.767125 + (i * 0.001),
        imageUrl: '',
      );
      
      final drinkShopLink = DrinkShopLink(
        id: 'link_$i',
        drinkId: drinkId ?? 'drink_1',
        shopId: shop.id,
        price: 500.0 + (i * 100),
        isAvailable: true,
        note: '',
      );
      
      mockShops.add(ShopWithPrice(shop: shop, drinkShopLink: drinkShopLink));
    }
    
    return mockShops;
  }
}
