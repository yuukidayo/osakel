# アカウント登録画面デザイン仕様書

## 概要
OSAKELアプリのアカウント登録画面の高精度デザイン仕様書です。モノクロームパレットを使用したモダンでユーザーフレンドリーなデザインを実装します。

## デザイン原則
- **モノクロームパレット**: 黒 #000000、白 #FFFFFF、グレー #F5F5F5/#CCCCCC/#666666のみ使用
- **一貫性**: 16pxの統一された余白とギャップ
- **アクセシビリティ**: 適切なコントラスト比とタップターゲットサイズ
- **モダンデザイン**: 角丸とシャドウによる洗練された外観

## 全体フレーム仕様

### デバイスアートボード
- **角丸**: 12px
- **背景色**: 白 #FFFFFF
- **セーフエリア**: 全周16px
- **セクション間ギャップ**: 16px

## コンポーネント仕様

### 1. ブランドヘッダー
```
要素: "OSAKEL" ロゴテキスト
位置: 中央揃え
フォントサイズ: 24sp
フォントウェイト: Semi-bold
色: 黒 #000000
左右アイコン: なし
```

### 2. メール・パスワードセクション

#### セクションタイトル
```
テキスト: "Sign up with Email"
フォントサイズ: 16sp
フォントウェイト: Semi-bold
色: #333333
```

#### 入力フィールド（2つ）
```
配置: 縦積み（12px垂直ギャップ）
幅: アートボード幅 - 32px
高さ: 56px
背景色: #F5F5F5
角丸: 12px
プレースホルダー:
  - "Email address"
  - "Password"
プレースホルダーフォント: 16sp Regular, #666666
```

#### パスワードフィールド特殊仕様
```
右端アイコン: 目のアイコン（表示/非表示切り替え）
アイコンサイズ: 24x24px
アイコン色: #666666
```

### 3. プライマリアクションボタン

#### "Sign Up" ボタン
```
幅: フル幅 - 32px
高さ: 56px
背景色: 黒 #000000
角丸: 12px
テキスト: "Sign Up"
テキストフォント: 16sp Medium
テキスト色: 白 #FFFFFF
シャドウ: Y-offset 2px, blur 8px, rgba(0,0,0,0.1)
```

#### プレス状態
```
背景色: 10%暗くした黒
その他の仕様は同じ
```

### 4. 区切り線

#### 水平線とテキスト
```
左右線: 1px #CCCCCC
中央テキスト: "or"
テキストフォント: 14sp Regular
テキスト色: #666666
上下パディング: 16px
```

### 5. ソーシャルサインアップボタン

#### "Continue with Google" ボタン
```
幅: フル幅 - 32px
高さ: 56px
背景色: 白 #FFFFFF
ボーダー: 2px 黒 #000000
角丸: 12px
左アイコン: Google "G" (24x24px)
テキスト: "Continue with Google"
テキストフォント: 16sp Medium
テキスト色: 黒 #000000
シャドウ: プライマリボタンと同じ
```

#### プレス状態
```
ボーダー色: 10%暗くした黒
テキスト色: 10%暗くした黒
その他の仕様は同じ
```

## レイアウト構成

### 縦方向の配置順序
1. ブランドヘッダー (上部)
2. 16px ギャップ
3. メール・パスワードセクション
4. 16px ギャップ
5. プライマリアクションボタン
6. 16px ギャップ
7. 区切り線
8. 16px ギャップ
9. ソーシャルサインアップボタン

### 横方向の配置
- 全要素: 16px左右マージン
- テキスト: 中央揃え（ブランドヘッダー、区切り線テキスト）
- ボタン・フィールド: フル幅（マージン除く）

## 状態管理

### デフォルト状態
- 全要素が上記仕様通りに表示
- 入力フィールドは空
- パスワードは非表示状態

### インタラクション状態
- ボタンプレス時の視覚フィードバック
- パスワード表示/非表示切り替え
- フォーカス状態の視覚表現

## 実装上の注意点

### Flutter実装時の考慮事項
1. **レスポンシブ対応**: 異なる画面サイズでの適切な表示
2. **アクセシビリティ**: スクリーンリーダー対応
3. **バリデーション**: リアルタイム入力検証
4. **ローディング状態**: ボタン押下時のローディング表示
5. **エラーハンドリング**: 適切なエラーメッセージ表示

### 技術仕様
- **フレームワーク**: Flutter
- **状態管理**: Provider/Riverpod
- **認証**: Firebase Auth
- **バリデーション**: form_field_validator
- **アニメーション**: Flutter標準アニメーション

## デザインシステム連携

この仕様は既存のOSAKELアプリのデザインシステムと整合性を保ち、他の画面との一貫性を確保します。

### 共通コンポーネント
- InputField
- PrimaryButton
- SecondaryButton
- BrandHeader
- Divider

### カラーパレット
```dart
class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFCCCCCC);
  static const Color darkGray = Color(0xFF666666);
  static const Color textPrimary = Color(0xFF333333);
}
```

### タイポグラフィ
```dart
class AppTextStyles {
  static const TextStyle brandTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle placeholder = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGray,
  );
}
```

## 次のステップ

1. **Flutter実装**: この仕様書に基づくFlutterウィジェットの実装
2. **AuthService連携**: 3権限システムとの統合
3. **バリデーション実装**: フォーム検証ロジックの追加
4. **テスト**: ユーザビリティテストとA/Bテスト
5. **最適化**: パフォーマンス最適化とアクセシビリティ改善
