import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// FirebaseMessagingはPushNotificationServiceを通じて間接的に使用
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/push_notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final PushNotificationService _notificationService = PushNotificationService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // FCMトークンを取得
  Future<void> _loadFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _notificationService.getToken();
      setState(() {
        _fcmToken = token;
      });
      
      // トークンをFirestoreに保存（実運用時に活用）
      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fcmToken': token,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error loading FCM token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FCMトークンの取得に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ローカル通知テスト送信
  Future<void> _sendLocalTestNotification() async {
    final title = _titleController.text.isNotEmpty ? _titleController.text : 'テスト通知';
    final body = _bodyController.text.isNotEmpty ? _bodyController.text : 'これはテスト通知です';

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0, // 通知ID
      title,
      body,
      platformChannelSpecifics,
      payload: 'test_notification',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('テスト通知を送信しました')),
    );
  }

  // トピック購読切り替え
  Future<void> _toggleTopicSubscription(String topic, bool subscribe) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (subscribe) {
        await _notificationService.subscribeToTopic(topic);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('トピック「$topic」を購読しました')),
        );
      } else {
        await _notificationService.unsubscribeFromTopic(topic);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('トピック「$topic」の購読を解除しました')),
        );
      }
    } catch (e) {
      debugPrint('Error toggling topic subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('トピック購読の変更に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // モノクロームデザインに合わせた色の設定
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('通知テスト'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FCMトークン表示
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FCMトークン',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF8A8A8A)),
                            ),
                            width: double.infinity,
                            child: Text(
                              _fcmToken ?? '読み込み中...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('更新'),
                              onPressed: _loadFCMToken,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ローカル通知テスト
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ローカル通知テスト',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: '通知タイトル',
                              labelStyle: TextStyle(color: Color(0xFF8A8A8A)),
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bodyController,
                            decoration: const InputDecoration(
                              labelText: '通知本文',
                              labelStyle: TextStyle(color: Color(0xFF8A8A8A)),
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('テスト通知を送信'),
                              onPressed: _sendLocalTestNotification,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // トピック購読管理
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'トピック購読管理',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTopicSubscriptionTile(
                            '新機能のお知らせ',
                            'new_features',
                            Icons.new_releases,
                          ),
                          _buildTopicSubscriptionTile(
                            'セール情報',
                            'sales',
                            Icons.local_offer,
                          ),
                          _buildTopicSubscriptionTile(
                            'おすすめ情報',
                            'recommendations',
                            Icons.star,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // トピック購読切り替えタイル
  Widget _buildTopicSubscriptionTile(String title, String topic, IconData icon) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'トピック: $topic',
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 12,
            ),
          ),
          value: false, // TODO: 購読状態の保存と取得
          onChanged: (value) async {
            setState(() {});
            await _toggleTopicSubscription(topic, value);
          },
          secondary: Icon(icon, color: Colors.black),
          activeColor: Colors.black,
        );
      },
    );
  }
}
