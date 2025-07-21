import 'package:flutter/material.dart';

class SignUpCompleteScreen extends StatelessWidget {
  final String email;
  
  const SignUpCompleteScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // #FFFFFF
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12), // 12px rounded corners effect
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // 16px safe-area padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success Icon - 80×80 px circle with light green background
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), // Very light green background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Color(0xFF388E3C), // Medium green check mark
                  ),
                ),
                
                const SizedBox(height: 24), // 24px vertical gap below icon
                
                // Title - 「登録が完了しました！」
                const Text(
                  '登録が完了しました！',
                  style: TextStyle(
                    fontSize: 24, // 24sp
                    fontWeight: FontWeight.w600, // Semi-bold
                    color: Color(0xFF000000), // #000
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12), // 12px gap between title and first line
                
                // Body Message - First line
                const Text(
                  '登録したメールアドレス宛に確認メールを送信しました。',
                  style: TextStyle(
                    fontSize: 16, // 16sp
                    fontWeight: FontWeight.normal, // Regular
                    color: Color(0xFF333333), // #333
                    height: 1.5, // line-height 24px (24/16 = 1.5)
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12), // 12px gap between the two lines
                
                // Body Message - Second line
                const Text(
                  'メール内のリンクをクリックして認証を完了してから、アプリをお楽しみください。',
                  style: TextStyle(
                    fontSize: 16, // 16sp
                    fontWeight: FontWeight.normal, // Regular
                    color: Color(0xFF333333), // #333
                    height: 1.5, // line-height 24px (24/16 = 1.5)
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40), // Extra spacing for better visual balance
                
                // Email confirmation display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // Light gray background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFCCCCCC), // #CCC border
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: Color(0xFF666666), // #666
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666), // #666
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
