#!/usr/bin/env node

const admin = require('firebase-admin');
const readline = require('readline');

/**
 * drink_shop_linksコレクションの全データを一括削除するスクリプト
 * 
 * 使用方法:
 * 1. npm install firebase-admin (初回のみ)
 * 2. Firebase Admin SDK サービスアカウントキーを設定
 * 3. node scripts/delete_drink_shop_links.js
 * 
 * 注意: この操作は元に戻せません！実行前に必ずバックアップを取ってください。
 */

const COLLECTION_NAME = 'drink_shop_links';
const BATCH_SIZE = 500; // Firestoreの制限に合わせたバッチサイズ

class DrinkShopLinksDeleter {
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
  async deleteAllDrinkShopLinks() {
    console.log('🔥 Firestore drink_shop_links コレクション一括削除スクリプト');
    console.log('='.repeat(60));
    
    try {
      // Firebase初期化
      await this.initializeFirebase();
      
      // 確認プロンプト
      const confirmed = await this.confirmDeletion();
      if (!confirmed) {
        console.log('❌ 削除処理をキャンセルしました。');
        return;
      }
      
      // 削除実行
      await this.performBatchDeletion();
      
      console.log('✅ 削除処理が完了しました。');
      
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
      // サービスアカウントキーのパスを環境変数から取得
      const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
                                 '/Users/esumi_yuuki/Desktop/OSAKEL/store_map_app/osakel-app-firebase-adminsdk-fbsvc-05d7fd9f22.json';
      
      // Firebase Admin SDK初期化
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert(require(serviceAccountPath)),
          // プロジェクトIDは自動で取得されます
        });
      }
      
      this.db = admin.firestore();
      console.log('✅ Firebase Admin SDK初期化完了');
      
    } catch (error) {
      console.error('❌ Firebase初期化エラー:', error);
      console.log('\n💡 解決方法:');
      console.log('1. Firebase Console からサービスアカウントキーをダウンロード');
      console.log('2. キーファイルを firebase-service-account.json として保存');
      console.log('3. または環境変数 GOOGLE_APPLICATION_CREDENTIALS を設定');
      throw error;
    }
  }

  /**
   * 削除確認プロンプト
   */
  async confirmDeletion() {
    // まずドキュメント数を確認
    const count = await this.getDocumentCount();
    
    console.log('\n⚠️  警告: この操作は元に戻せません！');
    console.log(`📊 削除対象: ${COLLECTION_NAME} コレクション (${count}件のドキュメント)`);
    console.log('');
    
    return new Promise((resolve) => {
      this.rl.question('本当に削除しますか？ (yes/no): ', (answer) => {
        const confirmed = answer.toLowerCase().trim() === 'yes' || answer.toLowerCase().trim() === 'y';
        resolve(confirmed);
      });
    });
  }

  /**
   * ドキュメント数取得
   */
  async getDocumentCount() {
    try {
      const snapshot = await this.db.collection(COLLECTION_NAME).count().get();
      return snapshot.data().count || 0;
    } catch (error) {
      console.warn('⚠️ ドキュメント数取得エラー:', error);
      return 0;
    }
  }

  /**
   * バッチ削除実行
   */
  async performBatchDeletion() {
    let totalDeleted = 0;
    let batchCount = 0;

    console.log('\n🗑️  削除処理開始...');
    
    while (true) {
      batchCount++;
      console.log(`📦 バッチ ${batchCount} 処理中...`);
      
      // バッチサイズ分のドキュメントを取得
      const snapshot = await this.db
        .collection(COLLECTION_NAME)
        .limit(BATCH_SIZE)
        .get();
      
      if (snapshot.empty) {
        console.log('✅ 全てのドキュメントを削除しました。');
        break;
      }
      
      // バッチ削除実行
      const batch = this.db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      try {
        await batch.commit();
        totalDeleted += snapshot.docs.length;
        console.log(`   ✅ ${snapshot.docs.length}件削除 (累計: ${totalDeleted}件)`);
        
        // レート制限対策で少し待機
        await this.sleep(100);
        
      } catch (error) {
        console.error('   ❌ バッチ削除エラー:', error);
        throw error;
      }
    }
    
    console.log('\n📊 削除完了統計:');
    console.log(`   - 総削除件数: ${totalDeleted}件`);
    console.log(`   - 実行バッチ数: ${batchCount - 1}バッチ`);
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
  const deleter = new DrinkShopLinksDeleter();
  deleter.deleteAllDrinkShopLinks();
}
