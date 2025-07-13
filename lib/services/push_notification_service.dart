import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  // シングルトンパターン
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // 通知の初期化
  Future<void> init() async {
    // FCMからの通知権限をリクエスト
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    
    // FCMトークンの取得
    String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
    
    // バックグラウンド通知を処理するための設定
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    // ローカル通知の初期化
    await _initLocalNotifications();
    
    // フォアグラウンドでの通知ハンドリング
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });
    
    // バックグラウンドからフォアグラウンドに遷移した時の通知ハンドリング
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }
  
  // ローカル通知の初期化
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // 通知がタップされた時の処理
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }
  
  // フォアグラウンド時に通知を表示
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    
    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'],
      );
    }
  }
  
  // 通知がタップされた時の処理
  void _handleNotificationTap(RemoteMessage message) {
    final String? route = message.data['route'];
    final String? shopId = message.data['shopId'];
    final String? drinkId = message.data['drinkId'];
    
    // ここでナビゲーションを行う（例：特定の店舗ページや商品ページへ）
    debugPrint('Navigate to route: $route, shopId: $shopId, drinkId: $drinkId');
    
    // Navigator.pushNamed(context, route, arguments: {'shopId': shopId, 'drinkId': drinkId});
    // Note: ここでのコンテキスト取得はできないため、グローバルナビゲーションキーを使用するか
    // 別途ナビゲーションロジックを実装する必要があります
  }
  
  // 特定のトピックへの購読
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
  
  // トピックからの購読解除
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
  
  // FCMトークンの取得
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}

// バックグラウンドメッセージハンドラ
@pragma('vm:entry-point') // この行は必須です
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンド通知受信時の処理
  // バックグラウンドでは最小限の処理に留める
  debugPrint('Handling a background message: ${message.messageId}');
  
  // Note: ここでデータベース操作や重い処理は避けるべき
}
