import 'package:flutter/material.dart';

import 'drinks/drink_search_screen.dart';
import 'store/shop_list_screen.dart';

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
  // 0: お酒検索画面、1: お店検索画面
  int _currentIndex = 0;

  // 画面切り替えメソッド
  void switchToIndex(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // お酒検索画面に切り替え
  void switchToDrinkSearch() {
    switchToIndex(0);
  }

  // お店検索画面に切り替え
  void switchToShopSearch() {
    switchToIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // 白色背景
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // お酒検索画面
          DrinkSearchScreen(
            onSwitchToShopSearch: switchToShopSearch,
          ),
          // お店検索画面
          ShopListScreen(
            title: 'お店を探す',
            onSwitchToDrinkSearch: switchToDrinkSearch,
          ),
          // 将来的に追加する他画面もここに追加可能
        ],
      ),
    );
  }
}
