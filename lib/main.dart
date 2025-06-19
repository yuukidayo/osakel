import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/category_list_screen.dart';
import 'screens/subcategory_screen.dart';
import 'screens/drink_detail_screen.dart';
import 'screens/map_screen_fixed.dart' as map_screen;
import 'screens/shop_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

void main() async {
  // This must be called first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Initialize Firebase - simplified approach
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Firebaseの接続状態を確認
    final firestore = FirebaseFirestore.instance;
    print('Firestore instance created');
    
    try {
      // カテゴリコレクションの存在確認
      final categoriesSnapshot = await firestore.collection('categories').limit(1).get();
      print('Categories collection check: ${categoriesSnapshot.docs.isEmpty ? "Empty" : "Has data"}');
      
      // ドリンクコレクションの存在確認
      final drinksSnapshot = await firestore.collection('drinks').limit(1).get();
      print('Drinks collection check: ${drinksSnapshot.docs.isEmpty ? "Empty" : "Has data"}');
    } catch (firestoreError) {
      print('Error checking Firestore collections: $firestoreError');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // We'll continue even if Firebase fails
  }
  
  // Google Maps initialization is handled automatically by the plugin
  
  // Run the app
  runApp(const MyApp());
}

// Function removed as we now initialize Firebase directly in main()

/// 認証状態を監視し、適切な画面にルーティングするためのラッパー
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 認証状態の変更を監視
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // ユーザーがログインしている場合
        if (snapshot.hasData) {
          final user = snapshot.data;
          // メール認証が完了しているかチェック
          if (user != null && user.emailVerified) {
            // メール認証完了済み → カテゴリー一覧画面へ
            return const CategoryListScreen();
          } else {
            // メール認証未完了 → ログイン画面に戻して、そこでダイアログ表示
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // ログアウト
              FirebaseAuth.instance.signOut();
              
              // 認証未完了メッセージ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('メール認証を完了してからログインしてください'),
                  backgroundColor: Colors.orange,
                ),
              );
            });
            return const LoginScreen();
          }
        }
        
        // ユーザーがログインしていない場合はログイン画面へ
        return const LoginScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSAKEL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
        ),
      ),
      // 認証状態に基づいてホーム画面を表示
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        } else if (settings.name == '/signup') {
          return MaterialPageRoute(
            builder: (context) => const SignUpScreen(),
          );
        } else if (settings.name == '/forgot_password') {
          return MaterialPageRoute(
            builder: (context) => const ForgotPasswordScreen(),
          );
        } else if (settings.name == '/categories') {
          return MaterialPageRoute(
            builder: (context) => const CategoryListScreen(),
          );
        } else if (settings.name == '/subcategory') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SubcategoryScreen(category: args['category']),
          );
        } else if (settings.name == '/drink_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => DrinkDetailScreen(drinkId: args['drinkId']),
          );
        } else if (settings.name == '/map') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => map_screen.MapScreen(drinkId: args['drinkId']),
          );
        } else if (settings.name == '/shop_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ShopDetailScreen(shop: args['shop'], price: args['price']),
          );
        }
        return null;
      },
    );
  }
}
