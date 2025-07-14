import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/category_list_screen.dart';
import 'screens/subcategory_screen.dart';
import 'screens/drink_detail_screen.dart';
import 'screens/store/map_screen_fixed.dart' as map_screen;
import 'screens/store/shop_detail_screen.dart';
import 'screens/drinks/drink_search_screen.dart';
import 'screens/drinks/providers/drink_search_notifier.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_screen.dart';
import 'services/push_notification_service.dart';
import 'utils/global_navigator.dart';
// MainScreenをメイン画面として使用するように変更

// バックグラウンドでのプッシュ通知処理用ハンドラー
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンド通知受信時の先行処理
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

/// アプリケーションのエントリーポイント
Future<void> main() async {
  // Flutter初期化（必須の最初のステップ）
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized');
  
  // 画面の向きを縦に固定
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  print('Screen orientation set to portrait');
  
  // Firebaseの初期化（アプリ全体で使用するため先に初期化）
  bool firebaseInitialized = false;
  
  try {
    // Firebase初期化（プラットフォーム固有の設定を使用）
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('✅ Firebase initialized successfully');
    
    // バックグラウンドメッセージハンドラーの設定
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Firebase background message handler set');
    
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    // Firebaseの初期化に失敗しても、アプリの起動は継続
  }
  
  // アプリを起動し、初期化状態を渡す
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
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
            // メール認証完了済み → MainScreen画面へ変更
            return const MainScreen();
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

class MyApp extends StatefulWidget {
  final bool firebaseInitialized;
  
  const MyApp({super.key, required this.firebaseInitialized});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Firebaseが正しく初期化された場合のみ、プッシュ通知サービスを初期化
    if (widget.firebaseInitialized) {
      print('Firebase is initialized, setting up push notifications');
      _initializePushNotifications();
    } else {
      print('⚠️ Firebase is not initialized, skipping push notifications setup');
    }
  }
  
  // プッシュ通知の初期化処理
  Future<void> _initializePushNotifications() async {
    // Firebaseの初期化を確認
    if (!Firebase.apps.isNotEmpty) {
      print('⚠️ Firebase apps not found, trying to initialize again');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase re-initialized successfully in MyApp');
      } catch (e) {
        print('❌ Failed to initialize Firebase in MyApp: $e');
        return; // Firebaseの初期化に失敗した場合は、通知初期化をスキップ
      }
    }
    
    // プッシュ通知サービスの初期化を実行
    try {
      await PushNotificationService().init();
      print('✅ Push notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing push notifications: $e');
      // プッシュ通知の初期化に失敗してもアプリは継続
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onSurface: Color(0xFF000000),   // 表面上のテキスト
          background: Color(0xFFFFFFFF),  // 背景色
          onBackground: Color(0xFF000000),// 背景上のテキスト
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
        // ダイアログ関連の設定
        // Flutter バージョンによりDialogThemeとDialogThemeDataの互換性の問題があるため、
        // 個別のプロパティとして設定
        dialogBackgroundColor: const Color(0xFFFFFFFF),
        // ボトムシートテーマ
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          surfaceTintColor: Color(0xFFFFFFFF),
        ),
        // スナックバーテーマ
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF000000),
          contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
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
