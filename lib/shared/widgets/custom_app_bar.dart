import 'package:flutter/material.dart';

/// カスタムヘッダーコンポーネント
/// 
/// 左側のハンバーガーメニューは現在非表示、中央にOSAKELロゴ、右側にプロフィールアイコン
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;
  
  const CustomAppBar({
    super.key,
    required this.onProfileTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // デフォルトの戻るボタンを非表示
      title: Column(
        children: [
          const Text(
            'OSAKEL', 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Colors.black
            ),
          ),
          const Text(
            'オサケル', 
            style: TextStyle(
              fontSize: 14, 
              color: Colors.black45
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        // プロフィールアイコン
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          onPressed: onProfileTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
