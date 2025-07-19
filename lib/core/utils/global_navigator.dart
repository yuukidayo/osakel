import 'package:flutter/material.dart';

class GlobalNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  // 通知などからのルーティングを処理
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    if (navigator == null) {
      debugPrint('Navigator is null. Cannot navigate to $routeName');
      return Future.value(false);
    }
    return navigator!.pushNamed(routeName, arguments: arguments);
  }
  
  static Future<dynamic> navigateToShopDetail(String shopId) {
    return navigateTo('/shop-detail', arguments: {'shopId': shopId});
  }
  
  static Future<dynamic> navigateToDrinkDetail(String drinkId) {
    return navigateTo('/drink-detail', arguments: {'drinkId': drinkId});
  }
  
  static Future<dynamic> navigateToMap({String? shopId, String? drinkId}) {
    return navigateTo('/map', arguments: {'shopId': shopId, 'drinkId': drinkId});
  }
}
