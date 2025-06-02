import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/category_list_screen.dart';
import 'screens/subcategory_screen.dart';
import 'screens/drink_detail_screen.dart';
import 'screens/map_screen_fixed.dart' as map_screen;
import 'screens/shop_detail_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サウナマップ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
        ),
      ),
      // カテゴリ選択画面をホーム画面として表示
      home: const CategoryListScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/category') {
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
