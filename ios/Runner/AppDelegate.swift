import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase with error handling
    // Check if GoogleService-Info.plist exists and is valid
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       FileManager.default.fileExists(atPath: path) {
      print("📄 GoogleService-Info.plist found at: \(path)")
      
      // Verify key fields exist
      if let plist = NSDictionary(contentsOfFile: path) {
        let requiredKeys = ["API_KEY", "GCM_SENDER_ID", "GOOGLE_APP_ID", "PROJECT_ID", "BUNDLE_ID"]
        var missingKeys: [String] = []
        for key in requiredKeys {
          if plist[key] == nil {
            missingKeys.append(key)
          }
        }
        if missingKeys.isEmpty {
          print("✅ All required FCM keys found in GoogleService-Info.plist")
        } else {
          print("⚠️  Missing keys in GoogleService-Info.plist: \(missingKeys.joined(separator: ", "))")
        }
      }
      
      do {
        FirebaseApp.configure()
        print("✅ Firebase configured successfully in AppDelegate")
        
        // Register for remote notifications only if Firebase is configured
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self
          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
              if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
              } else {
                print("📱 Notification permission granted: \(granted)")
              }
            }
          )
        } else {
          let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
      } catch {
        print("❌ Firebase configuration failed in AppDelegate: \(error.localizedDescription)")
        print("⚠️  App will continue without Firebase features")
        // Don't crash - let the app continue
      }
    } else {
      print("⚠️  GoogleService-Info.plist not found or incomplete - skipping Firebase configuration")
      print("⚠️  App will continue without Firebase features")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("📱 APNs token registered: \(tokenString)")
    print("📱 APNs token length: \(deviceToken.count) bytes")
    
    // Set APNs token for Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNs token set for Firebase Messaging")
    
    // Wait a moment then request FCM token
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      print("🔄 Requesting FCM token after APNs token registration...")
      Messaging.messaging().token { token, error in
        if let error = error {
          print("❌ Error fetching FCM token: \(error.localizedDescription)")
          print("❌ Error details: \(error)")
          if let nsError = error as NSError? {
            print("❌ Error domain: \(nsError.domain)")
            print("❌ Error code: \(nsError.code)")
            print("❌ Error userInfo: \(nsError.userInfo)")
          }
        } else if let token = token {
          print("🔥 FCM Token received in AppDelegate: \(token)")
          print("🔥 FCM Token length: \(token.count) characters")
        } else {
          print("⚠️  FCM token is nil")
        }
      }
    }
  }
  
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    print("❌ This means APNs token will not be available, and FCM token cannot be generated")
    print("💡 Common causes:")
    print("   - Testing on iOS Simulator (use physical device)")
    print("   - APNs not configured in Firebase Console")
    print("   - Push Notifications capability not enabled in Xcode")
    print("   - Invalid provisioning profile")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let token = fcmToken {
      print("🔥 FCM Registration Token received via delegate: \(token)")
      print("🔥 Token length: \(token.count) characters")
    } else {
      print("⚠️  FCM Registration Token is nil in delegate")
    }
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
