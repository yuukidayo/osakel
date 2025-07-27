import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'drink/screens/category_list_screen.dart';
import 'drink/screens/subcategory_screen.dart';
import 'drink/screens/drink_detail_screen.dart';
import 'map/map_screen_fixed.dart' as map_screen;
import 'store/screens/shop_detail_screen.dart';
import 'drink/screens/drink_search_screen.dart';
import 'drink/widgets/drink_search_notifier.dart';
import 'user/screens/login_screen.dart';
import 'user/screens/signup_screen.dart';
import 'user/screens/forgot_password_screen.dart';
import 'shared/screens/main_screen.dart';
import 'core/utils/global_navigator.dart';

import 'core/services/fcm_service.dart';

/// バックグラウンド通知を処理するグローバルハンドラ
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase Core初期化を必要とする処理は避ける
  debugPrint('📱 バックグラウンドメッセージ受信: ${message.messageId}');
}

/// アプリケーションのエントリーポイント - シンプルに標準的な初期化順序に修正
Future<void> main() async {
  // 1. Flutter初期化（必須の最初のステップ）
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Flutter binding initialized');
  
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
    debugPrint('Firebase initialized: $firebaseInitialized');
    
    // 5. FCMサービスの初期化
    if (firebaseInitialized) {
      try {
        await FCMService().initialize();
        debugPrint('FCM service initialized');
      } catch (e) {
        debugPrint('FCM service initialization error: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  // 6. アプリを起動
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

/// 認証状態を監視し、適切な画面にルーティングするためのラッパー
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // アプリライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);
    developer.log('🔄 AuthWrapper初期化 - ライフサイクル監視開始');
  }

  @override
  void dispose() {
    // アプリライフサイクル監視を停止
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      developer.log('📱 アプリがフォアグラウンドに復帰 - 認証状態を再確認');
      _checkAuthenticationStateOnResume();
    }
  }

  /// アプリ復帰時の認証状態確認
  Future<void> _checkAuthenticationStateOnResume() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        developer.log('🔄 アプリ復帰時のユーザー状態再読み込み: ${user.email}');
        await user.reload();
        
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          developer.log('✅ アプリ復帰時にメール認証確認 - 状態更新');
          // StreamBuilderが自動的に再構築されてMainScreenに遷移する
        }
      } catch (e) {
        developer.log('❌ アプリ復帰時のユーザー状態確認エラー: $e');
      }
    }
  }

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
            developer.log('✅ メール認証完了済み - MainScreenへ遷移: ${user.email}');
            return const MainScreen();
          } else {
            // メール認証未完了の場合、ユーザー状態を再読み込みして再確認
            developer.log('🔄 メール認証未完了 - ユーザー状態再読み込み中: ${user?.email}');
            return FutureBuilder<void>(
              future: _reloadUserAndCheck(user),
              builder: (context, reloadSnapshot) {
                if (reloadSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('認証状態を確認中...'),
                        ],
                      ),
                    ),
                  );
                }
                
                // 再読み込み後もメール未認証の場合はログアウト
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FirebaseAuth.instance.signOut();
                  developer.log('❌ メール認証未完了のためログアウトしました');
                });
                return const LoginScreen();
              },
            );
          }
        }
        
        // 未ログイン状態
        return const LoginScreen();
      },
    );
  }

  /// ユーザー状態を再読み込みして認証状態を再確認
  Future<void> _reloadUserAndCheck(User? user) async {
    if (user == null) return;
    
    try {
      developer.log('🔄 ユーザー状態再読み込み開始: ${user.email}');
      await user.reload();
      
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser != null) {
        developer.log('📧 再読み込み後の認証状態: emailVerified=${updatedUser.emailVerified}');
        
        if (updatedUser.emailVerified) {
          developer.log('✅ 再読み込み後にメール認証確認 - 画面更新をトリガー');
          // 認証状態が更新された場合、StreamBuilderが自動的に再構築される
        }
      }
    } catch (e) {
      developer.log('❌ ユーザー状態再読み込みエラー: $e');
    }
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
        debugPrint('FCMトークン更新: $token');
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
        // 日本語ローカライゼーション設定（強制的に日本語に設定）
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ja', 'JP'), // 日本語
          Locale('en', 'US'), // 英語（フォールバック）
        ],
        locale: const Locale('ja', 'JP'), // デフォルトを日本語に設定
        // デバイス設定を無視して強制的に日本語にする
        localeResolutionCallback: (locale, supportedLocales) {
          developer.log('🌍 ロケール解決: デバイスロケール=$locale, サポートロケール=$supportedLocales');
          developer.log('🌍 強制的に日本語(ja_JP)を返します');
          // 常に日本語を返す
          return const Locale('ja', 'JP');
        },
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
