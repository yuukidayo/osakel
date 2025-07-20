#!/usr/bin/env node

const admin = require('firebase-admin');
const readline = require('readline');

/**
 * drink_shop_linksコレクションにshops/drinksのIDを紐づけて保存するスクリプト
 * 
 * 使用方法:
 * 1. node scripts/populate_drink_shop_links.js
 * 
 * 機能:
 * - 既存のshops/drinksコレクションからIDを取得
 * - ランダムな組み合わせでdrink_shop_linksを生成
 * - 価格、在庫状況、備考などの情報も自動生成
 */

const COLLECTION_NAMES = {
  SHOPS: 'shops',
  DRINKS: 'drinks',
  DRINK_SHOP_LINKS: 'drink_shop_links'
};

const BATCH_SIZE = 500;

class DrinkShopLinksPopulator {
  constructor() {
    this.db = null;
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  }

  /**
   * メイン実行メソッド
   */
  async populateDrinkShopLinks() {
    console.log('🔗 Firestore drink_shop_links コレクション紐づけデータ生成スクリプト');
    console.log('='.repeat(70));
    
    try {
      // Firebase初期化
      await this.initializeFirebase();
      
      // 既存データ確認
      const stats = await this.getCollectionStats();
      console.log('\n📊 既存データ統計:');
      console.log(`   - shops: ${stats.shopsCount}件`);
      console.log(`   - drinks: ${stats.drinksCount}件`);
      console.log(`   - drink_shop_links: ${stats.linksCount}件`);
      
      // 生成設定の確認
      const config = await this.getGenerationConfig(stats);
      if (!config) {
        console.log('❌ 処理をキャンセルしました。');
        return;
      }
      
      // データ生成・保存
      await this.generateAndSaveLinks(config);
      
      console.log('✅ 紐づけデータ生成が完了しました。');
      
    } catch (error) {
      console.error('❌ スクリプト実行エラー:', error);
      process.exit(1);
    } finally {
      this.rl.close();
    }
  }

  /**
   * Firebase初期化
   */
  async initializeFirebase() {
    try {
      const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
                                 '/Users/esumi_yuuki/Desktop/OSAKEL/store_map_app/osakel-app-firebase-adminsdk-fbsvc-05d7fd9f22.json';
      
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert(require(serviceAccountPath)),
        });
      }
      
      this.db = admin.firestore();
      console.log('✅ Firebase Admin SDK初期化完了');
      
    } catch (error) {
      console.error('❌ Firebase初期化エラー:', error);
      throw error;
    }
  }

  /**
   * コレクション統計取得
   */
  async getCollectionStats() {
    const [shopsSnapshot, drinksSnapshot, linksSnapshot] = await Promise.all([
      this.db.collection(COLLECTION_NAMES.SHOPS).count().get(),
      this.db.collection(COLLECTION_NAMES.DRINKS).count().get(),
      this.db.collection(COLLECTION_NAMES.DRINK_SHOP_LINKS).count().get()
    ]);

    return {
      shopsCount: shopsSnapshot.data().count || 0,
      drinksCount: drinksSnapshot.data().count || 0,
      linksCount: linksSnapshot.data().count || 0
    };
  }

  /**
   * 生成設定の確認
   */
  async getGenerationConfig(stats) {
    if (stats.shopsCount === 0 || stats.drinksCount === 0) {
      console.log('❌ shops または drinks コレクションが空です。');
      return null;
    }

    console.log('\n🎯 生成モード選択:');
    console.log('1. 各店舗にランダムなドリンクを3-8個割り当て (推奨)');
    console.log('2. 全組み合わせ生成 (大量データ注意)');
    console.log('3. カスタム設定');
    
    const mode = await this.askQuestion('モードを選択してください (1-3): ');
    
    switch (mode.trim()) {
      case '1':
        return {
          mode: 'random',
          minDrinksPerShop: 3,
          maxDrinksPerShop: 8,
          estimatedTotal: stats.shopsCount * 5.5 // 平均
        };
      case '2':
        const total = stats.shopsCount * stats.drinksCount;
        console.log(`⚠️ 警告: ${total.toLocaleString()}件のデータが生成されます。`);
        const confirm = await this.askQuestion('続行しますか？ (yes/no): ');
        if (confirm.toLowerCase().trim() !== 'yes') return null;
        
        return {
          mode: 'all',
          estimatedTotal: total
        };
      case '3':
        return await this.getCustomConfig(stats);
      default:
        console.log('❌ 無効な選択です。');
        return null;
    }
  }

  /**
   * カスタム設定取得
   */
  async getCustomConfig(stats) {
    const minDrinks = await this.askQuestion('各店舗の最小ドリンク数: ');
    const maxDrinks = await this.askQuestion('各店舗の最大ドリンク数: ');
    
    return {
      mode: 'custom',
      minDrinksPerShop: parseInt(minDrinks) || 1,
      maxDrinksPerShop: parseInt(maxDrinks) || stats.drinksCount,
      estimatedTotal: stats.shopsCount * ((parseInt(minDrinks) + parseInt(maxDrinks)) / 2)
    };
  }

  /**
   * データ生成・保存
   */
  async generateAndSaveLinks(config) {
    console.log(`\n🔗 紐づけデータ生成開始 (推定${config.estimatedTotal.toLocaleString()}件)...`);
    
    // 全店舗・ドリンクID取得
    const [shopIds, drinkIds] = await Promise.all([
      this.getAllDocumentIds(COLLECTION_NAMES.SHOPS),
      this.getAllDocumentIds(COLLECTION_NAMES.DRINKS)
    ]);
    
    console.log(`📦 取得完了: shops=${shopIds.length}件, drinks=${drinkIds.length}件`);
    
    // 紐づけデータ生成
    const links = this.generateLinks(shopIds, drinkIds, config);
    console.log(`🎯 生成完了: ${links.length}件の紐づけデータ`);
    
    // バッチ保存
    await this.saveLinksBatch(links);
  }

  /**
   * 全ドキュメントID取得
   */
  async getAllDocumentIds(collectionName) {
    const snapshot = await this.db.collection(collectionName).select().get();
    return snapshot.docs.map(doc => doc.id);
  }

  /**
   * 紐づけデータ生成
   */
  generateLinks(shopIds, drinkIds, config) {
    const links = [];
    
    shopIds.forEach(shopId => {
      let shopDrinks;
      
      if (config.mode === 'all') {
        shopDrinks = drinkIds;
      } else {
        // ランダム選択
        const count = this.randomBetween(config.minDrinksPerShop, config.maxDrinksPerShop);
        shopDrinks = this.shuffleArray([...drinkIds]).slice(0, count);
      }
      
      shopDrinks.forEach(drinkId => {
        links.push({
          id: `${drinkId}_${shopId}`,
          drinkId: drinkId,
          shopId: shopId,
          price: this.generateRandomPrice(),
          isAvailable: Math.random() > 0.1, // 90%の確率で在庫あり
          note: this.generateRandomNote(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
    });
    
    return links;
  }

  /**
   * バッチ保存
   */
  async saveLinksBatch(links) {
    console.log(`\n💾 バッチ保存開始 (${links.length}件)...`);
    
    let savedCount = 0;
    
    for (let i = 0; i < links.length; i += BATCH_SIZE) {
      const batch = this.db.batch();
      const batchLinks = links.slice(i, i + BATCH_SIZE);
      
      batchLinks.forEach(link => {
        const docRef = this.db.collection(COLLECTION_NAMES.DRINK_SHOP_LINKS).doc(link.id);
        batch.set(docRef, link);
      });
      
      await batch.commit();
      savedCount += batchLinks.length;
      
      console.log(`   ✅ ${batchLinks.length}件保存 (累計: ${savedCount}/${links.length}件)`);
      
      // レート制限対策
      await this.sleep(100);
    }
    
    console.log(`\n📊 保存完了統計:`);
    console.log(`   - 総保存件数: ${savedCount}件`);
    console.log(`   - 実行バッチ数: ${Math.ceil(links.length / BATCH_SIZE)}バッチ`);
  }

  /**
   * ランダム価格生成 (300-2000円)
   */
  generateRandomPrice() {
    return Math.floor(Math.random() * (2000 - 300 + 1)) + 300;
  }

  /**
   * ランダム備考生成
   */
  generateRandomNote() {
    const notes = [
      '',
      'おすすめ',
      '限定品',
      '人気商品',
      '季節限定',
      '新商品',
      'セール中'
    ];
    return notes[Math.floor(Math.random() * notes.length)];
  }

  /**
   * 指定範囲のランダム整数
   */
  randomBetween(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  /**
   * 配列シャッフル
   */
  shuffleArray(array) {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  /**
   * 質問プロンプト
   */
  askQuestion(question) {
    return new Promise((resolve) => {
      this.rl.question(question, resolve);
    });
  }

  /**
   * 指定ミリ秒待機
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// スクリプトエントリーポイント
if (require.main === module) {
  const populator = new DrinkShopLinksPopulator();
  populator.populateDrinkShopLinks();
}
