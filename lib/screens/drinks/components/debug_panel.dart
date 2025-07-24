import 'package:flutter/material.dart';

class DebugPanel extends StatelessWidget {
  final int resultCount;
  final Map<String, dynamic> debugInfo;
  final VoidCallback onFirebaseConsoleOpen;

  const DebugPanel({
    super.key, 
    required this.resultCount,
    required this.debugInfo,
    required this.onFirebaseConsoleOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, size: 18),
              const SizedBox(width: 8),
              const Text('デバッグ情報', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('デバッグ情報を更新しました')),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(),
          Text('検索結果: $resultCount 件'),
          if (debugInfo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('クエリ時間: ${debugInfo['queryTime'] ?? 'N/A'}'),
            Text('インデックス: ${debugInfo['hasIndex'] ? '使用中' : '未使用'}'),
            if (debugInfo['hasIndex'] == false) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onFirebaseConsoleOpen,
                child: const Text('Firebase コンソールを開く'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
