# CasaZero — iOS Push Notification Issues Feedback

**Date:** 30 Jul 2026
**Reported symptom:** Push notifications work correctly on **Android**, but do **not** work properly on **iOS**.
**Stack:** `firebase_messaging` 16.0.4 (FirebaseMessaging iOS SDK 12.4.0) + `flutter_local_notifications` 19.5.0, iOS deployment target 15.0.
**Scope:** iOS-specific delivery, token, and display path. Cross-platform display logic is covered in `push_notification_display_issues_feedback.md`.

---

## 1. Headline finding

**The iOS project has no Push Notifications capability.** There is no `Runner.entitlements` file and no `CODE_SIGN_ENTITLEMENTS` build setting in any Runner build configuration. Without the `aps-environment` entitlement, iOS refuses APNs registration, so the app never receives an APNs token, `FirebaseMessaging.getToken()` cannot produce an FCM token, and **no push can be delivered in any app state**.

This is a **regression**: the previous project under `ios_backup/` had both the entitlements file and the build setting wired up. When the current `ios/` project was recreated, the capability was lost.

Android is unaffected because Android has no equivalent entitlement — FCM works off `google-services.json` and the manifest alone. That asymmetry fully explains "works on Android, not on iOS".

---

## 2. Evidence

### 2.1 Entitlements missing in the active project

`ios/Runner/` contains 30 files — `AppDelegate.swift`, `Info.plist`, `GoogleService-Info.plist`, `Runner-Bridging-Header.h`, storyboards, and the asset catalog. There is **no** `Runner.entitlements`.

Searching the whole repo for the signing setting returns matches only in `macos/` and `ios_backup/` — never in `ios/`:

| Location | `CODE_SIGN_ENTITLEMENTS` | `aps-environment` |
|----------|--------------------------|-------------------|
| `ios/Runner.xcodeproj/project.pbxproj` | **absent (all 3 configs)** | **absent** |
| `ios_backup/Runner.xcodeproj/project.pbxproj` | present (Debug / Release / Profile) | via `Runner.entitlements` |
| `macos/Runner.xcodeproj/project.pbxproj` | present | N/A |

The three Runner configurations in the active project (`Debug` at ~671, `Release` at ~694, `Profile` at ~488) each define `DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER`, and `INFOPLIST_FILE`, but no entitlements:

```674:691:ios/Runner.xcodeproj/project.pbxproj
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CLANG_ENABLE_MODULES = YES;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				DEVELOPMENT_TEAM = 2CKF37TSD9;
				ENABLE_BITCODE = NO;
				INFOPLIST_FILE = Runner/Info.plist;
				PRODUCT_BUNDLE_IDENTIFIER = com.attoexa.casazero;
				SWIFT_OBJC_BRIDGING_HEADER = "Runner/Runner-Bridging-Header.h";
			};
			name = Debug;
```

The backup shows what used to exist:

```1:8:ios_backup/Runner/Runner.entitlements.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
</dict>
</plist>
```

### 2.2 What is correctly configured (so these are *not* the cause)

| Item | Status |
|------|--------|
| `UIBackgroundModes` → `remote-notification` in `ios/Runner/Info.plist` (lines 65–68) | Present |
| Bundle ID match: pbxproj `com.attoexa.casazero` vs `GoogleService-Info.plist` `BUNDLE_ID` | Match |
| Firebase iOS app registered: `GOOGLE_APP_ID = 1:898881501223:ios:3fcb667f185eedc09fb602`, `IS_GCM_ENABLED = true` | Correct |
| `GCM_SENDER_ID` / `PROJECT_ID` consistent with Android (`898881501223` / `casazero-a39ba`) | Match |
| `GoogleService-Info.plist` added to the Runner "Resources" build phase | Correct |
| `DEVELOPMENT_TEAM = 2CKF37TSD9` set on all Runner configs | Present |
| Podfile platform 15.0, `use_frameworks!`, FirebaseMessaging 12.4.0 resolved in `Podfile.lock` | Correct |

So the Firebase side of the wiring is fine. The failure is in the **Apple** side: capability, entitlement, and APNs key.

---

## 3. Issue list

### P0-1 — Missing Push Notifications capability / `aps-environment` (blocker)

**Failure chain**

1. `application.registerForRemoteNotifications()` is called in `AppDelegate`.
2. iOS rejects it because the binary carries no `aps-environment` entitlement.
3. `didFailToRegisterForRemoteNotificationsWithError` fires — the existing handler logs it:

```84:91:ios/Runner/AppDelegate.swift
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    print("❌ APNs token unavailable — FCM token may not be generated on this device")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
```

4. `Messaging.messaging().apnsToken` is never set.
5. `FirebaseMessaging.getToken()` fails (typically `apns-token-not-set`) or returns nil.
6. No FCM token reaches the backend → **no push in foreground, background, or terminated**.

**Expected device log signature:** `no valid "aps-environment" entitlement string found for application`.

**Fix**

Enable the capability in Xcode (Runner target → Signing & Capabilities → **+ Capability** → **Push Notifications**). Xcode creates `ios/Runner/Runner.entitlements` and adds `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` to all three configurations. Commit both.

Two mistakes in the backup that should **not** be repeated:

- The entitlements file was named `Runner.entitlements.xml` and also added to the **Resources** build phase (`Runner.entitlements.xml in Resources`). Entitlements are a **code-signing input**, not a bundled resource — shipping it as a resource does nothing for APNs and leaks the file into the app bundle.
- Only `development` was declared. Xcode normally rewrites `aps-environment` to `production` for release/archive builds; if the value is pinned to `development`, TestFlight and App Store builds will fail to receive pushes even though debug builds work.

### P0-2 — Missing APNs Auth Key in Firebase Console (verify)

Not verifiable from the repo, but mandatory. Firebase Console → Project Settings → Cloud Messaging → iOS app → upload the **APNs Auth Key (.p8)** with its Key ID and your Team ID (`2CKF37TSD9`). Without it, Firebase accepts the send request and silently fails to relay to APNs — the send API returns success, which makes this easy to misdiagnose as a client bug.

An APNs Auth Key covers both sandbox and production; legacy certificates do not, and are a common cause of "debug works, TestFlight doesn't".

### P0-3 — Empty `fcm_token` is silently sent to the backend

On iOS, `getToken()` throws until the APNs token is available. `FcmService` swallows that error and returns null:

```187:203:lib/core/services/fcm_service.dart
  Future<String?> _refreshToken() async {
    try {
      if (kIsWeb || Firebase.apps.isEmpty || messaging == null) return null;
      _currentToken = await messaging!.getToken();
      ...
      return _currentToken;
    } catch (e) {
      print('❌ [FcmService] Error getting token: $e');
      return null;
    }
  }
```

`AuthRepository` then posts an empty string:

```38:46:lib/data/repositories/auth_repository.dart
      // Get FCM token (will be empty string if not available; getDeviceToken retries once)
      String fcmToken = '';
      try {
        if (Get.isRegistered<FcmService>()) {
          fcmToken = await Get.find<FcmService>().getDeviceToken() ?? '';
        }
      } catch (e) {
        print('⚠️ FCM Service not available: $e');
      }
```

Because the token is only registered with the backend via `fcm_token` on `POST /user/login`, an empty value at login time means **that device never receives a push again for the whole session**, even if the APNs token arrives seconds later. `getDeviceToken()` retries only once after 1500 ms, which is frequently not enough on a cold first launch.

**Fix**

- On iOS, gate on `FirebaseMessaging.instance.getAPNSToken()` before calling `getToken()`, retrying with backoff until non-null.
- Do not send an empty `fcm_token`; if it is empty, register it with the backend as soon as it resolves.
- Add a real token-update endpoint (see §4) so `onTokenRefresh` is not a dead end.

### P0-4 — iOS foreground banner depends on options set too late

For iOS, `FcmService` deliberately skips the local banner when the message has a `notification` block and relies on system presentation:

```229:240:lib/core/services/fcm_service.dart
  Future<void> handlePushMessage(RemoteMessage message) async {
    try {
      final skipLocalOnIos =
          !kIsWeb && Platform.isIOS && message.notification != null;
      if (skipLocalOnIos) {
        print(
          '📨 [FcmService] iOS foreground — using system presentation '
          '(skipping local duplicate)',
        );
      } else {
        await LocalNotificationService.showNotification(message);
      }
```

System presentation is enabled by `setForegroundNotificationPresentationOptions`, called at the very end of `FcmService.init()`:

```83:84:lib/core/services/fcm_service.dart
      _setupForegroundAndBackgroundHandlers();
      await _setIOSForegroundPresentationOptions();
```

`FcmService.init()` runs from `InitialBinding.registerFirebaseDependentServices()` inside `_initializeDeferredServices()` — after `runApp`, and it is **not awaited**:

```127:129:lib/app/bindings/initial_binding.dart
    if (Get.isRegistered<FcmService>()) {
      Get.find<FcmService>().init();
    }
```

The plugin persists these options into `NSUserDefaults`, so the setting survives across launches. That means the bug is **first-launch only but permanent-looking**: on a fresh install, a push arriving before init completes hits the iOS branch that skips the local banner *and* finds no persisted presentation options, so `willPresentNotification` resolves to `UNNotificationPresentationOptionNone` and **nothing is displayed**. Testers who install and immediately send a test push see "iOS shows nothing".

**Fix:** move `FcmService.init()` onto the critical startup path and `await` it, alongside `LocalNotificationService.initialize()` in `main.dart`.

### P1-5 — AppDelegate reassigns delegates the plugin manages

```26:32:ios/Runner/AppDelegate.swift
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self

    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
```

`FLTFirebaseMessagingPlugin` claims both delegates itself, from an observer on `UIApplicationDidFinishLaunchingNotification` — which UIKit posts *after* `didFinishLaunchingWithOptions` returns. It explicitly declines to take over the notification-center delegate when the incumbent conforms to `FlutterAppLifeCycleProvider`:

`FLTFirebaseMessagingPlugin.m` (firebase_messaging 16.0.4, lines 263–296):

```objc
    if (notificationCenter.delegate != nil) {
      // If a UNUserNotificationCenterDelegate is set and it conforms to
      // FlutterAppLifeCycleProvider then we don't want to replace it on iOS as the earlier
      // call to `[_registrar addApplicationDelegate:self];` will automatically delegate calls
      // to this plugin.
      if ([notificationCenter.delegate conformsToProtocol:@protocol(FlutterAppLifeCycleProvider)]) {
        shouldReplaceDelegate = NO;
      }
      ...
    }
    if (shouldReplaceDelegate) {
      notificationCenter.delegate = strongSelf;
    }
```

Because `AppDelegate` extends `FlutterAppDelegate` (which conforms to `FlutterAppLifeCycleProvider`) and assigns itself *before* the plugin's observer fires, the app currently lands on the supported forwarding path. Likewise `Messaging.messaging().delegate` is re-claimed by the plugin afterwards, and the plugin forwards `messaging:didReceiveRegistrationToken:` back to the app delegate.

So this is **not broken today — but it is load-bearing coincidence.** It depends on plugin-internal timing and on `FlutterAppDelegate` forwarding `UNUserNotificationCenterDelegate` callbacks. A plugin upgrade, a Flutter embedder change, or moving `GeneratedPluginRegistrant.register` could silently kill `onMessageOpenedApp` and local-notification taps on iOS only — with no compile error.

**Recommendation:** delete both manual delegate assignments and let the plugin own them. If they are kept, add a comment recording the ordering requirement, and cover taps with a regression test on every dependency bump.

### P1-6 — Manual `apnsToken` assignment bypasses explicit sandbox/prod typing

```73:82:ios/Runner/AppDelegate.swift
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
```

Assigning the `apnsToken` property leaves the environment (sandbox vs production) to Firebase auto-detection, which reads the provisioning profile and the `aps-environment` entitlement — the very thing that is missing. The plugin instead sets the type explicitly by build configuration:

`FLTFirebaseMessagingPlugin.m` (firebase_messaging 16.0.4, lines 1031–1042):

```objc
- (void)ensureAPNSTokenSetting {
  FIRMessaging *messaging = [FIRMessaging messaging];

  if (messaging.APNSToken == nil && _apnsToken != nil) {
#ifdef DEBUG
    [[FIRMessaging messaging] setAPNSToken:_apnsToken type:FIRMessagingAPNSTokenTypeSandbox];
#else
    [[FIRMessaging messaging] setAPNSToken:_apnsToken type:FIRMessagingAPNSTokenTypeProd];
#endif
    _apnsToken = nil;
  }
}
```

Because the app sets `apnsToken` first, `messaging.APNSToken` is already non-nil and this safeguard becomes a no-op. If the environment is inferred wrongly, APNs accepts the token and silently discards every push — the classic "no error anywhere, still no notifications". Removing the manual assignment restores the plugin's explicit typing.

### P1-7 — Data-only pushes cannot display on iOS

The background handler only synthesizes a banner for data-only messages:

```48:54:lib/main.dart
  if (message.notification == null) {
    try {
      await LocalNotificationService.showNotification(message);
    } catch (e) {
      print('❌ [FCM Background] Local notification error: $e');
    }
  }
```

On Android this path is reliable. On iOS it is effectively dead code for user-visible alerts:

| | Android | iOS |
|---|---------|-----|
| Data-only wakes app code | Yes, reliably | Only with `aps.content-available = 1`, low priority, and **throttled at Apple's discretion** |
| Data-only can show a banner | Yes (app constructs a local one) | No guarantee — often never runs; cannot display when terminated |
| Requires `notification` block for tray display | No | **Yes** |

So if the backend sends data-only payloads, iOS shows nothing in background or terminated even after the entitlement is fixed. iOS requires an `apns` alert payload. Recommended shape (extends the Android payload already documented in `push_notification_display_issues_feedback.md`):

```json
{
  "notification": { "title": "...", "body": "..." },
  "data": { "type": "document_uploaded", "reference_id": "123" },
  "android": {
    "priority": "high",
    "notification": { "channel_id": "casazero_alerts_v2", "priority": "max" }
  },
  "apns": {
    "headers": { "apns-priority": "10", "apns-push-type": "alert" },
    "payload": {
      "aps": {
        "alert": { "title": "...", "body": "..." },
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

Reserve data-only (`sync_notifications`) for silent refresh, and send it with `apns-push-type: background`, `apns-priority: 5`, and `content-available: 1`.

### P2-8 — `InterruptionLevel.timeSensitive` requires an entitlement

```342:349:lib/helpers/local_notification_service.dart
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
```

Time Sensitive notifications need `com.apple.developer.usernotifications.time-sensitive` in the entitlements file (and the matching capability on the App ID). With no entitlements file at all, iOS downgrades this to `.active`, so it will not break through Focus modes as intended. Add the key when creating `Runner.entitlements`, or drop back to `.active` to keep intent and behavior aligned.

### P2-9 — No Notification Service Extension

The Android banner uses `BigTextStyleInformation` for expandable long text. iOS has no equivalent without a Notification Service Extension, and rich media (images) additionally requires `mutable-content: 1` plus an extension target. Long bodies will be truncated on iOS. Cosmetic, but it is a visible parity gap worth noting before QA files it as a bug.

### P2-10 — iOS badge count is never managed

`presentBadge: true` is set on both the FCM and local paths, but nothing sets or clears the app icon badge. On iOS the badge is driven by `aps.badge` from the server (or `setBadgeCount` locally). The unread count already exists in `HomeController.fetchUnreadCount()`, so the backend should include it as `aps.badge` and the app should clear it on read.

### P2-11 — `ios_backup/` is a stale trap

`ios_backup/` contains a different `AppDelegate.swift` (native permission request, verbose token logging) plus the entitlements that the live project is missing. Anyone debugging this issue may "fix" the backup folder and see no change. Delete it or add a README stating it is dead code.

### P2-12 — Simulator cannot be used to validate this

iOS Simulator does not register with APNs and cannot obtain an FCM token. All verification must happen on a physical device with a provisioning profile that includes the Push Notifications capability. Note that `FirebaseAppDelegateProxyEnabled` is deliberately **not** set in `Info.plist` (default `YES`); the current AppDelegate depends on that swizzling, so it must not be disabled.

---

## 4. Cross-platform context

The token-lifecycle gap flagged in earlier reviews hits iOS harder. `onTokenRefresh` only updates the in-memory cache:

```205:213:lib/core/services/fcm_service.dart
  void _setupTokenRefreshListener() {
    if (Firebase.apps.isEmpty || messaging == null) return;
    messaging!.onTokenRefresh.listen((newToken) {
      print('🔄 [FcmService] Token refresh — new local token cached');
      _currentToken = newToken;
    }).onError((e) {
      print('❌ [FcmService] Token refresh error: $e');
    });
  }
```

Because the backend only learns the token at login, and because iOS is the platform where the token frequently arrives *after* login (APNs handshake latency) or rotates, iOS devices go dark far more often than Android ones. A `POST` token-update endpoint called from `onTokenRefresh` and `registerAfterAuth` is required for iOS to be reliable, independent of the entitlement fix.

---

## 5. Priority order

| # | Issue | Severity | Owner | Effort |
|---|-------|----------|-------|--------|
| 1 | Add Push Notifications capability + `Runner.entitlements` (`aps-environment`) to all 3 configs | **Blocker** | iOS / Xcode | S |
| 2 | Upload APNs Auth Key (.p8) in Firebase Console; verify Team ID + Key ID | **Blocker** | DevOps | S |
| 3 | Never send empty `fcm_token`; await `getAPNSToken()` on iOS, retry with backoff | **P0** | Flutter | M |
| 4 | Await `FcmService.init()` on the critical path so foreground presentation options are set before the first push | **P0** | Flutter | S |
| 5 | Backend: always send `notification` + `apns.aps.alert` for user-visible pushes | **P0** | Backend | M |
| 6 | Remove manual `UNUserNotificationCenter` / `Messaging` / `apnsToken` assignments from `AppDelegate` | **P1** | iOS | S |
| 7 | Add token-update endpoint and call it from `onTokenRefresh` / `registerAfterAuth` | **P1** | Backend + Flutter | M |
| 8 | Add time-sensitive entitlement or downgrade `interruptionLevel` | **P2** | iOS | S |
| 9 | Badge via `aps.badge`; clear on read | **P2** | Backend + Flutter | S |
| 10 | Notification Service Extension for long text / images | **P2** | iOS | M |
| 11 | Delete or document `ios_backup/` | **P2** | Repo hygiene | S |

---

## 6. Verification checklist (physical iOS device)

Run in order — each step gates the next.

| # | Check | Pass criteria |
|---|-------|---------------|
| 1 | Build after enabling the capability | `ios/Runner/Runner.entitlements` exists and contains `aps-environment`; `CODE_SIGN_ENTITLEMENTS` present in Debug, Release, and Profile |
| 2 | Launch on device, read Xcode console | `📱 APNs token registered: …` appears; **no** `no valid "aps-environment" entitlement` error and no `didFailToRegisterForRemoteNotifications` |
| 3 | Console after permission grant | `🔑 [FcmService] Token generated: …` with a non-empty token |
| 4 | Login request body | `fcm_token` is non-empty in the `POST /user/login` payload |
| 5 | Firebase Console → send test to that token | Notification arrives |
| 6 | App in **foreground** | Banner appears once (no duplicate); `📨 [FcmService] Foreground push` logged |
| 7 | App in **background** | Tray notification appears; tap opens the correct screen |
| 8 | App **terminated** (swipe away) | Tray notification appears from the `notification` + `apns` payload; tap cold-starts to the correct screen |
| 9 | Data-only push while terminated | Expected to show nothing — confirms P1-7 and that alerts must carry a `notification` block |
| 10 | TestFlight / release build | Pushes still arrive, proving `aps-environment` resolved to `production` and the APNs key covers both environments |
| 11 | Reinstall app, send push immediately after first launch | Banner appears — confirms the P0-4 init-ordering fix |

---

## 7. Summary

iOS push is failing for a configuration reason, not a logic reason: the Dart layer is essentially platform-correct, but the iOS app is not entitled to receive remote notifications. `ios/Runner/` has no `Runner.entitlements` and no `CODE_SIGN_ENTITLEMENTS` in any build configuration, while `ios_backup/` still carries both — the capability was dropped when the iOS project was regenerated. That single gap blocks APNs registration, which blocks the FCM token, which blocks every push in every app state.

After restoring the capability and confirming the APNs Auth Key in Firebase, three client-side issues still need fixing before iOS matches Android: the empty `fcm_token` sent at login when APNs is still handshaking, the deferred `FcmService.init()` that leaves foreground presentation options unset on first launch, and the reliance on data-only payloads that iOS will not display. The manual delegate and `apnsToken` assignments in `AppDelegate` happen to work today only because of plugin-internal timing, and should be removed to keep taps from breaking silently on the next dependency bump.
