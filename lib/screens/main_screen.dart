import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import 'drinks/drink_search_screen.dart';
import 'store/shop_search_screen.dart';
import 'notification/notification_test_screen.dart';
import '../providers/shared_category_provider.dart';

/// メイン画面コンテナ
/// IndexedStackを使用して各画面を管理し、切り替えのパフォーマンスを最適化する
class MainScreen extends StatefulWidget {
  static const String routeName = '/main';

  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 現在表示している画面のインデックス
  // 0: お酒検索画面、1: お店検索画面、2: 通知テスト画面
  int _currentIndex = 0;

  // 画面切り替えメソッド
  void switchToIndex(int index) {
    if (_currentIndex != index) {
      developer.log('画面切り替え: $_currentIndex → $index');
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // お酒検索画面に切り替え
  void switchToDrinkSearch() {
    developer.log('お酒検索画面へ切り替え');
    switchToIndex(0);
  }

  // お店検索画面に切り替え
  void switchToShopSearch() {
    developer.log('お店検索画面へ切り替え');
    switchToIndex(1);
  }
  
  // 通知テスト画面に切り替え
  void switchToNotificationTest() {
    switchToIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SharedCategoryProvider()..initialize(),
      child: Scaffold(
        backgroundColor: Colors.white, // 純白背景(#FFFFFF)に統一
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // お酒検索画面
            DrinkSearchScreen(
              onSwitchToShopSearch: switchToShopSearch,
            ),
            // お店検索画面
            ShopSearchScreen(
              onSwitchToDrinkSearch: () => switchToIndex(0),
            ),
            // 通知テスト画面
            const NotificationTestScreen(),
          ],
        ),
        // bottomNavigationBarを削除して非表示化
        // 画面切り替えは別の方法で行う必要があります
      ),
    );
  }
}
