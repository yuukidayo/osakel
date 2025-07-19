const admin = require('firebase-admin');

/**
 * Firebase Admin SDK初期化
 */
function initializeFirebase() {
  console.log('Initializing Firebase connection...');
  
  try {
    // 方法１：サービスアカウントキーを使用
    const serviceAccountPath = '/Users/esumi_yuuki/Desktop/OSAKEL/store_map_app/osakel-app-firebase-adminsdk-fbsvc-05d7fd9f22.json';
    const fs = require('fs');
    if (fs.existsSync(serviceAccountPath)) {
      console.log('Using service account key for authentication...');
      const serviceAccount = require(serviceAccountPath);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: "https://osakel-app-default-rtdb.firebaseio.com"
      });
      
      console.log('Firebase initialized successfully');
      return true;
    }
    
    // 方法２：デフォルト認証情報を使用
    console.log('Trying default credentials...');
    admin.initializeApp();
    console.log('Firebase initialized with default credentials');
    return true;
    
  } catch (error) {
    console.error('Error initializing Firebase:', error);
    console.log('Please provide a valid service account key file named firebase-credentials.json');
    return false;
  }
}

/**
 * ショップデータを移行し、drink_categoriesフィールドを追加
 */
async function migrateAndDuplicateShops() {
  try {
    const firestore = admin.firestore();
    
    console.log('Starting shops migration...');
    
    // カテゴリのドキュメントIDを取得
    console.log('Fetching categories...');
    const categoriesSnapshot = await firestore.collection('categories').get();
    const categoryDocumentIds = categoriesSnapshot.docs.map(doc => doc.id);
    
    console.log(`Found ${categoryDocumentIds.length} categories:`);
    categoryDocumentIds.forEach((id, index) => {
      console.log(`Category ${index + 1}: ${id}`);
    });
    
    // 既存のショップを取得
    console.log('Fetching existing shops...');
    const shopsSnapshot = await firestore.collection('shops').get();
    console.log(`Found ${shopsSnapshot.docs.length} shops to migrate.`);
    
    let batch = firestore.batch();
    let count = 0;
    let batchCount = 1;
    
    for (const doc of shopsSnapshot.docs) {
      const shop = doc.data();
      
      // ランダムに2-3個のカテゴリIDを選択
      const shuffledCategories = [...categoryDocumentIds].sort(() => 0.5 - Math.random());
      const numberOfCategories = Math.floor(Math.random() * 2) + 2; // 2-3個
      const selectedCategories = shuffledCategories.slice(0, numberOfCategories);
      
      console.log(`Shop "${shop.name || 'Unknown'}" will have categories: [${selectedCategories.join(', ')}]`);
      
      // 新しいドキュメントIDを生成
      const newDocId = `${doc.id}_duplicated`;
      const newDocRef = firestore.collection('shops').doc(newDocId);
      
      // 複製したドキュメントを作成
      const newShop = {
        ...shop,
        drink_categories: selectedCategories
      };
      
      // バッチに追加
      batch.set(newDocRef, newShop);
      count++;
      
      // Firestoreのバッチ制限（500）に達したらコミット
      if (count % 400 === 0) {
        console.log(`Committing batch ${batchCount}...`);
        await batch.commit();
        batch = firestore.batch();
        batchCount++;
      }
    }
    
    // 残りをコミット
    if (count % 400 !== 0) {
      console.log(`Committing final batch ${batchCount}...`);
      await batch.commit();
    }
    
    console.log(`Successfully migrated and duplicated ${count} shops in ${batchCount} batches.`);
    return count;
    
  } catch (error) {
    console.error('Error during shops migration:', error);
    throw error;
  }
}

/**
 * メイン実行関数
 */
async function main() {
  try {
    // Firebase初期化
    if (!initializeFirebase()) {
      process.exit(1);
    }
    
    // ショップ移行実行
    const migratedCount = await migrateAndDuplicateShops();
    
    console.log(`\n✅ Migration completed successfully!`);
    console.log(`📊 Total shops migrated: ${migratedCount}`);
    console.log(`🏷️  Each shop now has a 'drink_categories' field with 2-3 category document IDs`);
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  }
}

// スクリプト実行
if (require.main === module) {
  main();
}

module.exports = {
  initializeFirebase,
  migrateAndDuplicateShops
};
