// updateCategoryField.js
const admin = require('firebase-admin');

// Firebaseアプリの初期化（サービスアカウントキーへのパスを指定）
// 実際のサービスアカウントキーのパスを設定
const serviceAccount = require('./osakel-app-firebase-adminsdk-fbsvc-fda666e37c.json');

// Firebase初期化（初回実行時のみ）
function initializeFirebase() {
  if (admin.apps.length === 0) {
    // Firebase Admin SDK初期化
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin SDKが初期化されました');
  }
  
  return admin.firestore();
}

/**
 * カテゴリドキュメントの特定フィールドを配列で更新する関数
 * @param {string} categoryId - 更新対象のカテゴリドキュメントID
 * @param {string} fieldName - 更新対象のフィールド名
 * @param {Array} arrayData - 保存する配列データ
 * @returns {Promise} - 更新処理のPromise
 */
async function updateCategoryFieldWithArray(categoryId, fieldName, arrayData) {
  if (!categoryId || !fieldName || !Array.isArray(arrayData)) {
    throw new Error('Invalid parameters. categoryId and fieldName must be strings, and arrayData must be an array');
  }

  try {
    // Firestoreの初期化
    const db = initializeFirebase();

    // 更新データの準備（動的なフィールド名を使用）
    const updateData = {};
    updateData[fieldName] = arrayData;

    // カテゴリドキュメントの更新
    await db.collection('categories').doc(categoryId).set(updateData, { merge: true });
    console.log(`Successfully updated field "${fieldName}" for category "${categoryId}"`);
    console.log('Updated data:', arrayData);
    
    return {
      success: true,
      message: `Field "${fieldName}" updated successfully for category "${categoryId}"`,
      data: updateData
    };
  } catch (error) {
    console.error('Error updating category field:', error);
    throw error;
  }
}

/**
 * カテゴリ名からドキュメントを検索して特定フィールドを配列で更新する関数
 * @param {string} categoryName - 検索対象のカテゴリ名（nameフィールド）
 * @param {string} fieldName - 更新対象のフィールド名
 * @param {Array} arrayData - 保存する配列データ
 * @returns {Promise} - 更新処理のPromise
 */
async function updateCategoryFieldByNameWithArray(categoryName, fieldName, arrayData) {
  if (!categoryName || !fieldName || !Array.isArray(arrayData)) {
    throw new Error('Invalid parameters. categoryName and fieldName must be strings, and arrayData must be an array');
  }

  try {
    // Firestoreの初期化
    const db = initializeFirebase();
    
    // nameフィールドでカテゴリを検索
    const querySnapshot = await db.collection('categories').where('name', '==', categoryName).get();
    
    if (querySnapshot.empty) {
      console.log(`No category found with name "${categoryName}". Creating a new category...`);
      
      // 新しいカテゴリを作成
      const newCategoryRef = db.collection('categories').doc();
      const newData = {
        name: categoryName,
        [fieldName]: arrayData
      };
      
      await newCategoryRef.set(newData);
      console.log(`Created new category "${categoryName}" with field "${fieldName}"`);
      console.log('Set data:', newData);
      
      return {
        success: true,
        message: `Created new category "${categoryName}" with field "${fieldName}"`,
        data: newData,
        newCategory: true,
        categoryId: newCategoryRef.id
      };
    }
    
    // カテゴリが見つかった場合は更新
    const categoryDoc = querySnapshot.docs[0];
    const categoryId = categoryDoc.id;
    
    // 更新データの準備
    const updateData = {};
    updateData[fieldName] = arrayData;
    
    // カテゴリドキュメントの更新
    await db.collection('categories').doc(categoryId).set(updateData, { merge: true });
    console.log(`Successfully updated field "${fieldName}" for category "${categoryName}" (ID: ${categoryId})`);
    console.log('Updated data:', arrayData);
    
    return {
      success: true,
      message: `Field "${fieldName}" updated successfully for category "${categoryName}" (ID: ${categoryId})`,
      data: updateData,
      categoryId: categoryId
    };
  } catch (error) {
    console.error('Error updating category field by name:', error);
    throw error;
  }
}

// エクスポート（モジュールとして使用する場合）
module.exports = {
  updateCategoryFieldWithArray,
  updateCategoryFieldByNameWithArray
};

// スタンドアロン実行の例（コマンドライン引数から取得）
if (require.main === module) {
  const args = process.argv.slice(2);
  const mode = args[0];
  
  if (mode === '--name' || mode === '-n') {
    // nameフィールドで検索して更新するモード
    if (args.length >= 4) {
      const categoryName = args[1];
      const fieldName = args[2];
      // 残りの引数を配列データとして扱う
      const arrayData = args.slice(3);
      
      updateCategoryFieldByNameWithArray(categoryName, fieldName, arrayData)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
    } else {
      console.log('Usage: node updateCategoryField.js --name <categoryName> <fieldName> <item1> <item2> ...');
      process.exit(1);
    }
  } else {
    // 従来のID指定モード
    if (args.length >= 3) {
      const categoryId = args[0];
      const fieldName = args[1];
      // 残りの引数を配列データとして扱う
      const arrayData = args.slice(2);
      
      updateCategoryFieldWithArray(categoryId, fieldName, arrayData)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
    } else {
      console.log('Usage ID mode: node updateCategoryField.js <categoryId> <fieldName> <item1> <item2> ...');
      console.log('Usage Name mode: node updateCategoryField.js --name <categoryName> <fieldName> <item1> <item2> ...');
      process.exit(1);
    }
  }
}
