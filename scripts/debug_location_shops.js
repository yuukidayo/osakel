const admin = require('firebase-admin');

// Firebase Admin SDKの初期化
const serviceAccount = require('./osakel-app-firebase-adminsdk-fbsvc-fda666e37c.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 距離計算関数（Haversine公式）
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // 地球の半径（km）
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

async function debugLocationAndShops() {
  try {
    console.log('🔍 現在地付近の店舗表示問題デバッグ開始...\n');

    // 1. 利用可能なdrinkIdを確認
    console.log('📋 1. 利用可能なdrinkIdを確認');
    const drinksSnapshot = await db.collection('drinks').limit(5).get();
    console.log(`   - drinksコレクション: ${drinksSnapshot.docs.length}件`);
    
    const availableDrinkIds = [];
    drinksSnapshot.docs.forEach(doc => {
      availableDrinkIds.push(doc.id);
      console.log(`   - drinkId: ${doc.id}`);
    });

    // 2. 大阪関目周辺の店舗データを確認
    console.log('\n🏪 2. 大阪関目周辺の店舗データを確認');
    const shopsSnapshot = await db.collection('shops').get();
    console.log(`   - shopsコレクション総数: ${shopsSnapshot.docs.length}件`);
    
    const osakaShops = [];
    shopsSnapshot.docs.forEach(doc => {
      const shop = doc.data();
      if (shop.address && shop.address.includes('大阪')) {
        osakaShops.push({
          id: doc.id,
          name: shop.name,
          address: shop.address,
          lat: shop.lat,
          lng: shop.lng
        });
      }
    });
    
    console.log(`   - 大阪の店舗: ${osakaShops.length}件`);
    osakaShops.forEach(shop => {
      console.log(`   - ${shop.name} (${shop.lat}, ${shop.lng}) - ${shop.address}`);
    });

    // 3. drink_shop_linksの関連データを確認
    console.log('\n🔗 3. drink_shop_linksの関連データを確認');
    const testDrinkId = 'oZTuXXMx1WaErBoCzYa1_duplicated';
    const linksSnapshot = await db.collection('drink_shop_links')
      .where('drinkId', '==', testDrinkId)
      .get();
    
    console.log(`   - drinkId "${testDrinkId}" のリンク: ${linksSnapshot.docs.length}件`);
    
    const linkedShopIds = [];
    linksSnapshot.docs.forEach(doc => {
      const link = doc.data();
      linkedShopIds.push(link.shopId);
      console.log(`   - shopId: ${link.shopId}, price: ¥${link.price}`);
    });

    // 4. 現在地からの距離計算（仮の現在地として東京駅を使用）
    console.log('\n📍 4. 現在地からの距離計算');
    const testLocation = {
      lat: 35.6812, // 東京駅
      lng: 139.7671,
      name: '東京駅（テスト用現在地）'
    };
    
    console.log(`   - テスト現在地: ${testLocation.name} (${testLocation.lat}, ${testLocation.lng})`);
    
    // 大阪の店舗との距離を計算
    osakaShops.forEach(shop => {
      const distance = calculateDistance(testLocation.lat, testLocation.lng, shop.lat, shop.lng);
      console.log(`   - ${shop.name}まで: ${distance.toFixed(2)}km`);
    });

    // 5. 大阪関目周辺での距離計算
    console.log('\n🎯 5. 大阪関目周辺での距離計算');
    const sekimeLocation = {
      lat: 34.7024, // 関目周辺
      lng: 135.5538,
      name: '大阪市城東区関目'
    };
    
    console.log(`   - 関目周辺: ${sekimeLocation.name} (${sekimeLocation.lat}, ${sekimeLocation.lng})`);
    
    const nearbyShops = [];
    osakaShops.forEach(shop => {
      const distance = calculateDistance(sekimeLocation.lat, sekimeLocation.lng, shop.lat, shop.lng);
      if (distance <= 5.0) {
        nearbyShops.push({
          ...shop,
          distance: distance
        });
      }
      console.log(`   - ${shop.name}まで: ${distance.toFixed(2)}km ${distance <= 5.0 ? '✅' : '❌'}`);
    });

    // 6. 検索結果のシミュレーション
    console.log('\n🔍 6. 検索結果のシミュレーション');
    console.log(`   - 関目周辺5km圏内の店舗: ${nearbyShops.length}件`);
    
    if (nearbyShops.length > 0) {
      console.log('   - 該当店舗:');
      nearbyShops.forEach(shop => {
        const isLinked = linkedShopIds.includes(shop.id);
        console.log(`     - ${shop.name} (${shop.distance.toFixed(2)}km) ${isLinked ? '🔗リンクあり' : '❌リンクなし'}`);
      });
    } else {
      console.log('   - 該当店舗なし');
    }

    // 7. 問題の特定
    console.log('\n🚨 7. 問題の特定');
    
    if (osakaShops.length === 0) {
      console.log('   ❌ 問題: 大阪の店舗データが存在しません');
    } else if (nearbyShops.length === 0) {
      console.log('   ❌ 問題: 関目周辺5km圏内に店舗がありません');
    } else if (linkedShopIds.length === 0) {
      console.log('   ❌ 問題: drink_shop_linksにデータがありません');
    } else {
      const linkedNearbyShops = nearbyShops.filter(shop => linkedShopIds.includes(shop.id));
      if (linkedNearbyShops.length === 0) {
        console.log('   ❌ 問題: 関目周辺の店舗とdrinkIdのリンクがありません');
      } else {
        console.log('   ✅ データは正常: アプリの検索ロジックを確認してください');
        console.log(`   - 表示されるべき店舗: ${linkedNearbyShops.length}件`);
      }
    }

    console.log('\n🎉 デバッグ調査完了');

  } catch (error) {
    console.error('❌ デバッグエラー:', error);
  } finally {
    admin.app().delete();
  }
}

// スクリプト実行
debugLocationAndShops();
