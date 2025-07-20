#!/usr/bin/env node

const admin = require('firebase-admin');

/**
 * Firestoreのdrinks/drink_shop_linksコレクションのデータを確認するデバッグスクリプト
 */

class FirestoreDebugger {
  constructor() {
    this.db = null;
  }

  async initialize() {
    try {
      const serviceAccountPath = '/Users/esumi_yuuki/Desktop/OSAKEL/store_map_app/osakel-app-firebase-adminsdk-fbsvc-05d7fd9f22.json';
      
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

  async debugDrinkIds() {
    console.log('🔍 Firestore データ確認スクリプト');
    console.log('='.repeat(50));
    
    try {
      await this.initialize();
      
      // 1. drinksコレクションの確認
      console.log('\n📊 drinksコレクション:');
      const drinksSnapshot = await this.db.collection('drinks').limit(10).get();
      drinksSnapshot.docs.forEach((doc, index) => {
        console.log(`   ${index + 1}. ID: ${doc.id}`);
        const data = doc.data();
        console.log(`      名前: ${data.name || '未設定'}`);
      });
      
      // 2. drink_shop_linksコレクションの確認
      console.log('\n🔗 drink_shop_linksコレクション:');
      const linksSnapshot = await this.db.collection('drink_shop_links').limit(10).get();
      linksSnapshot.docs.forEach((doc, index) => {
        console.log(`   ${index + 1}. ID: ${doc.id}`);
        const data = doc.data();
        console.log(`      drinkId: ${data.drinkId || '未設定'}`);
        console.log(`      shopId: ${data.shopId || '未設定'}`);
        console.log(`      price: ${data.price || '未設定'}`);
      });
      
      // 3. 統計情報
      const [drinksCount, linksCount, shopsCount] = await Promise.all([
        this.db.collection('drinks').count().get(),
        this.db.collection('drink_shop_links').count().get(),
        this.db.collection('shops').count().get()
      ]);
      
      console.log('\n📈 統計情報:');
      console.log(`   - drinks: ${drinksCount.data().count}件`);
      console.log(`   - drink_shop_links: ${linksCount.data().count}件`);
      console.log(`   - shops: ${shopsCount.data().count}件`);
      
      // 4. 特定のdrinkIdでの検索テスト
      if (drinksSnapshot.docs.length > 0) {
        const testDrinkId = drinksSnapshot.docs[0].id;
        console.log(`\n🧪 検索テスト (drinkId: ${testDrinkId}):`);
        
        const testLinksSnapshot = await this.db
          .collection('drink_shop_links')
          .where('drinkId', '==', testDrinkId)
          .get();
        
        console.log(`   該当する店舗: ${testLinksSnapshot.docs.length}件`);
        testLinksSnapshot.docs.forEach((doc, index) => {
          const data = doc.data();
          console.log(`     ${index + 1}. shopId: ${data.shopId}, price: ${data.price}`);
        });
      }
      
    } catch (error) {
      console.error('❌ デバッグエラー:', error);
    }
  }
}

// スクリプト実行
if (require.main === module) {
  const firestoreDebugger = new FirestoreDebugger();
  firestoreDebugger.debugDrinkIds();
}
