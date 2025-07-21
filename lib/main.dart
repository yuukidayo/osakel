import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'screens/category_list_screen.dart';
import 'screens/subcategory_screen.dart';
import 'features/drinks/screens/drink_detail_screen.dart';
import 'features/stores/screens/map_screen_fixed.dart' as map_screen;
import 'features/stores/screens/shop_detail_screen.dart';
import 'screens/drinks/drink_search_screen.dart';
import 'screens/drinks/providers/drink_search_notifier.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'screens/main_screen.dart';
import 'core/utils/global_navigator.dart';

import 'core/services/fcm_service.dart';

/// バックグラウンド通知を処理するグローバルハンドラ
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase Core初期化を必要とする処理は避ける
  print('📱 バックグラウンドメッセージ受信: ${message.messageId}');
}

/// アプリケーションのエントリーポイント - シンプルに標準的な初期化順序に修正
Future<void> main() async {
  // 1. Flutter初期化（必須の最初のステップ）
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized');
  
  // 2. 画面の向きを縦に固定
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // 3. FCMバックグラウンドハンドラを登録 (Firebase初期化前に必要)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 4. Firebaseを初期化
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 初期化成功の確認
    firebaseInitialized = Firebase.apps.isNotEmpty;
    print('Firebase initialized: $firebaseInitialized');
    
    // 5. FCMサービスの初期化
    if (firebaseInitialized) {
      try {
        await FCMService().initialize();
        print('FCM service initialized');
      } catch (e) {
        print('FCM service initialization error: $e');
      }
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // 6. アプリを起動
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

/// 認証状態を監視し、適切な画面にルーティングするためのラッパー
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
            // メール認証完了済み → MainScreen画面へ変更
            return const MainScreen();
          } else {
            // メール認証未完了 → ログイン画面に戻す
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // ログアウト
              FirebaseAuth.instance.signOut();
              
              // 認証未完了をログ出力のみ（SnackBar削除）
              developer.log('メール認証未完了のためログアウトしました');
            });
            return const LoginScreen();
          }
        }
        
        // 未ログイン状態
        return const LoginScreen();
      },
    );
  }
}

class MyApp extends StatefulWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, required this.firebaseInitialized});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
    
    // FCMトークン更新リスナーの設定
    if (widget.firebaseInitialized) {
      FCMService().setupTokenRefreshListener((token) {
        print('FCMトークン更新: $token');
        // ここでトークンをFirestoreなどに保存するロジックを追加可能
      });
    }
  }

  Future<void> _initializeApp() async {
    // システム全体のUI設定のみ - Firebaseは初期化済みなのでここでは不要
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // アプリの基本設定とデザイン
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrinkSearchNotifier()),
      ],
      child: MaterialApp(
        title: 'OSAKEL',
        debugShowCheckedModeBanner: false,
        navigatorKey: GlobalNavigator.navigatorKey, // グローバルナビゲーションキー設定
        theme: ThemeData(
          // モノトーンデザインのベースカラー定義
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF000000),     // メインブラック
            onPrimary: Color(0xFFFFFFFF),   // ホワイト（プライマリ上のテキスト等）
            secondary: Color(0xFF333333),   // ダークグレー
            onSecondary: Color(0xFFFFFFFF), // ダークグレー上のテキスト
            surface: Color(0xFFFFFFFF),     // 表面の色（カード背景等）
            onSurface: Color(0xFF000000),// 背景上のテキスト
            error: Color(0xFF000000),       // エラーカラー（モノトーンに合わせて黒に）
            onError: Color(0xFFFFFFFF),     // エラーカラー上のテキスト
            outline: Color(0xFF8A8A8A),     // アウトライン（グレー）
          ),
          // Material 3を有効化
          useMaterial3: true,
          // アプリバーのテーマ設定
          appBarTheme: const AppBarTheme(
            foregroundColor: Color(0xFFFFFFFF),  // テキスト・アイコンは白
            backgroundColor: Color(0xFF000000),  // 背景は黒
            elevation: 0,                        // 影なし（フラットデザイン）
          ),
          // ボタンテーマ（ElevatedButton）
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000000),     // 黒背景
              foregroundColor: const Color(0xFFFFFFFF),     // 白テキスト
              elevation: 0,                                 // 影なし
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),      // 角を少し丸く
              ),
            ),
          ),
          // テキストボタン
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF000000),     // 黒テキスト
            ),
          ),
          // アウトラインボタン
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF000000),     // 黒テキスト
              side: const BorderSide(color: Color(0xFF000000)), // 黒い枠線
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),      // 角を少し丸く
              ),
            ),
          ),
          // 入力フィールド
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],                    // 薄いグレー背景
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,                  // 枠線なし
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF000000)), // フォーカス時は黒枠
            ),
          ),
          // テキストテーマ
          textTheme: const TextTheme(
            // 見出し
            headlineLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
            headlineMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
            headlineSmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
            // 本文
            bodyLarge: TextStyle(color: Color(0xFF000000)),
            bodyMedium: TextStyle(color: Color(0xFF000000)),
            bodySmall: TextStyle(color: Color(0xFF8A8A8A)),  // 小さいテキストは薄いグレー
          ),
          // ボトムシートテーマ
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFFFFFFFF),
            surfaceTintColor: Color(0xFFFFFFFF),
          ),
          // スナックバーテーマ
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF000000),
            contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
          ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFFFFFFF)),
        ),
        // FirebaseDebugWidgetをbuilderパターンで統合
        builder: (context, child) {
          // FirebaseDebugWidgetを一時的に無効化
          return child ?? const SizedBox();
          
          // 元のコード (問題解決後に復活可能)
          // return FirebaseDebugWidget(
          //   child: child ?? const SizedBox(),
          //   showInProduction: false, // 本番環境では表示しない
          // );
        },
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
          } else if (settings.name == DrinkSearchScreen.routeName) {
            return MaterialPageRoute(
              builder: (context) => const DrinkSearchScreen(),
            );
          } else if (settings.name == MainScreen.routeName) {
            return MaterialPageRoute(
              builder: (context) => const MainScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}
