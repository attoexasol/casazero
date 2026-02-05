import UIKit
import Flutter
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ REQUIRED: Initialize Firebase
    FirebaseApp.configure()

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
