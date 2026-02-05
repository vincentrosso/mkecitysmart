import Flutter
import UIKit
import Firebase
import FirebaseAuth
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    print("[AppDelegate] App launched, requesting push notification permissions...")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("[AppDelegate] ✅ APNs token received: \(tokenString.prefix(20))...")
    
    // Set APNs token for Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    print("[AppDelegate] ✅ APNs token set for Firebase Messaging")
    
    // Set APNs token for Firebase Auth (required for phone verification)
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    print("[AppDelegate] ✅ APNs token set for Firebase Auth")
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[AppDelegate] ❌ Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // Handle silent push notifications for phone auth verification
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("[AppDelegate] 📩 Received remote notification: \(userInfo)")
    
    // Let Firebase Auth handle the notification if it's for phone auth
    if Auth.auth().canHandleNotification(userInfo) {
      print("[AppDelegate] ✅ Firebase Auth handled the notification (phone verification)")
      completionHandler(.noData)
      return
    }
    print("[AppDelegate] ℹ️ Notification not for Firebase Auth, passing to parent")
    // Otherwise, let the parent handle it
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}
