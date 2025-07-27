import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpCompleteScreen extends StatelessWidget {
  final String email;

  const SignUpCompleteScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 成功アイコン
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // タイトル
                    const Text(
                      'アカウント登録完了！',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // サブタイトル
                    Text(
                      '$email\nにメール認証を送信しました',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 説明文
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF4A4A4A),
                            size: 28,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'メール認証を完了してください',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF2C2C2C),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '送信されたメールのリンクをタップして\nメール認証を完了してください。\n\n認証完了後、下のボタンから\nログインしてアプリをお楽しみください。',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // ログイン画面へのボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // ログイン画面に遷移
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'ログイン画面へ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // メール再送信ボタン（オプション）
              TextButton(
                onPressed: () {
                  // メール再送信の処理（必要に応じて実装）
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('メール認証を再送信しました'),
                      backgroundColor: Color(0xFF2C2C2C),
                    ),
                  );
                },
                child: const Text(
                  'メール認証を再送信',
                  style: TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
