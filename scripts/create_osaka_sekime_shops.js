const admin = require('firebase-admin');

// Firebase Admin SDKの初期化
const serviceAccount = require('./osakel-app-firebase-adminsdk-fbsvc-fda666e37c.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 大阪市城東区関目周辺の店舗データ
const osakaShops = [
  {
    id: 'osaka_sekime_bar_001',
    name: '関目バー OSAKEL',
    address: '大阪府大阪市城東区関目2-1-15',
    lat: 34.7024,
    lng: 135.5538,
    category: 'バー',
    openTime: '18:00',
    openHours: '18:00 - 02:00',
    imageUrl: 'https://example.com/osaka_sekime_bar.jpg',
    imageUrls: [
      'https://example.com/osaka_sekime_bar_1.jpg',
      'https://example.com/osaka_sekime_bar_2.jpg',
      'https://example.com/osaka_sekime_bar_3.jpg'
    ],
    drinkIds: ['oZTuXXMx1WaErBoCzYa1_duplicated'],
    drink_categories: ['0FavGaP6R45vr9DZLvrX', '8bXjiNMhwduF1pJv5Q8D']
  },
  {
    id: 'osaka_sekime_izakaya_002',
    name: '関目居酒屋 かんもく',
    address: '大阪府大阪市城東区関目3-5-8',
    lat: 34.7031,
    lng: 135.5545,
    category: '居酒屋',
    openTime: '17:00',
    openHours: '17:00 - 24:00',
    imageUrl: 'https://example.com/osaka_sekime_izakaya.jpg',
    imageUrls: [
      'https://example.com/osaka_sekime_izakaya_1.jpg',
      'https://example.com/osaka_sekime_izakaya_2.jpg'
    ],
    drinkIds: ['oZTuXXMx1WaErBoCzYa1_duplicated'],
    drink_categories: ['8bXjiNMhwduF1pJv5Q8D', 'bkEjjwPNtBsjqhOXGVoe']
  },
  {
    id: 'osaka_sekime_wine_003',
    name: 'ワインバー セキメ',
    address: '大阪府大阪市城東区関目1-12-3',
    lat: 34.7018,
    lng: 135.5532,
    category: 'ワインバー',
    openTime: '19:00',
    openHours: '19:00 - 01:00',
    imageUrl: 'https://example.com/osaka_sekime_wine.jpg',
    imageUrls: [
      'https://example.com/osaka_sekime_wine_1.jpg',
      'https://example.com/osaka_sekime_wine_2.jpg',
      'https://example.com/osaka_sekime_wine_3.jpg',
      'https://example.com/osaka_sekime_wine_4.jpg'
    ],
    drinkIds: ['oZTuXXMx1WaErBoCzYa1_duplicated'],
    drink_categories: ['0FavGaP6R45vr9DZLvrX', '2UHznlDW1nePaUxo5a0A']
  },
  {
    id: 'osaka_sekime_sake_004',
    name: '関目日本酒バル 和',
    address: '大阪府大阪市城東区関目4-7-20',
    lat: 34.7038,
    lng: 135.5552,
    category: '日本酒バル',
    openTime: '18:30',
    openHours: '18:30 - 23:30',
    imageUrl: 'https://example.com/osaka_sekime_sake.jpg',
    imageUrls: [
      'https://example.com/osaka_sekime_sake_1.jpg',
      'https://example.com/osaka_sekime_sake_2.jpg'
    ],
    drinkIds: ['oZTuXXMx1WaErBoCzYa1_duplicated'],
    drink_categories: ['8bXjiNMhwduF1pJv5Q8D', 'VNlK61wmGhxtcn9wqjBv']
  },
  {
    id: 'osaka_sekime_beer_005',
    name: 'クラフトビール 関目ブルワリー',
    address: '大阪府大阪市城東区関目5-3-12',
    lat: 34.7045,
    lng: 135.5559,
    category: 'ビアバー',
    openTime: '16:00',
    openHours: '16:00 - 24:00',
    imageUrl: 'https://example.com/osaka_sekime_beer.jpg',
    imageUrls: [
      'https://example.com/osaka_sekime_beer_1.jpg',
      'https://example.com/osaka_sekime_beer_2.jpg',
      'https://example.com/osaka_sekime_beer_3.jpg',
      'https://example.com/osaka_sekime_beer_4.jpg',
      'https://example.com/osaka_sekime_beer_5.jpg'
    ],
    drinkIds: ['oZTuXXMx1WaErBoCzYa1_duplicated'],
    drink_categories: ['bkEjjwPNtBsjqhOXGVoe', '2UHznlDW1nePaUxo5a0A']
  }
];

// drink_shop_linksデータ
const drinkShopLinks = [
  {
    drinkId: 'oZTuXXMx1WaErBoCzYa1_duplicated',
    shopId: 'osaka_sekime_bar_001',
    price: 850
  },
  {
    drinkId: 'oZTuXXMx1WaErBoCzYa1_duplicated',
    shopId: 'osaka_sekime_izakaya_002',
    price: 720
  },
  {
    drinkId: 'oZTuXXMx1WaErBoCzYa1_duplicated',
    shopId: 'osaka_sekime_wine_003',
    price: 950
  },
  {
    drinkId: 'oZTuXXMx1WaErBoCzYa1_duplicated',
    shopId: 'osaka_sekime_sake_004',
    price: 680
  },
  {
    drinkId: 'oZTuXXMx1WaErBoCzYa1_duplicated',
    shopId: 'osaka_sekime_beer_005',
    price: 780
  }
];

async function createOsakaSekimeShops() {
  try {
    console.log('🏪 大阪市城東区関目周辺の店舗データ作成開始...');
    
    // 確認プロンプト
    console.log('\n📋 作成予定データ:');
    console.log(`- shopsコレクション: ${osakaShops.length}件`);
    console.log(`- drink_shop_linksコレクション: ${drinkShopLinks.length}件`);
    console.log(`- 対象drinkId: oZTuXXMx1WaErBoCzYa1_duplicated`);
    console.log('\n店舗一覧:');
    osakaShops.forEach((shop, index) => {
      console.log(`${index + 1}. ${shop.name} (${shop.address})`);
    });
    
    // 実行確認（自動実行のためコメントアウト）
    // const readline = require('readline');
    // const rl = readline.createInterface({
    //   input: process.stdin,
    //   output: process.stdout
    // });
    // 
    // const answer = await new Promise(resolve => {
    //   rl.question('\n実行しますか？ (y/N): ', resolve);
    // });
    // rl.close();
    // 
    // if (answer.toLowerCase() !== 'y') {
    //   console.log('❌ 処理をキャンセルしました');
    //   return;
    // }

    console.log('\n🚀 データ作成開始...');

    // 1. shopsコレクションにデータを追加
    console.log('\n📍 shopsコレクションにデータを追加中...');
    const batch = db.batch();
    
    for (const shop of osakaShops) {
      const shopRef = db.collection('shops').doc(shop.id);
      
      // GeoPointオブジェクトを作成
      const shopData = {
        ...shop,
        location: new admin.firestore.GeoPoint(shop.lat, shop.lng)
      };
      
      batch.set(shopRef, shopData);
      console.log(`  ✅ ${shop.name} を追加`);
    }
    
    await batch.commit();
    console.log(`✅ shopsコレクションに ${osakaShops.length}件のデータを追加完了`);

    // 2. drink_shop_linksコレクションにデータを追加
    console.log('\n🔗 drink_shop_linksコレクションにデータを追加中...');
    const linkBatch = db.batch();
    
    for (const link of drinkShopLinks) {
      // ドキュメントIDを生成（drinkId_shopIdの形式）
      const docId = `${link.drinkId}_${link.shopId}`;
      const linkRef = db.collection('drink_shop_links').doc(docId);
      
      linkBatch.set(linkRef, link);
      console.log(`  🔗 ${link.shopId} (¥${link.price}) をリンク`);
    }
    
    await linkBatch.commit();
    console.log(`✅ drink_shop_linksコレクションに ${drinkShopLinks.length}件のデータを追加完了`);

    console.log('\n🎉 大阪市城東区関目周辺の店舗データ作成完了！');
    console.log('\n📊 作成結果:');
    console.log(`- shopsコレクション: ${osakaShops.length}件追加`);
    console.log(`- drink_shop_linksコレクション: ${drinkShopLinks.length}件追加`);
    console.log(`- 対象エリア: 大阪府大阪市城東区関目周辺`);
    console.log(`- 対象drinkId: oZTuXXMx1WaErBoCzYa1_duplicated`);

  } catch (error) {
    console.error('❌ エラーが発生しました:', error);
  } finally {
    // Firebase接続を終了
    admin.app().delete();
  }
}

// スクリプト実行
createOsakaSekimeShops();
