import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../screens/category_list_screen.dart';

/// 管理者専用ルートを保護するガードウィジェット
class AdminGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const AdminGuard({
    Key? key,
    required this.child,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラーが発生しました: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final isAdmin = snapshot.data ?? false;

        if (isAdmin) {
          return child;
        } else {
          // 管理者でない場合はリダイレクト
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('管理者権限が必要です'),
                backgroundColor: Colors.red,
              ),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => fallbackWidget ?? const CategoryListScreen(),
              ),
            );
          });

          return const Scaffold(
            body: Center(
              child: Text('権限を確認中...'),
            ),
          );
        }
      },
    );
  }
}
