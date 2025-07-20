const admin = require('firebase-admin');

// Firebase Admin SDK初期化
const serviceAccount = require('../assets/secrets/osakel-app-firebase-adminsdk-fbsvc-bb50459439.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 更新するimageUrl
const NEW_IMAGE_URL = 'https://firebasestorage.googleapis.com/v0/b/osakel-app.firebasestorage.app/o/stores%2F%E3%81%8A%E5%BA%97%E3%81%AE%E3%82%B5%E3%83%B3%E3%83%95%E3%82%9A%E3%83%AB%E7%94%BB%E5%83%8F%20(1).png?alt=media&token=6cd14506-7787-4171-b702-97c108afba59';

async function updateShopsImageUrls() {
  try {
    console.log('🔄 shopsコレクションのimageUrls一括更新を開始します...');
    
    // shopsコレクションの全ドキュメントを取得
    const shopsSnapshot = await db.collection('shops').get();
    
    if (shopsSnapshot.empty) {
      console.log('⚠️ shopsコレクションにドキュメントが見つかりません');
      return;
    }
    
    console.log(`📊 対象ドキュメント数: ${shopsSnapshot.size}件`);
    
    // バッチ処理用
    const batch = db.batch();
    let updateCount = 0;
    
    // 各ドキュメントのimageUrlsを更新
    shopsSnapshot.forEach((doc) => {
      const docRef = db.collection('shops').doc(doc.id);
      const currentData = doc.data();
      
      // 現在のimageUrlsを表示
      console.log(`📄 ドキュメントID: ${doc.id}`);
      console.log(`   現在のimageUrls: ${JSON.stringify(currentData.imageUrls || [])}`);
      
      // imageUrlsを新しいURL配列に更新
      batch.update(docRef, {
        imageUrls: [NEW_IMAGE_URL],
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      updateCount++;
    });
    
    // バッチ処理を実行
    console.log('\n🚀 バッチ更新を実行中...');
    await batch.commit();
    
    console.log(`\n✅ 更新完了！`);
    console.log(`📊 更新されたドキュメント数: ${updateCount}件`);
    console.log(`🖼️ 新しいimageUrls: ["${NEW_IMAGE_URL}"]`);
    
    // 更新結果を確認
    console.log('\n🔍 更新結果を確認中...');
    const updatedSnapshot = await db.collection('shops').limit(3).get();
    updatedSnapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`✅ ${doc.id}: ${JSON.stringify(data.imageUrls)}`);
    });
    
  } catch (error) {
    console.error('❌ エラーが発生しました:', error);
  } finally {
    // Firebase Admin SDK終了
    admin.app().delete();
  }
}

// スクリプト実行
updateShopsImageUrls();
