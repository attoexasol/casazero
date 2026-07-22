import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentInteractionControllerDelegate {
  private var documentInteractionController: UIDocumentInteractionController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Initialize Firebase (also attempted from Dart main.dart if not already configured)
    FirebaseApp.configure()

    // Register plugins before wiring delegates so firebase_messaging /
    // flutter_local_notifications can share FlutterAppDelegate correctly.
    GeneratedPluginRegistrant.register(with: self)

    // APNs + FCM: required for reliable FCM token generation on physical iOS devices.
    // FlutterAppDelegate forwards UNUserNotificationCenter tap events to plugins
    // (getInitialMessage / onMessageOpenedApp / local notification callbacks).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self

    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // MethodChannel after Flutter engine / root VC exist.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.example.casazero/file_opener",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] (call, result) in
        switch call.method {
        case "showOpenCancelConfirmation":
          let args = call.arguments as? [String: Any]
          let title = args?["title"] as? String ?? "Open"
          let message = args?["message"] as? String ?? "Open this file?"
          self?.showNativeOpenCancelConfirmation(
            title: title,
            message: message,
            result: result
          )
        case "openWithChooser":
          guard let args = call.arguments as? [String: Any],
                let filePath = args["filePath"] as? String else {
            result(FlutterError(
              code: "INVALID_ARGUMENT",
              message: "File path is null",
              details: nil
            ))
            return
          }
          self?.openFileWithChooser(filePath: filePath, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return ok
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

  private func openFileWithChooser(filePath: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: filePath)
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(["type": "fileNotFound", "message": "File not found"])
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let rootVC = self.window?.rootViewController else {
        result(["type": "error", "message": "No root view controller"])
        return
      }

      let docController = UIDocumentInteractionController(url: fileURL)
      docController.delegate = self
      self.documentInteractionController = docController

      let rect = CGRect(
        x: rootVC.view.bounds.midX,
        y: rootVC.view.bounds.midY,
        width: 1,
        height: 1
      )

      if docController.presentOpenInMenu(from: rect, in: rootVC.view, animated: true) {
        result(["type": "done", "message": "Chooser shown successfully"])
        return
      }

      if docController.presentOptionsMenu(from: rect, in: rootVC.view, animated: true) {
        result(["type": "done", "message": "Chooser shown successfully"])
        return
      }

      let activityVC = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )
      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = rootVC.view
        popover.sourceRect = rect
        popover.permittedArrowDirections = []
      }
      rootVC.present(activityVC, animated: true) {
        result(["type": "done", "message": "Chooser shown successfully"])
      }
    }
  }

  func documentInteractionControllerDidDismissOpenInMenu(
    _ controller: UIDocumentInteractionController
  ) {
    documentInteractionController = nil
  }

  func documentInteractionControllerDidDismissOptionsMenu(
    _ controller: UIDocumentInteractionController
  ) {
    documentInteractionController = nil
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
