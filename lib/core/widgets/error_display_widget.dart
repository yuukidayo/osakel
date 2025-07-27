import 'package:flutter/material.dart';

/// Firebase接続エラーやデータ取得エラーを表示するウィジェット
class ErrorDisplayWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onRetry;
  final VoidCallback? onFallback;
  final bool showDetails;

  const ErrorDisplayWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.onRetry,
    this.onFallback,
    this.showDetails = false,
  });

  /// Firebase接続エラー用のファクトリコンストラクタ
  factory ErrorDisplayWidget.firebaseConnection({
    VoidCallback? onRetry,
    bool showDetails = false,
  }) {
    return ErrorDisplayWidget(
      title: 'サーバーとの接続に問題があります',
      message: 'インターネット接続を確認して、もう一度お試しください。\n問題が続く場合は、時間をおいて再度アクセスしてください。',
      icon: Icons.cloud_off,
      iconColor: Colors.orange,
      onRetry: onRetry,
      showDetails: showDetails,
    );
  }

  /// データ取得エラー用のファクトリコンストラクタ
  factory ErrorDisplayWidget.dataFetch({
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onFallback,
    bool showDetails = false,
  }) {
    return ErrorDisplayWidget(
      title: 'データの読み込みに失敗しました',
      message: customMessage ?? 'データを取得できませんでした。\nネットワーク接続を確認して、再試行してください。',
      icon: Icons.sync_problem,
      iconColor: Colors.red[400],
      onRetry: onRetry,
      onFallback: onFallback,
      showDetails: showDetails,
    );
  }

  /// 権限エラー用のファクトリコンストラクタ
  factory ErrorDisplayWidget.permission({
    VoidCallback? onRetry,
    bool showDetails = false,
  }) {
    return ErrorDisplayWidget(
      title: 'アクセス権限がありません',
      message: 'このデータにアクセスする権限がありません。\nログインしている場合は、管理者にお問い合わせください。',
      icon: Icons.lock_outline,
      iconColor: Colors.amber[700],
      onRetry: onRetry,
      showDetails: showDetails,
    );
  }

  /// 一般的なエラー用のファクトリコンストラクタ
  factory ErrorDisplayWidget.generic({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool showDetails = false,
  }) {
    return ErrorDisplayWidget(
      title: title ?? '予期しないエラーが発生しました',
      message: message ?? 'システムエラーが発生しました。\n時間をおいて再度お試しください。',
      icon: Icons.warning_amber,
      iconColor: Colors.red,
      onRetry: onRetry,
      showDetails: showDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // エラーアイコン
          Icon(
            icon,
            size: 64,
            color: iconColor ?? Colors.red[400],
          ),
          const SizedBox(height: 16),
          
          // エラータイトル
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // エラーメッセージ
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onRetry != null) ...[
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                if (onFallback != null) const SizedBox(width: 12),
              ],
              
              if (onFallback != null)
                OutlinedButton.icon(
                  onPressed: onFallback,
                  icon: const Icon(Icons.offline_bolt),
                  label: const Text('オフラインモード'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
          
          // デバッグ情報（開発時のみ）
          if (showDetails) ...[
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text(
                '詳細情報（開発者向け）',
                style: TextStyle(fontSize: 14),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Type: ${_getErrorType()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Timestamp: ${DateTime.now().toIso8601String()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Troubleshooting Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._getTroubleshootingSteps().map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 2),
                          child: Text(
                            '• $step',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorType() {
    if (icon == Icons.cloud_off) return 'CONNECTION_ERROR';
    if (icon == Icons.sync_problem) return 'DATA_FETCH_ERROR';
    if (icon == Icons.lock_outline) return 'PERMISSION_ERROR';
    return 'GENERIC_ERROR';
  }

  List<String> _getTroubleshootingSteps() {
    switch (_getErrorType()) {
      case 'CONNECTION_ERROR':
        return [
          'インターネット接続を確認',
          'WiFi/モバイルデータの切り替え',
          'アプリの再起動',
          'デバイスの再起動',
        ];
      case 'DATA_FETCH_ERROR':
        return [
          'ネットワーク接続を確認',
          'アプリの再起動',
          'キャッシュのクリア',
          'Firebase接続状態の確認',
        ];
      case 'PERMISSION_ERROR':
        return [
          'ログイン状態を確認',
          'アカウント権限を確認',
          '管理者への問い合わせ',
          'アプリの再ログイン',
        ];
      default:
        return [
          'アプリの再起動',
          'デバイスの再起動',
          'アプリの更新確認',
          '開発者への報告',
        ];
    }
  }
}

/// ローディング状態とエラー状態を組み合わせたウィジェット
class LoadingErrorWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget child;
  final String loadingMessage;

  const LoadingErrorWidget({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.loadingMessage = 'データを読み込み中...',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              loadingMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return ErrorDisplayWidget.dataFetch(
        customMessage: errorMessage,
        onRetry: onRetry,
        showDetails: true,
      );
    }

    return child;
  }
}

/// エラー情報を含むスナックバーを表示するヘルパー
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? action,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: duration,
        action: action != null && onAction != null
            ? SnackBarAction(
                label: action,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Firebase関連のエラー用
  static void showFirebaseError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    show(
      context,
      message: customMessage ?? 'サーバーとの接続に問題が発生しました',
      action: onRetry != null ? '再試行' : null,
      onAction: onRetry,
    );
  }

  /// データ取得エラー用
  static void showDataError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    show(
      context,
      message: customMessage ?? 'データの読み込みに失敗しました',
      action: onRetry != null ? '再試行' : null,
      onAction: onRetry,
    );
  }
}