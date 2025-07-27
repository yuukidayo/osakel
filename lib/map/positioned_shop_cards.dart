import 'package:flutter/material.dart';
import '../../../../models/shop_with_price.dart';
import 'shop_card_page_view.dart';

/// マップ画面下部に固定表示される店舗カードコンポーネント
/// 
/// Positionedラッパーを含む完全なレイアウトコンポーネント
class PositionedShopCards extends StatelessWidget {
  final List<ShopWithPrice> shops;
  final PageController pageController;
  final void Function(int index) onPageChanged;
  final void Function(ShopWithPrice shopWithPrice) onShopTap;

  const PositionedShopCards({
    super.key,
    required this.shops,
    required this.pageController,
    required this.onPageChanged,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 30, // 下部に30pxのマージンを追加
      left: 0,
      right: 0,
      height: 300, // カードの高さを固定
      child: Stack(
        children: [
          // 店舗カードページビュー
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: ShopCardPageView(
              shops: shops,
              controller: pageController,
              onPageChanged: onPageChanged,
              onShopTap: onShopTap,
            ),
          ),
        ],
      ),
    );
  }
}