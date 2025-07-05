# Firestore カテゴリ更新スクリプト

このディレクトリには、Firestoreのデータを更新するためのスクリプトが含まれています。

## updateCategoryField.js

このスクリプトは、Firestoreの`categories`コレクション内のドキュメントの特定フィールドを配列で更新するために使用します。

### 前提条件

1. **Node.jsのインストール**
   - [Node.js公式サイト](https://nodejs.org/)からダウンロードしてインストール

2. **Firebase Admin SDKのインストール**
   ```bash
   npm install firebase-admin --save
   ```

3. **サービスアカウントキーの取得**
   - Firebase管理コンソール（https://console.firebase.google.com/）にアクセス
   - プロジェクトを選択し、「プロジェクト設定」→「サービスアカウント」に移動
   - 「新しい秘密鍵の生成」をクリックしてJSONファイルをダウンロード
   - ダウンロードしたJSONファイルをこのscriptsディレクトリに配置

4. **スクリプトの設定**
   - `updateCategoryField.js`ファイル内の以下の行を修正：
     ```javascript
     const serviceAccount = require('./path-to-your-serviceAccountKey.json');
     ```
     例えば：
     ```javascript
     const serviceAccount = require('./serviceAccountKey.json');
     ```

### 使用方法

#### コマンドラインからの実行

**1. ドキュメントIDで指定する場合**

```bash
node updateCategoryField.js <categoryId> <fieldName> <item1> <item2> ...
```

例：
```bash
# ウィスキーカテゴリのサブカテゴリを設定
node updateCategoryField.js whiskyCategory subcategories スコッチ アイリッシュ バーボン ジャパニーズ

# 日本酒カテゴリのサブカテゴリを設定
node updateCategoryField.js sakeCategory subcategories 純米 大吟醸 本醸造 にごり酒
```

**2. カテゴリ名で検索する場合 (--name フラグ使用)**

```bash
node updateCategoryField.js --name <categoryName> <fieldName> <item1> <item2> ...
```

例：
```bash
# 「ウイスキー」というnameフィールドを持つカテゴリのサブカテゴリを設定
node /Users/esumi_yuuki/Desktop/OSAKEL/store_map_app/scripts/updateCategoryField.js --name ウイスキー subcategories スコッチ カナディアン バーボン ジャパニーズ アイリッシュ その他

# 短いフラグを使用する場合
node updateCategoryField.js -n 日本酒 subcategories 純米 大吟醸 本醸造 にごり酒
```

**注意**: 同じ名前のカテゴリが見つからない場合は、新しいカテゴリが自動的に作成されます。

#### Node.jsコードからの使用

**1. ドキュメントIDで指定する場合**

```javascript
const { updateCategoryFieldWithArray } = require('./updateCategoryField');

// カテゴリID、フィールド名、配列データを指定して実行
updateCategoryFieldWithArray("whiskyCategory", "subcategories", ["スコッチ", "アイリッシュ", "バーボン", "ジャパニーズ"])
  .then(result => {
    console.log('更新成功:', result);
  })
  .catch(error => {
    console.error('更新失敗:', error);
  });
```

**2. カテゴリ名で検索する場合**

```javascript
const { updateCategoryFieldByNameWithArray } = require('./updateCategoryField');

// カテゴリ名、フィールド名、配列データを指定して実行
updateCategoryFieldByNameWithArray("ウイスキー", "subcategories", ["スコッチ", "アイリッシュ", "バーボン", "ジャパニーズ"])
  .then(result => {
    console.log('更新成功:', result);
    // 新規カテゴリが作成された場合はresult.newCategoryがtrue
    if (result.newCategory) {
      console.log('新規カテゴリ作成、ID:', result.categoryId);
    }
  })
  .catch(error => {
    console.error('更新失敗:', error);
  });
```

### パラメータ説明

#### ID指定モード
- **categoryId**: 更新するカテゴリのドキュメントID（例：`whiskyCategory`）
- **fieldName**: 更新するフィールド名（例：`subcategories`）
- **item1, item2, ...**: 配列に含める項目（例：`スコッチ`, `アイリッシュ`, `バーボン`）

#### 名前指定モード
- **--name または -n**: 名前ベースの検索を指定するフラグ
- **categoryName**: 更新するカテゴリのnameフィールドの値（例：`ウイスキー`）
- **fieldName**: 更新するフィールド名（例：`subcategories`）
- **item1, item2, ...**: 配列に含める項目

### トラブルシューティング

1. **認証エラー**
   - サービスアカウントキーのパスが正しいことを確認
   - サービスアカウントに適切な権限があることを確認

2. **「Error: Cannot find module 'firebase-admin'」エラー**
   - `npm install firebase-admin --save`を実行して依存パッケージをインストール

3. **Firestoreへの接続エラー**
   - インターネット接続が正常であることを確認
   - Firestoreがプロジェクトで有効になっていることを確認
