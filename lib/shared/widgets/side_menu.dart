import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../features/auth/screens/login_screen.dart';
// import '../../../features/admin/screens/add_drink_screen.dart'; // TODO: admin画面実装後に有効化

/// サイドメニューコンポーネント
/// 
/// ユーザープロフィール表示、通知一覧やお気に入りなどのメニュー項目、
/// およびログアウト機能を提供
class SideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final String userName;
  final String? profileImage;
  final int notificationCount;
  
  const SideMenu({
    Key? key,
    required this.onClose,
    required this.userName,
    this.profileImage,
    this.notificationCount = 0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // 画面幅の80%
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // プロフィールエリア
            _buildProfileSection(),
            
            const Divider(),
            
            // メニュー項目
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMenuItem(
                      Icons.notifications_outlined, 
                      '通知一覧', 
                      badge: notificationCount,
                    ),
                    _buildMenuItem(
                      Icons.search, 
                      'お酒検索',
                      onTap: () {
                        onClose();
                        Navigator.of(context).pushNamed('/drinks/search');
                      },
                    ),
                    _buildMenuItem(
                      Icons.wine_bar_outlined, 
                      'お気に入り お酒',
                    ),
                    _buildMenuItem(
                      Icons.store_outlined, 
                      'お気に入り お店',
                    ),
                    
                    // 管理者専用メニュー
                    FutureBuilder<bool>(
                      future: AuthService.isAdmin(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              const Divider(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: const Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      '管理者メニュー',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildMenuItem(
                                Icons.add_box_outlined,
                                'お酒登録',
                                onTap: () {
                                  onClose();
                                  // TODO: admin画面実装後に有効化
                                  // Navigator.of(context).push(
                                  //   MaterialPageRoute(
                                  //     builder: (context) => const AddDrinkScreen(),
                                  //   ),
                                  // );
                                },
                              ),
                              const Divider(),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    _buildMenuItem(
                      Icons.help_outline, 
                      'ヘルプ',
                    ),
                    _buildMenuItem(
                      Icons.description_outlined, 
                      '利用規約',
                    ),
                    _buildMenuItem(
                      Icons.logout_outlined, 
                      'ログアウト',
                      onTap: () => _handleLogout(context),
                    ),
                    _buildMenuItem(
                      Icons.delete_outline, 
                      'アカウント削除',
                      textColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 各メニュー項目のウィジェットを生成
  Widget _buildMenuItem(
    IconData icon, 
    String title, {
    int badge = 0, 
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge > 0 
        ? CircleAvatar(
            radius: 12,
            backgroundColor: Colors.black,
            child: Text(
              badge.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          )
        : null,
      onTap: onTap ?? () {
        // デフォルトの処理 - 将来的に実装
      },
    );
  }
  
  // プロフィールセクションのウィジェット
  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // プロフィール画像
          CircleAvatar(
            radius: 32,
            backgroundImage: profileImage != null && profileImage!.isNotEmpty 
                ? NetworkImage(profileImage!) 
                : null,
            backgroundColor: Colors.grey[300],
            child: profileImage == null || profileImage!.isEmpty 
                ? const Icon(Icons.person, size: 40, color: Colors.grey) 
                : null,
          ),
          const SizedBox(width: 16),
          // ユーザー名と編集ボタン
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // 編集ボタン
          ElevatedButton(
            onPressed: () {
              // プロフィール編集画面へ遷移（未実装）
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }
  
  // ログアウト処理
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // ロード中ダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Firebase Authからログアウト
      await FirebaseAuth.instance.signOut();
      
      // ダイアログを閉じる
      Navigator.of(context).pop();
      
      // サイドメニューを閉じる
      onClose();
      
      // ログイン画面に遷移（履歴をクリア）
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // すべての履歴をクリア
      );
    } catch (e) {
      // エラー処理
      Navigator.of(context).pop(); // ダイアログを閉じる
      
      // エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログアウトに失敗しました: ${e.toString()}')),
      );
    }
  }
}

/// サイドメニューをオーバーレイとして表示するためのユーティリティ関数
void showSideMenu(BuildContext context, {String userName = 'ゲスト', String? profileImage, int notificationCount = 0}) {
  // オーバーレイエントリを作成
  late final OverlayEntry overlay;
  
  overlay = OverlayEntry(
    builder: (context) {
      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 暗い背景（タップで閉じる）
            GestureDetector(
              onTap: () => overlay.remove(),
              child: Container(color: Colors.black54),
            ),
            
            // サイドメニューのアニメーション
            TweenAnimationBuilder<double>(
              tween: Tween(begin: -1.0, end: 0.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value * MediaQuery.of(context).size.width * 0.8, 0),
                  child: child,
                );
              },
              child: SideMenu(
                onClose: () => overlay.remove(),
                userName: userName,
                profileImage: profileImage,
                notificationCount: notificationCount,
              ),
            ),
          ],
        ),
      );
    },
  );
  
  // オーバーレイに追加
  Overlay.of(context).insert(overlay);
}
