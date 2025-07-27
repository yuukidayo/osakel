import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// drinksコレクションに10種類のドキュメントを作成するスクリプト
void main() async {
  // Flutter初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp();
  debugPrint('Firebase initialized successfully');
  
  // Firestoreインスタンスの取得
  final firestore = FirebaseFirestore.instance;
  
  try {
    debugPrint('サンプルドリンクデータの作成を開始します...');
    
    // バッチ処理を使用して複数のドキュメントを一度に作成
    final batch = firestore.batch();
    
    // ビールカテゴリ（カテゴリID: beer）のドリンク
    final beerDrinks = [
      {
        'name': 'プレミアムモルツ',
        'category': 'beer',
        'categoryId': 'cat_beer',
        'type': 'ラガー',
        'brand': 'サントリー',
        'country': '日本',
        'region': '関西',
        'alcohol': 5.5,
        'price': 550,
        'imageUrl': 'https://example.com/premium_malts.jpg',
        'description': '麦芽100%の贅沢な味わいが特徴のプレミアムビール。',
        'isPR': true,
      },
      {
        'name': 'よなよなエール',
        'category': 'beer',
        'categoryId': 'cat_beer',
        'type': 'ペールエール',
        'brand': 'ヤッホーブルーイング',
        'country': '日本',
        'region': '長野',
        'alcohol': 5.0,
        'price': 480,
        'imageUrl': 'https://example.com/yonayona.jpg',
        'description': '華やかなホップの香りと苦味が特徴の日本のクラフトビール。',
        'isPR': false,
      },
      {
        'name': 'ギネス ドラフト',
        'category': 'beer',
        'categoryId': 'cat_beer',
        'type': 'スタウト',
        'brand': 'ギネス',
        'country': 'アイルランド',
        'region': 'ダブリン',
        'alcohol': 4.2,
        'price': 700,
        'imageUrl': 'https://example.com/guinness.jpg',
        'description': '黒ビールの代表格。コーヒーやチョコレートを思わせる複雑な風味。',
        'isPR': false,
      },
      {
        'name': 'インディアペールエール',
        'category': 'beer',
        'categoryId': 'cat_beer',
        'type': 'IPA',
        'brand': 'ブリュードッグ',
        'country': 'スコットランド',
        'region': 'エルロン',
        'alcohol': 6.5,
        'price': 650,
        'imageUrl': 'https://example.com/ipa.jpg',
        'description': '強いホップの苦味と柑橘系の香りが特徴の個性的なビール。',
        'isPR': false,
      },
    ];
    
    // ワインカテゴリ（カテゴリID: wine）のドリンク
    final wineDrinks = [
      {
        'name': 'シャトー・マルゴー',
        'category': 'wine',
        'categoryId': 'cat_wine',
        'type': '赤ワイン',
        'brand': 'シャトー・マルゴー',
        'grape': 'カベルネ・ソーヴィニヨン',
        'country': 'フランス',
        'region': 'ボルドー',
        'alcohol': 13.5,
        'price': 50000,
        'imageUrl': 'https://example.com/margaux.jpg',
        'description': 'ボルドーの5大シャトーの一つ。エレガントで複雑な味わい。',
        'isPR': false,
      },
      {
        'name': 'シャブリ グラン・クリュ',
        'category': 'wine',
        'categoryId': 'cat_wine',
        'type': '白ワイン',
        'brand': 'ウィリアム・フェーブル',
        'grape': 'シャルドネ',
        'country': 'フランス',
        'region': 'ブルゴーニュ',
        'alcohol': 12.5,
        'price': 8000,
        'imageUrl': 'https://example.com/chablis.jpg',
        'description': 'ミネラル感豊かで爽やかな酸味が特徴のプレミアム白ワイン。',
        'isPR': true,
      },
      {
        'name': 'バローロ',
        'category': 'wine',
        'categoryId': 'cat_wine',
        'type': '赤ワイン',
        'brand': 'ジャコモ・コンテルノ',
        'grape': 'ネッビオーロ',
        'country': 'イタリア',
        'region': 'ピエモンテ',
        'alcohol': 14.0,
        'price': 12000,
        'imageUrl': 'https://example.com/barolo.jpg',
        'description': 'イタリアワインの王様と呼ばれる力強い赤ワイン。',
        'isPR': false,
      },
    ];
    
    // ウイスキーカテゴリのドリンク
    final whiskyDrinks = [
      {
        'name': '山崎12年',
        'category': 'whisky',
        'categoryId': 'cat_whisky',
        'type': 'シングルモルト',
        'brand': 'サントリー',
        'country': '日本',
        'region': '大阪',
        'alcohol': 43.0,
        'price': 15000,
        'imageUrl': 'https://example.com/yamazaki.jpg',
        'description': '日本を代表するシングルモルトウイスキー。華やかな香りと複雑な味わい。',
        'isPR': true,
      },
      {
        'name': 'ラフロイグ10年',
        'category': 'whisky',
        'categoryId': 'cat_whisky',
        'type': 'islay',
        'brand': 'ラフロイグ',
        'country': 'スコットランド',
        'region': 'アイラ島',
        'alcohol': 40.0,
        'price': 7000,
        'imageUrl': 'https://example.com/laphroaig.jpg',
        'description': '強烈なピート香と海の香りが特徴的なアイラモルト。',
        'isPR': false,
      },
      {
        'name': 'メーカーズマーク',
        'category': 'whisky',
        'categoryId': 'cat_whisky',
        'type': 'bourbon',
        'brand': 'メーカーズマーク',
        'country': 'アメリカ',
        'region': 'ケンタッキー',
        'alcohol': 45.0,
        'price': 4500,
        'imageUrl': 'https://example.com/makers.jpg',
        'description': '赤い封蝋が特徴的な、甘みのあるプレミアムバーボン。',
        'isPR': false,
      },
    ];
    
    // ドリンクデータをバッチに追加
    final allDrinks = [...beerDrinks, ...wineDrinks, ...whiskyDrinks];
    
    for (var drink in allDrinks) {
      final docRef = firestore.collection('drinks').doc();
      batch.set(docRef, drink);
      debugPrint('ドリンクを追加: ${drink['name']}');
    }
    
    // バッチを実行
    await batch.commit();
    debugPrint('サンプルドリンクデータの作成が完了しました。合計${allDrinks.length}件のドリンクを追加しました。');
  } catch (e) {
    debugPrint('サンプルドリンクデータの作成中にエラーが発生しました: $e');
    rethrow;
  }
}
