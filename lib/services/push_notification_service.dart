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
    
    // FCMトークンの取得を試行
    try {
      // iOSシミュレータではトークンを取得できないため、エラー処理を追加
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('✅ FCM Token: $token');
      } else {
        debugPrint('⚠️ FCM Token is null');
      }
    } catch (e) {
      // iOSシミュレータではエラーが発生する場合がある
      debugPrint('❌ Error getting FCM token: $e');
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('ℹ️ Note: iOS simulators cannot receive push notifications.');
      }
    }
    
    // バックグラウンド通知を処理するための設定
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    if (Platform.isIOS) {
      try {
        // iOSシミュレータでも設定自体は正常に行える
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('✅ iOS notification presentation options set');
        
        // シミュレータか実機かを確認して表示
        bool isSimulator = !await _isPhysicalDevice();
        if (isSimulator) {
          debugPrint('⚠️ Running on iOS simulator - push notifications will not work');
        } else {
          try {
            // APNSトークンを引き出す試行 - 実機でのみ取得可能
            String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken != null) {
              debugPrint('✅ APNS token: $apnsToken');
            } else {
              debugPrint('⚠️ APNS token is null');
            }
          } catch (e) {
            debugPrint('❌ Error getting APNS token: $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Error setting iOS notification options: $e');
      }
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
  
  /// 実機かシミュレータかを判別する
  Future<bool> _isPhysicalDevice() async {
    if (Platform.isIOS) {
      // iOSの場合、特定のパターンをデバイス名で判断
      try {
        final deviceInfo = await _getDeviceInfo();
        // シミュレータでは "simulator" や "Simulator" が含まれることが多い
        return !(deviceInfo.toLowerCase().contains('simulator'));
      } catch (_) {
        // 判定できない場合は安全策でシミュレータとみなす
        return false;
      }
    }
    // iOS以外はとりあえず実機とみなす
    return true;
  }
  
  /// デバイス情報を取得する簡易的な方法
  Future<String> _getDeviceInfo() async {
    try {
      // シミュレータか判別する簡易的な方法
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
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
