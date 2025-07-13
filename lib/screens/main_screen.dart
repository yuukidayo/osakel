import 'package:flutter/material.dart';

import 'drinks/drink_search_screen.dart';
import 'store/shop_list_screen.dart';
import 'notification/notification_test_screen.dart';

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
  
  // 通知テスト画面に切り替え
  void switchToNotificationTest() {
    switchToIndex(2);
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
          // 通知テスト画面
          const NotificationTestScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: switchToIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF8A8A8A),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_bar),
            label: 'お酒を探す',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'お店を探す',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '通知テスト',
          ),
        ],
      ),
    );
  }
}
