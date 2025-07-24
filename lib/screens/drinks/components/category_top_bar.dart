import 'package:flutter/material.dart';
import '../../../shared/widgets/side_menu.dart' show showSideMenu;

class CategoryTopBar extends StatelessWidget {
  final String categoryDisplayName;
  final VoidCallback onCategoryTap;
  final VoidCallback onSwitchToShopSearch;
  final IconData switchIcon;

  const CategoryTopBar({
    super.key,
    required this.categoryDisplayName,
    required this.onCategoryTap,
    required this.onSwitchToShopSearch,
    this.switchIcon = Icons.storefront,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 左側のプロフィールアイコン
          GestureDetector(
            onTap: () {
              // サイドメニューを表示
              showSideMenu(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF8A8A8A)), // グレーアイコン
            ),
          ),
          
          // 中央のカテゴリ選択
          Expanded(
            child: Center(
              child: InkWell(
                onTap: onCategoryTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          
          // 右側の店舗表示への切り替えアイコン
          GestureDetector(
            onTap: onSwitchToShopSearch,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA), // 非常に薄いグレー背景
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDDDDD)), // 薄いグレー枠線
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    switchIcon,
                    size: 20,
                    color: const Color(0xFF333333), // ダークグレー
                  ),
                  // 右下に青い丸と右矢印を表示 (ショップリスト画面と統一感を持たせる)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF000000), // 黒色背景
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: Color(0xFFFFFFFF), // 白色アイコン
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
