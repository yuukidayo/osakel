# 画面とファイルのマッピング

このドキュメントでは、OSAKELアプリの各画面とそれに対応するDartファイルの関係を説明します。

## 📱 メイン画面

### 1. カテゴリ一覧画面
- **ファイル**: `lib/screens/category_list_screen.dart`
- **説明**: アプリのホーム画面。お酒のカテゴリ一覧を表示
- **関連ウィジェット**: 
  - `lib/widgets/custom_app_bar.dart` - カスタムアプリバー
  - `lib/widgets/side_menu.dart` - サイドメニュー

### 2. サブカテゴリ画面
- **ファイル**: `lib/screens/subcategory_screen.dart`
- **説明**: 選択されたカテゴリのサブカテゴリとドリンク一覧を表示
- **サイズ**: 24KB（大きなファイル）

### 3. ドリンク詳細画面
- **ファイル**: `lib/screens/drink_detail_screen.dart`
- **説明**: 個別のお酒の詳細情報を表示
- **サイズ**: 22KB（大きなファイル）
- **関連**: `lib/utils/safe_data_utils.dart` - 安全なデータ取得

## 🗺️ マップ関連画面

### 4. メインのマップ画面
- **ファイル**: `lib/screens/map_screen_fixed.dart`
- **説明**: Google Mapでお店の位置を表示するメインのマップ画面
- **サイズ**: 14KB
- **機能**:
  - PageViewによるスワイプ可能な店舗カード表示
  - Firestoreからの店舗データ取得
  - カスタムマーカー生成
  - 店舗詳細画面への遷移
- **関連ウィジェット**:
  - `lib/widgets/shop_card_widget.dart` - 店舗カード
  - `lib/utils/custom_marker_generator.dart` - カスタムマーカー
  - `lib/services/firestore_service.dart` - データ取得

## 🏪 店舗関連画面

### 6. 店舗一覧画面
- **ファイル**: `lib/screens/shop_list_screen.dart`
- **説明**: お店の一覧を表示
- **サイズ**: 15KB
- **関連ウィジェット**: `lib/widgets/shop_card_widget.dart` - 店舗カード

### 7. 店舗詳細画面
- **ファイル**: `lib/screens/shop_detail_screen.dart`
- **説明**: 個別の店舗の詳細情報を表示

### 8. ストア詳細画面
- **ファイル**: `lib/screens/store_detail_screen.dart`
- **説明**: ストアの詳細情報とカルーセル表示
- **サイズ**: 15KB
- **依存関係**: `carousel_slider` パッケージ


## 💬 コメント関連画面

### 10. プロコメント画面
- **ファイル**: `lib/screens/pro_comments_screen.dart`
- **説明**: プロユーザーのコメントを表示

## 🔐 認証関連画面

### 11. ログイン画面
- **ファイル**: `lib/screens/auth/login_screen.dart`
- **説明**: ユーザーログイン
- **サイズ**: 10KB

### 12. サインアップ画面
- **ファイル**: `lib/screens/auth/signup_screen.dart`
- **説明**: 新規ユーザー登録
- **サイズ**: 10KB

### 13. パスワードリセット画面
- **ファイル**: `lib/screens/auth/forgot_password_screen.dart`
- **説明**: パスワード忘れ対応

### 14. ドリンク検索画面
- **ファイル**: `lib/screens/drinks/drink_search_screen.dart`
- **説明**: お酒の検索機能を提供する画面
- **機能**:
  - カテゴリとサブカテゴリによるフィルタリング
  - 詳細検索ボトムシート
  - Firestoreからのドリンクデータの取得と表示

## 👑 管理者画面

### 14. ドリンク追加画面
- **ファイル**: `lib/screens/admin/add_drink_screen.dart`
- **説明**: 管理者専用のお酒登録画面
- **サイズ**: 16KB
- **関連**:
  - `lib/widgets/admin_guard.dart` - 管理者権限チェック
  - `lib/models/admin_drink.dart` - 管理者用ドリンクモデル

## 🧩 共通ウィジェット

### カスタムアプリバー
- **ファイル**: `lib/widgets/custom_app_bar.dart`
- **使用画面**: カテゴリ一覧画面

### サイドメニュー
- **ファイル**: `lib/widgets/side_menu.dart`
- **機能**: ログアウト、管理者メニュー
- **サイズ**: 10KB

### 店舗ボトムシート
- **ファイル**: `lib/widgets/store_bottom_sheet.dart`
- **使用画面**: マップ画面
- **サイズ**: 11KB

### 価格マーカー
- **ファイル**: `lib/widgets/price_marker.dart`
- **使用画面**: マップ画面

### 店舗カード
- **ファイル**: `lib/widgets/shop_card_widget.dart`
- **使用画面**: 店舗一覧画面
- **サイズ**: 7KB

## 📊 データモデル

### ドリンクモデル
- **ファイル**: `lib/models/drink.dart`
- **説明**: お酒の基本情報

### 店舗モデル
- **ファイル**: `lib/models/shop.dart`
- **説明**: 店舗の基本情報

### カテゴリモデル
- **ファイル**: `lib/models/category.dart`
- **説明**: お酒のカテゴリ情報

### ユーザーモデル
- **ファイル**: `lib/models/user.dart`
- **説明**: ユーザー情報

### コメントモデル
- **ファイル**: `lib/models/comment.dart`
- **説明**: ユーザーコメント


### ドリンク-店舗リンクモデル
- **ファイル**: `lib/models/drink_shop_link.dart`
- **説明**: ドリンクと店舗の関連付け

### 管理者用ドリンクモデル
- **ファイル**: `lib/models/admin_drink.dart`
- **説明**: 管理者用のドリンク登録モデル

## 🔧 ユーティリティ

### 安全なデータ取得
- **ファイル**: `lib/utils/safe_data_utils.dart`
- **説明**: null安全な文字列・数値取得ヘルパー
- **使用画面**: ドリンク詳細画面

### 管理者ガード
- **ファイル**: `lib/widgets/admin_guard.dart`
- **説明**: 管理者権限チェック用ウィジェット

## 🚀 エントリーポイント

### メインファイル
- **ファイル**: `lib/main.dart`
- **説明**: アプリのエントリーポイント、ルーティング設定

## 📝 注意事項

1. **大きなファイル**: `subcategory_screen.dart`（24KB）と`drink_detail_screen.dart`（22KB）は特に大きなファイルです
2. **カルーセル**: `store_detail_screen.dart`では`carousel_slider`パッケージを使用
3. **認証**: 認証関連画面は`auth/`フォルダに整理
4. **管理者機能**: 管理者専用機能は`admin/`フォルダに整理
5. **null安全**: `safe_data_utils.dart`を使用してnullエラーを防止

## 🔄 画面遷移の流れ

```
ログイン → ドリンク検索画面
カテゴリ一覧 → サブカテゴリ → ドリンク詳細
              ↓
           メインのマップ画面 → 店舗詳細
              ↓
           店舗一覧 → 店舗詳細
```

このマッピングを参考に、各画面の修正や機能追加を行ってください。
