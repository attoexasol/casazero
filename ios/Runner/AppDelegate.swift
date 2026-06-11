import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Initialize Firebase (also attempted from Dart main.dart if not already configured)
    FirebaseApp.configure()

    // APNs + FCM: required for reliable FCM token generation on physical iOS devices
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self

    // Existing Flutter plugin registration
    GeneratedPluginRegistrant.register(with: self)

    // Existing MethodChannel setup
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let channel = FlutterMethodChannel(
      name: "com.example.casazero/file_opener",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "showOpenCancelConfirmation" {
        let args = call.arguments as? [String: Any]
        let title = args?["title"] as? String ?? "Open"
        let message = args?["message"] as? String ?? "Open this file?"
        self?.showNativeOpenCancelConfirmation(
          title: title,
          message: message,
          result: result
        )
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward APNs device token to Firebase Messaging
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("📱 APNs token registered: \(tokenString.prefix(20))...")
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNs token set for Firebase Messaging")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    print("❌ APNs token unavailable — FCM token may not be generated on this device")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  private func showNativeOpenCancelConfirmation(
    title: String,
    message: String,
    result: @escaping FlutterResult
  ) {
    guard let root = window?.rootViewController else {
      result(false)
      return
    }

    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
      result(false)
    })

    alert.addAction(UIAlertAction(title: "Open", style: .default) { _ in
      result(true)
    })

    root.present(alert, animated: true)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let token = fcmToken {
      print("🔥 FCM Registration Token received via delegate: \(token.prefix(20))...")
    } else {
      print("⚠️ FCM Registration Token is nil in delegate")
    }
  }
}
