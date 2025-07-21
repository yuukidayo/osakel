import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      content: const Text('登録したメールアドレスに送信された認証メールから認証を完了してください。'),
      actions: [
        TextButton(
          onPressed: () async {
            // Resend verification email
            await user.sendEmailVerification();
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('認証メールを再送信しました'),
                backgroundColor: Colors.blue,
              ),
            );
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
