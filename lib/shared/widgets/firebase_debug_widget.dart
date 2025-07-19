import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebaseの初期化状態と認証状態を画面下部にオーバーレイ表示するWidget
class FirebaseDebugWidget extends StatefulWidget {
  /// アプリ本体
  final Widget child;

  /// 本番環境でもオーバーレイを表示するか
  final bool showInProduction;

  const FirebaseDebugWidget({
    Key? key,
    required this.child,
    this.showInProduction = false,
  }) : super(key: key);

  @override
  _FirebaseDebugWidgetState createState() => _FirebaseDebugWidgetState();
}

class _FirebaseDebugWidgetState extends State<FirebaseDebugWidget> {
  bool _visible = true;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  Future<void> _updateStatus() async {
    try {
      final apps = Firebase.apps;
      final isCoreInit = apps.isNotEmpty;
      bool authInit;
      bool hasUser;
      try {
        final auth = FirebaseAuth.instance;
        authInit = true;
        hasUser = auth.currentUser != null;
      } catch (_) {
        authInit = false;
        hasUser = false;
      }

      if (mounted) {
        setState(() {
          _status = {
            'core': isCoreInit,
            'apps': apps.map((a) => a.name).toList(),
            'auth': authInit,
            'user': hasUser,
            'time': DateTime.now().toIso8601String(),
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = {
            'error': e.toString(),
            'time': DateTime.now().toIso8601String(),
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 本番環境では非表示
    if (!widget.showInProduction && const bool.fromEnvironment('dart.vm.product')) {
      return widget.child;
    }
    // 閉じられていたら本体だけ
    if (!_visible) {
      return widget.child;
    }

    // Directionalityでラップして明示的にテキスト方向を指定
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildOverlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final bg = Colors.black.withOpacity(0.8);
    final textColor = Colors.white;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          color: bg,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🔧 Firebase Debug', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _updateStatus,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _visible = false),
                  ),
                ],
              ),
              Divider(color: Colors.white24),
              if (_status.containsKey('error'))
                Text('Error: ${_status['error']}', style: TextStyle(color: Colors.redAccent, fontSize: 12))
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _infoChip('Core', _status['core'] == true),
                    _infoChip('Apps: ${(_status['apps'] as List?)?.join(', ') ?? ''}', true),
                    _infoChip('Auth', _status['auth'] == true),
                    _infoChip('User', _status['user'] == true),
                    Text(_status['time'] ?? '', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, bool ok) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ok ? Icons.check_circle : Icons.error, size: 14, color: ok ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
