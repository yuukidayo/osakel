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
    // iOS向けの初期設定 - 先に行うことでAPNSTokenの取得成功率が上がる
    if (Platform.isIOS) {
      try {
        // iOS通知設定 - トークン取得前に行う
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('✅ iOS notification presentation options set');
      } catch (e) {
        debugPrint('❌ Error setting iOS notification options: $e');
      }
    }

    // 通知権限をリクエスト - 必ず最初に行う
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true, // 重要通知も許可する
      );
      debugPrint('✅ User notification permission status: ${settings.authorizationStatus}');
      
      // 権限の確認
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted full notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional notification permission');
      } else {
        debugPrint('⚠️ User declined notification permission');
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
    }
    
    // バックグラウンド通知を処理するための設定
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 少し待機してからFCMトークン取得を試行
    await Future.delayed(const Duration(milliseconds: 500));
    
    // FCMトークンの取得を試行
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('✅ FCM Token: $token');
      } else {
        debugPrint('⚠️ FCM Token is null - waiting and trying again');
        
        // 再度待機して再試行
        await Future.delayed(const Duration(seconds: 1));
        token = await _fcm.getToken();
        if (token != null) {
          debugPrint('✅ FCM Token on second attempt: $token');
        } else {
          debugPrint('❌ FCM Token still null after retry');
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('ℹ️ On iOS devices, check the following:');
        debugPrint('ℹ️ 1. Ensure FirebaseAppDelegateProxyEnabled is set to true in Info.plist');
        debugPrint('ℹ️ 2. Verify you have a valid provisioning profile with push capability');
        debugPrint('ℹ️ 3. iOS simulators cannot receive push notifications');
      }
    }
    
    if (Platform.isIOS) {
      // シミュレータか実機かを確認して表示
      bool isSimulator = !await _isPhysicalDevice();
      if (isSimulator) {
        debugPrint('⚠️ Running on iOS simulator - push notifications will not work properly');
      } else {
        debugPrint('✅ Running on iOS physical device - attempting to get APNS token directly');
        // 実機の場合は直接APNSトークンを試行
        try {
          // APNSトークン取得を再試行
          String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            debugPrint('✅ APNS token successfully retrieved: $apnsToken');
            // APNSトークン取得後に再度FCMトークンを取得し直すと成功する可能性が高い
            try {
              String? fcmToken = await _fcm.getToken();
              if (fcmToken != null) {
                debugPrint('✅ FCM Token after APNS token retrieval: $fcmToken');
              }
            } catch (e) {
              debugPrint('❌ Still could not get FCM token after APNS token: $e');
            }
          } else {
            debugPrint('⚠️ APNS token is null - check provisioning profile');
          }
        } catch (e) {
          debugPrint('❌ Error getting APNS token: $e');
        }
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
