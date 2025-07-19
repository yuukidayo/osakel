import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/shop_with_price.dart';

import '../../../../core/services/firestore_service.dart';
import 'mock_data_service.dart';

/// マップデータ管理サービス
class MapDataService {
  final FirestoreService _firestoreService = FirestoreService();

  /// 店舗データを読み込み
  Future<List<ShopWithPrice>> loadShopsData({String? drinkId}) async {
    try {
      List<ShopWithPrice> shops = [];
      
      if (drinkId != null) {
        // ドリンクIDから関連する店舗を取得
        final drinkShopLinks = await _firestoreService.getDrinkShopLinks(drinkId);
        
        for (var link in drinkShopLinks) {
          final shop = await _firestoreService.getShop(link.shopId);
          if (shop != null) {
            shops.add(ShopWithPrice(shop: shop, drinkShopLink: link));
          }
        }
      }
      
      // データが取得できなかった場合はモックデータを返す
      if (shops.isEmpty) {
        return MockDataService.generateMockShops(drinkId: drinkId);
      }
      
      return shops;
    } catch (e) {
      // エラー時はモックデータを返す
      return MockDataService.generateMockShops(drinkId: drinkId);
    }
  }

  /// 初期フォーカス処理
  Future<void> performInitialFocus({
    required List<ShopWithPrice> shops,
    required Completer<GoogleMapController> mapController,
    required PageController pageController,
    required Function(ShopWithPrice) onShopSelected,
  }) async {
    if (shops.isNotEmpty) {
      final firstShop = shops.first;
      
      // 先頭店舗を選択状態にする
      onShopSelected(firstShop);
      
      // マップコントローラが利用可能になるまで待機
      final controller = await mapController.future;
      
      // 先頭店舗の位置にカメラを移動
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstShop.shop.lat, firstShop.shop.lng),
            zoom: 15.0,
          ),
        ),
      );
      
      // PageViewも先頭に設定
      if (pageController.hasClients) {
        pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}
