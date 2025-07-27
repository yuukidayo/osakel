import 'package:flutter/material.dart';

/// マップ画面の「このエリアで再検索」ボタンコンポーネント
/// 
/// 検索状態に応じてローディング表示と通常表示を切り替える
class SearchAreaButton extends StatelessWidget {
  final bool isVisible;
  final bool isSearching;
  final VoidCallback? onPressed;

  const SearchAreaButton({
    super.key,
    required this.isVisible,
    required this.isSearching,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.39, // 0.3 × 1.3 = 0.39（39%）
          height: 36, // 28 × 1.3 ≈ 36
          child: ElevatedButton(
            onPressed: isSearching ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333), // 黒背景
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18), // 14 × 1.3 ≈ 18
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10), // 8 × 1.3 ≈ 10
            ),
            child: isSearching
                ? const SizedBox(
                    width: 16, // 12 × 1.3 ≈ 16
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, // 1.5 × 1.3 ≈ 2
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'このエリアで再検索',
                    style: TextStyle(
                      fontSize: 13, // 10 × 1.3 = 13
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}