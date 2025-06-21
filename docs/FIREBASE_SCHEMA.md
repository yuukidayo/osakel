# Firebase Firestore Schema

## Collections

### alcohols
お酒の詳細情報を格納するコレクション

```yaml
alcohols/{alcoholId}:
  name: string                    # お酒の名前
  name_en: string                # お酒の英語名
  countryRef: reference          # 生産国への参照 (→ countries/{countryId})
  region: string                 # 生産地域
  category: string               # お酒のカテゴリ（ビール、ワイン、日本酒など）
  alcohol_percentage: number     # アルコール度数
  series: string                 # シリーズ名
  type: string                   # タイプ（ラガー、IPAなど）
  subcategoryId: string          # サブカテゴリID
  categoryId: string             # カテゴリID
  imageUrl: string               # 画像URL
  description: string            # 説明
  createdAt: timestamp           # 作成日時
  updatedAt: timestamp           # 更新日時
```

### countries
国情報を格納するコレクション

```yaml
countries/{countryId}:
  name: string                   # 国名（日本語）例: "ドイツ"
  name_en: string               # 国名（英語）例: "Germany"
  code: string                  # 国コード（ISO 3166-1 alpha-2）例: "DE"
  flag_emoji: string            # 国旗絵文字 例: "🇩🇪"
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

### drinks
ドリンク情報を格納するコレクション

```yaml
drinks/{drinkId}:
  name: string                  # ドリンク名
  type: string                  # タイプ
  categoryId: string            # カテゴリID
  subcategoryId: string         # サブカテゴリID
  imageUrl: string              # 画像URL
  description: string           # 説明
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

### shops
店舗情報を格納するコレクション

```yaml
shops/{shopId}:
  name: string                  # 店舗名
  address: string               # 住所
  location: geopoint            # 位置情報
  category: string              # カテゴリ
  openTime: string              # 営業開始時間
  closeTime: string             # 営業終了時間
  imageUrl: string              # メイン画像URL
  imageURL: string              # 代替画像URL
  imageUrls: array<string>      # 複数画像URL
  drinkIds: array<string>       # 提供ドリンクIDリスト
  distance: number              # 距離（メートル）
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

### categories
カテゴリ情報を格納するコレクション

```yaml
categories/{categoryId}:
  name: string                  # カテゴリ名
  description: string           # 説明
  imageUrl: string              # 画像URL
  order: number                 # 表示順序
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

### users
ユーザー情報を格納するコレクション

```yaml
users/{userId}:
  id: string                    # ユーザーID
  name: string                  # ユーザー名
  email: string                 # メールアドレス
  role: string                  # ロール（管理者、一般ユーザーなど）
  shopId: string                # 関連店舗ID（プロユーザーの場合）
  isPro: boolean                # プロユーザーフラグ
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

### comments
コメント情報を格納するコレクション

```yaml
comments/{commentId}:
  userId: string                # コメント投稿者ID
  drinkId: string               # 対象ドリンクID
  comment: string               # コメント内容
  rating: number                # 評価（1-5）
  isPro: boolean                # プロコメントフラグ
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

### drink_shop_links
ドリンクと店舗の関連を格納するコレクション

```yaml
drink_shop_links/{linkId}:
  drinkId: string               # ドリンクID
  shopId: string                # 店舗ID
  categoryId: string            # カテゴリID
  price: number                 # 価格
  available: boolean            # 提供可能フラグ
  createdAt: timestamp          # 作成日時
  updatedAt: timestamp          # 更新日時
```

## 参照関係

### alcohols → countries
- `alcohols.countryRef` は `countries/{countryId}` への参照
- 使用例：
  ```dart
  final countryRef = alcoholDoc['countryRef'] as DocumentReference;
  final countrySnap = await countryRef.get();
  final countryName = countrySnap['name'] as String;
  ```

### users → shops
- `users.shopId` は `shops/{shopId}` への参照（文字列）

### drink_shop_links → drinks, shops
- `drink_shop_links.drinkId` は `drinks/{drinkId}` への参照（文字列）
- `drink_shop_links.shopId` は `shops/{shopId}` への参照（文字列）

### comments → users, drinks
- `comments.userId` は `users/{userId}` への参照（文字列）
- `comments.drinkId` は `drinks/{drinkId}` への参照（文字列）
