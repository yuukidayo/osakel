import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// バックグラウンド通知を処理するグローバルハンドラ
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase初期化が必要な場合はここで行う
  // await Firebase.initializeApp();
  debugPrint('バックグラウンドメッセージ受信: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  // FCMサービスの初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // バックグラウンドハンドラーの登録（Firebase.initializeApp前に行う必要がある）
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // 通知権限の要求
      await _requestPermissions();
      
      // 通知ハンドラーの設定
      _setupNotificationHandlers();
      
      // ローカル通知の初期化
      await _initializeLocalNotifications();
      
      // FCMトークン取得と表示
      String? token = await _messaging.getToken();
      debugPrint('FCMトークン: $token');
      
      _isInitialized = true;
      debugPrint('FCMサービス初期化完了');
    } catch (e) {
      debugPrint('FCMサービス初期化エラー: $e');
    }
  }
  
  // 通知権限のリクエスト
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('iOS通知許可ステータス: ${settings.authorizationStatus}');
    } 
  }
  
  // 通知ハンドラーの設定
  void _setupNotificationHandlers() {
    // フォアグラウンド通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('フォアグラウンドメッセージ受信: ${message.notification?.title}');
      _showLocalNotification(message);
    });
    
    // アプリが閉じられた状態からの起動
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('初期メッセージ: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
    
    // バックグラウンドからの復帰
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('通知タップでアプリが開かれました: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }
  
  // ローカル通知の初期化
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) {
        // iOS 10未満での処理（現在ではほぼ使用されない）
        debugPrint('iOS 10未満のローカル通知: $title');
        return;
      }
    );
    
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('ローカル通知タップ: ${details.payload}');
      },
    );
    
    // Android通知チャネルの作成
    if (Platform.isAndroid) {
      await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        ),
      );
    }
  }
  
  // ローカル通知の表示
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null) {
      _localNotifications.show(
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
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
  
  // 通知タップ時の処理
  void _handleNotificationTap(RemoteMessage message) {
    // 画面遷移などの処理をここに実装
    // 例: NavigationService.navigateTo('/notification-details', arguments: message.data);
  }
  
  // FCMトークンの取得
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  // FCMトークン更新リスナーの設定
  void setupTokenRefreshListener(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen((String token) {
      debugPrint('FCMトークン更新: $token');
      onTokenRefresh(token);
    });
  }
}