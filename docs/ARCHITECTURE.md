# OSAKEL アプリケーション アーキテクチャ

## プロジェクト構成

OSAKEL アプリケーションは Flutter フレームワークを使用した、iOS および Android 向けのモバイルアプリケーションです。

### ディレクトリ構造

```
lib/
├── models/ - データモデルクラス
├── screens/ - 画面UI
│   └── admin/ - 管理者向け画面
├── services/ - ビジネスロジックとAPI連携
├── widgets/ - 再利用可能なUI部品
└── main.dart - アプリケーションのエントリポイント
```

## データ処理

### Firestore データモデル

アプリケーションのデータモデルは `models/` ディレクトリに定義されています。各モデルクラスは Firestore ドキュメントとの変換ロジックを含んでいます。

詳細なコレクション構造については `docs/FIREBASE_SCHEMA.md` を参照してください。

### データ取得・パース

#### 数値フィールドの処理

Firestore や API からのレスポンスでは、数値フィールドが `int` 型または `double` 型として返される可能性があります。型の不一致によるエラーを防ぐため、以下のパターンに従ってください：

**✅ 推奨パターン: `as num` + `toDouble()`**

```dart
// 推奨: numとしてキャストし、toDouble()でdoubleに変換
final num rawValue = data['value'] as num;
final double value = rawValue.toDouble();

// または 1行で
final double value = (data['value'] as num).toDouble();
```

**✅ 代替パターン: 条件分岐による型チェック**

```dart
double value;
if (data['value'] is double) {
  value = data['value'];
} else if (data['value'] is int) {
  value = (data['value'] as int).toDouble();
} else {
  value = 0.0; // デフォルト値
}
```

**❌ 非推奨: 直接 `as double` キャスト**

```dart
// 非推奨: intが来た場合に例外が発生
final double value = data['value'] as double; 
```

#### null安全な数値変換

null 値の可能性がある場合は、null チェックを追加するか、null 合体演算子（??）を使用してください：

```dart
// null可能なフィールドの処理
final num? rawValue = data['value'] as num?;
final double value = rawValue?.toDouble() ?? 0.0;

// または 1行で
final double value = ((data['value'] as num?) ?? 0).toDouble();
```

### ビジネスロジックの計算

整数除算（`~/`）は結果が必ず整数になるため、`double` 型を期待する箇所では浮動小数点除算（`/`）を使用してください：

```dart
// 推奨: 浮動小数点除算
final double average = total / count;

// 非推奨: 整数除算を使用後にキャスト
final double average = (total ~/ count).toDouble();
```

## UI アーキテクチャ

### 状態管理

アプリケーションでは主に StatefulWidget を使用した状態管理を行っています。複雑な画面では以下のパターンに従っています：

1. `initState()` で初期データの読み込み
2. 非同期データ取得中の `_isLoading` フラグによるローディング表示
3. エラー処理とユーザーへのフィードバック

### コンポーネント設計

再利用可能なUIコンポーネントは `widgets/` ディレクトリに配置し、画面固有のUIは各画面クラス内に定義しています。

## テスト戦略

### 単体テスト

数値変換ロジックなど、データパースに関するテストは特に重要です。特にFirestoreや外部APIからのデータ取得部分では、様々な型のデータが返される可能性を考慮したテストケースを作成してください。

**例: 数値変換のテスト**

```dart
test('should handle int to double conversion', () {
  // Given
  final Map<String, dynamic> data = {'price': 100}; // intとして値を設定
  
  // When
  final drink = Drink.fromMap('test', data);
  
  // Then
  expect(drink.price, 100.0);
  expect(drink.price.runtimeType, double);
});
```

## セキュリティとパフォーマンス

### Firebase Security Rules

Firestore データベースアクセスはセキュリティルールによって保護されています。ユーザー認証と適切な権限チェックを行うようにしてください。

### パフォーマンス最適化

- 大きなリストデータの取得にはページネーションを使用
- 不要なFirestoreクエリの実行回数を最小限に抑える
- 画像の適切なキャッシュと最適化

## 今後の改善予定

- 状態管理の改善（Provider/Riverpod への移行検討）
- 型安全性の向上
- テストカバレッジの拡大
