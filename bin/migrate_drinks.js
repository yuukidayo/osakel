// Firebaseのdrinksコレクションを複製し、subcategories配列を追加するスクリプト
// 実行方法: 
// 1. firebase login
// 2. firebase use --add (プロジェクトを選択)
// 3. node bin/migrate_drinks.js

const admin = require('firebase-admin');
const { execSync } = require('child_process');

// Firebase接続の初期化
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
        credential: admin.credential.cert(serviceAccount)
      });
    } 
    // 方法２：上記が失敗した場合は、プロジェクトIDを直接指定
    else {
      console.log('Service account key not found. Using project ID directly.');
      // Firebase CLIからプロジェクトIDを取得
      const projectId = execSync('firebase use --json')
        .toString()
        .trim();
        
      const projectInfo = JSON.parse(projectId);
      console.log(`Using Firebase project ID: ${projectInfo.result}`);
      
      // 認証情報を直接指定
      admin.initializeApp({
        projectId: projectInfo.result,
        // GOOGLE_APPLICATION_CREDENTIALS環境変数に依存します
        // ここで、Google Cloudの認証情報を指定することも可能です
      });
    }
    
    console.log('Firebase initialized successfully');
    return admin.firestore();
  } catch (error) {
    console.error('Error initializing Firebase:', error);
    console.error('Please provide a valid service account key file named firebase-credentials.json');
    process.exit(1);
  }
}

// データ移行の実行
async function migrateAndDuplicateDrinks() {
  const db = initializeFirebase();
  
  try {
    console.log('Starting drinks migration...');
    
    // カテゴリとサブカテゴリの情報を取得
    console.log('Fetching categories...');
    const categoriesSnapshot = await db.collection('categories').get();
    const categoryMap = {};
    
    categoriesSnapshot.forEach(doc => {
      const data = doc.data();
      categoryMap[doc.id] = data.subcategories || [];
      console.log(`Category ${doc.id} has ${(data.subcategories || []).length} subcategories`);
    });
    
    // 既存のドリンクを取得
    console.log('Fetching existing drinks...');
    const drinksSnapshot = await db.collection('drinks').get();
    console.log(`Found ${drinksSnapshot.size} drinks to migrate.`);
    
    let batch = db.batch();
    let count = 0;
    let batchCount = 0;
    
    for (const doc of drinksSnapshot.docs) {
      const drink = doc.data();
      const categoryId = drink.categoryId || drink.category || '';
      
      const availableSubcategories = categoryMap[categoryId] || [];
      let selectedSubcategories = [];
      
      if (availableSubcategories.length >= 2) {
        // ランダムに2つ選択
        const shuffled = [...availableSubcategories].sort(() => 0.5 - Math.random());
        selectedSubcategories = shuffled.slice(0, 2).map(sub => {
          return typeof sub === 'object' ? (sub.id || '') : sub.toString();
        });
      } else if (availableSubcategories.length > 0) {
        selectedSubcategories = availableSubcategories.map(sub => {
          return typeof sub === 'object' ? (sub.id || '') : sub.toString();
        });
      }
      
      // 既存のsubcategoryIdがあれば配列に追加（重複しないように）
      if (drink.subcategoryId && !selectedSubcategories.includes(drink.subcategoryId)) {
        selectedSubcategories.push(drink.subcategoryId.toString());
      }
      
      // 新しいドキュメントIDを生成
      const newDocId = `${doc.id}_duplicated`;
      const newDocRef = db.collection('drinks').doc(newDocId);
      
      // 複製したドキュメントを作成
      const newDrink = { ...drink, subcategories: selectedSubcategories };
      
      // バッチに追加
      batch.set(newDocRef, newDrink);
      
      count++;
      
      // Firestoreのバッチ制限（500）に達したらコミット
      if (count % 400 === 0) {
        batchCount++;
        console.log(`Committing batch ${batchCount} with ${count} documents...`);
        await batch.commit();
        batch = db.batch(); // 新しいバッチを作成
      }
    }
    
    // 残りをコミット
    if (count % 400 !== 0) {
      batchCount++;
      console.log(`Committing final batch ${batchCount}...`);
      await batch.commit();
    }
    
    console.log(`Successfully migrated and duplicated ${count} drinks in ${batchCount} batches.`);
    process.exit(0);
  } catch (error) {
    console.error('Error during migration:', error);
    process.exit(1);
  }
}

// スクリプトの実行
migrateAndDuplicateDrinks();
