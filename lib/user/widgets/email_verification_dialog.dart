import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class EmailVerificationDialog extends StatelessWidget {
  final User user;

  const EmailVerificationDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メール認証が未完了です'),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              // Resend verification email
              developer.log('認証メール再送信開始: ${user.email}');
              await user.sendEmailVerification();
              developer.log('✅ 認証メール再送信成功: ${user.email}');
              if (!context.mounted) return;
              Navigator.pop(context);
            } catch (e) {
              developer.log('❌ 認証メール再送信エラー: $e');
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: const Text('認証メールを再送信'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  /// Show email verification dialog and handle sign out
  static Future<void> showEmailVerificationDialog(
    BuildContext context,
    User user,
    FirebaseAuth auth,
  ) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => EmailVerificationDialog(user: user),
    );
    
    // Sign out since email is not verified
    await auth.signOut();
  }
}
