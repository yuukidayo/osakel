import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_data_creator.dart';

// このスクリプトは単独で実行するためのものです
void main() async {
  // Flutter初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp();
  debugPrint('Firebase initialized successfully');
  
  // データ作成クラスのインスタンス化
  final dataCreator = FirebaseDataCreator();
  
  try {
    // サンプルドリンクデータの作成
    debugPrint('サンプルドリンクデータの作成を開始します...');
    await dataCreator.createSampleDrinks();
    debugPrint('サンプルドリンクデータの作成が完了しました');
    
    // 成功メッセージ
    debugPrint('処理が完了しました。アプリを終了します。');
  } catch (e) {
    debugPrint('エラーが発生しました: $e');
  }
}
