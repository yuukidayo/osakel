// Firebaseのdrinksコレクションを複製し、subcategories配列を追加するスクリプト
// 実行方法: flutter run --release -d <device_id> -t bin/migrate_drinks.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../lib/firebase_options.dart';

void main() async {
  // Flutter初期化（最初に実行する必要がある）
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MigrationApp());
}

class MigrationApp extends StatelessWidget {
  const MigrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MigrationScreen(),
    );
  }
}

class MigrationScreen extends StatefulWidget {
  @override
  _MigrationScreenState createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  String _status = 'Initializing...';
  bool _isRunning = false;
  String _result = '';
  
  @override
  void initState() {
    super.initState();
    _initFirebase();
  }
  
  Future<void> _initFirebase() async {
    try {
      setState(() {
        _status = 'Initializing Firebase...';
      });
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      setState(() {
        _status = 'Firebase initialized. Ready to migrate.';
      });
    } catch (e) {
      setState(() {
        _status = 'Firebase initialization error: $e';
      });
    }
  }
  
  Future<void> _startMigration() async {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _status = 'Migration in progress...';
    });
    
    try {
      final result = await migrateAndDuplicateDrinksForTesting();
      
      setState(() {
        _result = result;
        _status = 'Migration completed.';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error during migration: $e';
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drinks Migration Tool'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Status: $_status',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (_result.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Result: $_result',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRunning ? null : _startMigration,
              child: Text(_isRunning ? 'Running...' : 'Start Migration'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 既存のdrinksコレクションを複製し、subcategories配列を追加する
Future<String> migrateAndDuplicateDrinksForTesting() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  try {
    // カテゴリとサブカテゴリの情報を取得
    debugPrint('Fetching categories...');
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final categoryMap = <String, List<dynamic>>{};
    
    for (var doc in categoriesSnapshot.docs) {
      final data = doc.data();
      categoryMap[doc.id] = data['subcategories'] ?? [];
      debugPrint('Category ${doc.id} has ${(data['subcategories'] ?? []).length} subcategories');
    }
    
    // 既存のドリンクを取得
    debugPrint('Fetching existing drinks...');
    final drinksSnapshot = await _firestore.collection('drinks').get();
    debugPrint('Found ${drinksSnapshot.docs.length} drinks to migrate.');
    
    var batch = _firestore.batch();
    int count = 0;
    
    for (var doc in drinksSnapshot.docs) {
      final drink = doc.data();
      final categoryId = drink['categoryId'] ?? drink['category'] ?? '';
      
      final availableSubcategories = categoryMap[categoryId] ?? [];
      List<String> selectedSubcategories = [];
      
      if (availableSubcategories.length >= 2) {
        // ランダムに2つ選択
        final shuffled = List.from(availableSubcategories)..shuffle();
        selectedSubcategories = shuffled.take(2).map<String>((sub) {
          return sub is Map ? (sub['id'] ?? '') : sub.toString();
        }).toList();
      } else if (availableSubcategories.isNotEmpty) {
        selectedSubcategories = availableSubcategories.map<String>((sub) {
          return sub is Map ? (sub['id'] ?? '') : sub.toString();
        }).toList();
      }
      
      // 既存のsubcategoryIdがあれば配列に追加（重複しないように）
      if (drink['subcategoryId'] != null && 
          !selectedSubcategories.contains(drink['subcategoryId'])) {
        selectedSubcategories.add(drink['subcategoryId'].toString());
      }
      
      // 新しいドキュメントIDを生成
      final newDocId = '${doc.id}_duplicated';
      final newDocRef = _firestore.collection('drinks').doc(newDocId);
      
      // 複製したドキュメントを作成
      final Map<String, dynamic> newDrink = Map.from(drink);
      newDrink['subcategories'] = selectedSubcategories;
      
      // バッチに追加
      batch.set(newDocRef, newDrink);
      
      count++;
      
      // Firestoreのバッチ制限（500）に達したらコミット
      if (count % 400 == 0) {
        debugPrint('Committing batch of $count documents...');
        await batch.commit();
        batch = _firestore.batch(); // 新しいバッチを作成
      }
    }
    
    // 残りをコミット
    if (count % 400 != 0) {
      debugPrint('Committing final batch...');
      await batch.commit();
    }
    
    return 'Successfully migrated and duplicated $count drinks.';
  } catch (error) {
    debugPrint('Error during migration: $error');
    return 'Migration failed: ${error.toString()}';
  }
}
