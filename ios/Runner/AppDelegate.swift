import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase設定 - 最初に呼び出す
    FirebaseApp.configure()
    
    // FCM設定
    Messaging.messaging().delegate = self
    
    // 通知許可のリクエスト
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings = UIUserNotificationSettings(
        types: [.alert, .badge, .sound],
        categories: nil
      )
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // FCMトークン取得時のコールバック
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM token: \(String(describing: fcmToken))")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
  
  // フォアグラウンドでの通知表示設定
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }
    completionHandler([[.alert, .badge, .sound]])
  }
  
  // 通知タップ時の処理
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }
    completionHandler()
  }
  
  // APNsトークンをFCMに渡す
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}