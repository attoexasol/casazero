# CasaZero — Flutter Push Notification Implementation Audit

**Date:** 30 Jul 2026  
**Type:** Audit only — no code was modified  
**Focus:** Full stack with emphasis on iOS parity vs working Android path  
**Constraint:** Preserve all existing behavior; recommendations only  

**Stack**

| Layer | Version / detail |
|-------|------------------|
| Flutter | GetX app |
| `firebase_messaging` | ^16.0.4 (iOS SDK FirebaseMessaging 12.4.0) |
| `flutter_local_notifications` | ^19.5.0 |
| Backend | Laravel (`backend.casazero.site`) |
| iOS bundle | `com.attoexa.casazero` |
| Android package | `com.example.casazero` (debug) |
| Firebase project | `casazero-a39ba` / sender `898881501223` |

---

## 1. Current Architecture

### 1.1 Layered design

```
┌─────────────────────────────────────────────────────────────────┐
│  Native                                                          │
│  iOS: AppDelegate (FirebaseApp.configure, APNs, Messaging)       │
│  Android: MainActivity (singleTop, onNewIntent) + Manifest       │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  Bootstrap (main.dart)                                           │
│  Firebase.initializeApp → onBackgroundMessage → PushLaunchHandler│
│  → LocalNotificationService.initialize                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  Services (GetX)                                                 │
│  FcmService          — permission, token cache, onMessage        │
│  NotificationManager — payload sync + deep-link navigation       │
│  PushLaunchHandler   — getInitialMessage / onMessageOpenedApp    │
│  LocalNotificationService — channel + heads-up banners           │
│  AppStatusService    — FG/BG report to Laravel                   │
│  PrivateChatNotificationService — chat payload refresh           │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  Backend contract                                                │
│  POST /user/login          { fcm_token }   ← ONLY token register │
│  POST /send-chat-notification                                    │
│  POST /update-app-status   (client calls; route may 404)         │
│  In-app feed APIs          (list / unread / mark read / delete)  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 File map

| Responsibility | File |
|----------------|------|
| App entry + background isolate | `lib/main.dart` |
| Service DI | `lib/app/bindings/initial_binding.dart` |
| FCM permissions / token / foreground | `lib/core/services/fcm_service.dart` |
| Cold / bg tap capture | `lib/core/services/push_launch_handler.dart` |
| Local banners + local tap | `lib/helpers/local_notification_service.dart` |
| Payload sync + deep links | `lib/core/services/notification_manager.dart` |
| Chat push side-effects | `lib/core/services/private_chat_notification_service.dart` |
| App FG/BG status | `lib/core/services/app_status_service.dart` |
| Chat push send + app status API | `lib/data/repositories/notification_repository.dart` |
| Login attaches `fcm_token` | `lib/data/repositories/auth_repository.dart` |
| Logout / session delete FCM | `auth_repository.dart`, `session_expiry_service.dart` |
| Type aliases | `lib/core/constants/push_types.dart` |
| Pending nav persistence | `lib/core/services/storage_service.dart` |
| HOME flush of pending nav | `lib/app/routes/app_routes.dart` |
| iOS native | `ios/Runner/AppDelegate.swift`, `Info.plist`, `GoogleService-Info.plist` |
| Android native | `android/.../AndroidManifest.xml`, `MainActivity.kt` |

### 1.3 Design strengths already in place

- Clear separation: FCM never touches GetX controllers; `NotificationManager` does.
- Background isolate is top-level with `@pragma('vm:entry-point')` and does not use GetX controllers.
- Cold-start order on purpose: `getInitialMessage` **before** local launch details (iOS requirement).
- Pending deep-link is persisted and survives logout (`StorageService.clearAll` preserves it).
- Dedup by FCM `messageId`; payload normalization + nested JSON `data` string support.
- Typed navigation for documents, private/group chat, tickets, maintenance.
- Android channel `casazero_alerts_v2` (max importance) aligned with manifest default channel id.

---

## 2. Initialization Order

### 2.1 Actual startup sequence

```
1. WidgetsFlutterBinding.ensureInitialized()
2. SystemChrome status-bar style
3. _initializeCriticalServices()                         ← awaited before runApp
   3a. GetStorage.init()
   3b. StorageService.init()
   3c. LocaleController
   3d. _initializeFirebase()
       - Firebase.initializeApp (or skip if AppDelegate already configured)
       - FirebaseMessaging.onBackgroundMessage(...)
       - PushLaunchHandler.install()
           → getInitialMessage()
           → onMessageOpenedApp.listen
   3e. LocalNotificationService.initialize()
       → plugin init + Android channel + getNotificationAppLaunchDetails
4. runApp(CasaZeroApp)
   4a. GetMaterialApp(initialBinding: InitialBinding)
       → registers ApiService, NotificationManager, FcmService (NOT init),
         AppStatusService, PrivateChatNotificationService, etc.
   4b. initialRoute = SPLASH
5. unawaited(_initializeDeferredServices())              ← AFTER first frame
   5a. InitialBinding.registerFirebaseDependentServices()
       → PrivateChat / Presence / FirebaseAuth / providers
       → FcmService.init()  **fire-and-forget (not awaited)**
           → requestPermission
           → getToken
           → onTokenRefresh listener
           → onMessage listener
           → setForegroundNotificationPresentationOptions (iOS)
```

### 2.2 iOS native order (before Dart)

```
AppDelegate.didFinishLaunching
  → FirebaseApp.configure()
  → GeneratedPluginRegistrant.register
  → UNUserNotificationCenter.current().delegate = self
  → registerForRemoteNotifications()
  → Messaging.messaging().delegate = self
  → super.application(...)
```

Then Dart `Firebase.apps.isNotEmpty` → skip second configure, log “already initialized by AppDelegate”.

### 2.3 What is early vs late

| Step | Timing | Impact |
|------|--------|--------|
| Background handler registration | Critical (pre-runApp) | Correct |
| `getInitialMessage` | Critical (pre-runApp) | Correct for cold start |
| Local channel / launch details | Critical (pre-runApp) | Correct |
| `FcmService.init` (permission, onMessage, iOS presentation) | **Deferred, not awaited** | Foreground display / first-token race |
| Token → Laravel | Only at login body | No mid-session update |

---

## 3. Current Token Flow

### 3.1 Generation path

```
iOS:  registerForRemoteNotifications
        → didRegisterForRemoteNotifications (APNs Data)
        → Messaging.messaging().apnsToken = deviceToken
        → FirebaseMessaging.getToken()  → FCM registration token

Android: Google Play Services / FCM
        → FirebaseMessaging.getToken()  → FCM registration token
```

Cached only in `FcmService._currentToken` (memory). Not written to GetStorage as FCM token (device “token” in storage is the **trusted-device** token, not FCM).

### 3.2 Backend registration (single path)

```
AuthRepository.login()
  → fcmToken = FcmService.getDeviceToken() ?? ''
      (1 retry after 1500 ms if empty)
  → POST /user/login { ..., fcm_token: fcmToken, ... }
```

`registerAfterAuth()` (splash restore, post-login, post-OTP) only:

```
requestPermission + _refreshToken()
```

It does **not** call any Laravel update endpoint. Comment in code is explicit: *“Backend token registration uses fcm_token on POST /user/login only.”*

### 3.3 Token refresh

```
messaging.onTokenRefresh → _currentToken = newToken
```

Local cache only. Backend is never notified until the next login.

### 3.4 Logout / session expiry

| Event | FCM action |
|-------|------------|
| Successful logout API | `FcmService.deleteToken()` |
| Session expiry (401 path) | `FcmService.deleteToken()` then `storage.clearAll()` |
| Logout API failure | Local FCM delete may be skipped (error path returns without delete in some branches) |

Backend is not explicitly told “clear this FCM token” beyond logout semantics on the server; client deletes the Firebase token locally so that device stops matching until next login.

### 3.5 Token flow diagram

```
App Start
  → (iOS) APNs register (native)
  → Deferred FcmService.init → getToken → cache

User Login
  → getDeviceToken (retry ×1 / 1.5s)
  → POST /user/login { fcm_token }
  → registerAfterAuth → refresh local cache only

OTP / Splash session restore
  → registerAfterAuth → local cache only

Token rotation (OS / Firebase)
  → onTokenRefresh → local cache only
  → Laravel still has old token  ❌

Logout / Session expiry
  → deleteToken() → cache null
```

---

## 4. Current iOS Flow

### 4.1 Capabilities present in repo

| Item | Status |
|------|--------|
| `UIBackgroundModes` → `remote-notification` | Present (`Info.plist`) |
| `GoogleService-Info.plist` (`com.attoexa.casazero`, GCM enabled) | Present + in Resources |
| `DEVELOPMENT_TEAM = 2CKF37TSD9` | Present |
| Bundle ID match Xcode ↔ plist ↔ `firebase_options.ios` | Match (`com.attoexa.casazero`) |
| `Runner.entitlements` / `aps-environment` | **Missing** |
| `CODE_SIGN_ENTITLEMENTS` in pbxproj | **Missing (Debug/Release/Profile)** |
| APNs Auth Key in Firebase Console | Not verifiable from repo — must confirm |

`ios_backup/` still has entitlements; active `ios/` project does not. This is the primary iOS delivery blocker.

### 4.2 Permission

- Prompt owned by `FirebaseMessaging.requestPermission` inside deferred `FcmService.init`.
- `LocalNotificationService` sets `requestAlertPermission/Badge/Sound: false` on iOS (avoids double prompt).
- Resume path refreshes token if permission flipped deny → grant (local only).

### 4.3 Receive by state

| State | Mechanism |
|-------|-----------|
| **Foreground** | `onMessage` → if `notification != null`, **skip local**, rely on `setForegroundNotificationPresentationOptions`; else local show. Always dispatch to `NotificationManager`. |
| **Background** | OS shows `notification`/`aps.alert`. Data-only → Dart background handler may show local (unreliable on iOS). |
| **Terminated** | OS must show `notification` + APNs alert. Data-only generally **cannot** surface a banner. Tap → `getInitialMessage` via `PushLaunchHandler`. |

### 4.4 Tap / deep link

| Source | Handler |
|--------|---------|
| APNs / FCM system banner | `getInitialMessage` / `onMessageOpenedApp` → `PushLaunchHandler` → persist + queue retries → `NotificationManager` |
| Local banner (data-only / some FG) | `onDidReceiveNotificationResponse` / launch details → same manager |
| In-app notification center | Shared `handleNotificationNavigation` |

Flush gates on `HomeController` registered + route `HOME` + non-empty access token.

### 4.5 Fragile native details

1. Manual `UNUserNotificationCenter.delegate = self` and `Messaging.delegate = self` before plugin observers run — works today via `FlutterAppDelegate` forwarding, but is load-bearing coincidence.
2. Manual `Messaging.messaging().apnsToken = deviceToken` bypasses plugin’s DEBUG sandbox / RELEASE prod typing.
3. `InterruptionLevel.timeSensitive` used without time-sensitive entitlement → silently downgrades.
4. No app badge management (`aps.badge` / clear on read).
5. No Notification Service Extension (long text / images truncated vs Android BigText).

---

## 5. Current Android Flow

### 5.1 Native plumbing

| Item | Status |
|------|--------|
| `POST_NOTIFICATIONS`, `VIBRATE`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` | Present |
| Default channel meta-data `casazero_alerts_v2` | Present |
| `MainActivity` `singleTop` + `onNewIntent` | Present |
| `FLUTTER_NOTIFICATION_CLICK` intent-filter | Present |
| Dedicated white `ic_stat_*` notification icon | Missing (uses `@mipmap/ic_launcher`) |

### 5.2 Permission

- FCM `requestPermission` + `permission_handler` notification + plugin `requestNotificationsPermission` (Android 13+).
- Channel created at max importance on local init (critical path).

### 5.3 Receive by state

| State | Mechanism |
|-------|-----------|
| **Foreground** | OS does **not** show FCM tray → always `LocalNotificationService.showNotification` via `onMessage`. |
| **Background** | `notification` block → OS tray; data-only → background handler local show. |
| **Terminated** | `notification` block → OS tray; data-only OEM-dependent (often fails on aggressive OEMs / force-stop). |

### 5.4 Why Android “works” vs iOS

- No APNs entitlement required.
- FCM token typically available before/during login without APNs handshake.
- Foreground path always draws a local banner (does not depend on deferred iOS presentation options).
- Background Dart isolate for data-only is more reliable than iOS content-available throttling.

---

## 6. Weaknesses

### 6.1 Architecture / product

1. **Single Laravel registration point (`fcm_token` on login only)** — rotations and late iOS tokens never reach the server.
2. **`registerAfterAuth` is misnamed for backend** — refreshes local cache only.
3. **Empty `fcm_token` accepted** — login proceeds with `''` when `getToken` fails.
4. **No dedicated `POST /update-fcm-token` (or equivalent)** in client constants.
5. **`/update-app-status` called but previously observed 404** — gating contract broken; when fixed, lifecycle gap becomes dangerous.
6. **AppStatusService ignores `detached` / `hidden`** — kill may leave status as `foreground`.
7. **Chat type aliases** — outgoing often `private_chat`; canonical `private_chat_message` — mitigated by `PushTypes` aliases but easy to regress.
8. **NotificationRepository** has no FCM register/update/delete methods — only chat send + app status.

### 6.2 Client reliability

9. **`FcmService.init()` deferred and not awaited** — `onMessage` and iOS presentation options late.
10. **`getDeviceToken` single 1.5s retry** — insufficient for cold iOS APNs.
11. **No `getAPNSToken()` gate before `getToken()` on iOS**.
12. **iOS foreground skip-local + late presentation options** → first-launch silent banners.
13. **Data-only reliance for banners** works on Android BG; fails on iOS BG/terminated.
14. **Android notification small icon** uses launcher mipmap (OEM may blank / demote).

### 6.3 iOS configuration

15. **Missing Push Notifications capability / `aps-environment`** — blocks APNs → blocks FCM token → blocks all delivery.
16. **APNs Auth Key presence not enforced/documented in repo**.
17. **Manual AppDelegate delegate / apnsToken assignments** fragile vs plugin ownership.
18. **`ios_backup/` stale trap** with different AppDelegate + entitlements.

---

## 7. Race Conditions

| # | Race | What happens | Who loses |
|---|------|--------------|-----------|
| R1 | Login before APNs/FCM token ready | `fcm_token: ''` sent; session never gets a token | iOS especially |
| R2 | `FcmService.init` after splash/login path starts | Permission / presentation / onMessage not ready for early pushes | Both; FG iOS worse |
| R3 | `onTokenRefresh` after login | Backend keeps stale token | Both; long sessions |
| R4 | `getInitialMessage` before `NotificationManager` / HOME | Mitigated by persist + delayed retries (0.8–7s) + HOME flush | Mostly OK |
| R5 | Splash → OTP pending skips `registerAfterAuth` until OTP success | Correct for auth policy; token still only from original login body | If login had empty token, OTP never re-sends it |
| R6 | AuthController `registerAfterAuth` **after** login HTTP already sent token | Second refresh is local-only; cannot fix empty login token | iOS |
| R7 | Local launch details vs FCM initial message | Order correct (FCM first); reverse would drop iOS opens | Guarded |
| R8 | App kill without `paused` | Status stuck `foreground` when API exists | Push suppression risk |
| R9 | Dual Firebase init (native + Dart) | Dart skips if apps non-empty — OK | Low |
| R10 | Plugin vs AppDelegate competing for `UNUserNotificationCenter.delegate` | Currently forwards; upgrade can break taps | iOS taps |

### Lifecycle the audit traced

```
App Start
  ↓
Firebase Initialization (native iOS + Dart critical path)
  ↓
Permission Request (deferred FcmService.init)          ← R2
  ↓
APNs Registration (native; fails without entitlement)  ← blocker
  ↓
FCM Token Generation (deferred; may fail without APNs) ← R1
  ↓
Laravel Token Registration (login body only)           ← R1, R3, R6
  ↓
Notification Receive (FG local/system; BG OS/handler; killed OS-only)
  ↓
Notification Tap (PushLaunchHandler / local → NotificationManager queue)
```

---

## 8. Missing iOS Features

| Feature | Status | Notes |
|---------|--------|-------|
| Push Notifications entitlement (`aps-environment`) | **Missing** | Blocker |
| APNs Auth Key documented / verified | Unknown | Must confirm in Firebase Console |
| Await APNs before FCM `getToken` | Missing | Causes empty login token |
| Backend token update after late/rotated token | Missing | Login-only |
| Critical-path `FcmService.init` | Missing | Presentation options race |
| Provisional authorization option | Not used | `provisional: false` |
| Explicit sandbox/prod APNs token typing via plugin | Bypassed | Manual `apnsToken =` |
| Time Sensitive entitlement | Missing | Level set in local details anyway |
| App icon badge sync | Missing | `presentBadge` / options on, no set/clear |
| Notification Service Extension | Missing | No rich media / long body expansion |
| `content-available` silent strategy documented | Missing | Data-only not reliable for UI |
| Commit of entitlements for CI / new machines | Missing | Capability only in backup historically |

---

## 9. Production Risks

| Risk | Severity | Platform | Effect |
|------|----------|----------|--------|
| No `aps-environment` in signed binary | **Critical** | iOS | Zero push delivery |
| Missing / wrong APNs key in Firebase | **Critical** | iOS | Send “succeeds”, device never receives |
| Empty `fcm_token` at login | **High** | iOS ≫ Android | Device never registered for session |
| Token rotation not synced | **High** | Both | Silent loss after weeks/reinstall |
| Deferred FG presentation options | **High** | iOS | No banner on first open after install |
| Data-only user alerts | **High** | iOS (and OEM Android killed) | No tray when closed |
| App status API 404 + future gating with stale FG | **Medium–High** | Both | Suppress pushes when user needs them |
| Force-stop / MIUI-style kill | **Medium** | Android | Expected OS limitation |
| AppDelegate / plugin delegate conflict after upgrade | **Medium** | iOS | Taps / `onMessageOpenedApp` break |
| TestFlight `aps-environment` stuck on `development` if hand-authored wrong | **Medium** | iOS | Debug OK, release dead |
| Simulator testing | **Low** | iOS | Cannot validate APNs/FCM |
| Launcher icon as Android status icon | **Low** | Android | Blank / ugly shade icons |
| Logout path that skips `deleteToken` on API failure | **Low** | Both | Stale server targeting until overwrite |

---

## 10. Recommended Implementation Plan

**Preserve existing behavior:** keep current layering (`FcmService` → `NotificationManager` → controllers), local channel id `casazero_alerts_v2`, `PushLaunchHandler` before local launch details, pending-nav persistence across logout, and deep-link type map. Changes should be additive or ordering/hardening only.

### Phase 0 — Unblock iOS delivery (must do first)

1. Enable **Push Notifications** capability in Xcode for Runner.
2. Commit `ios/Runner/Runner.entitlements` with `aps-environment` and set `CODE_SIGN_ENTITLEMENTS` for Debug, Release, Profile (do **not** add entitlements to Resources).
3. Confirm APNs **Auth Key (.p8)** + Key ID + Team `2CKF37TSD9` in Firebase Console for the iOS app.
4. Physical device smoke test: APNs register log → non-empty FCM token → Firebase console test message.

### Phase 1 — Token lifecycle (preserve login field; extend)

1. Keep `fcm_token` on `POST /user/login`.
2. Add backend endpoint (e.g. `POST /update-fcm-token`) **or** reuse an existing profile endpoint if one exists.
3. Call it from:
   - `onTokenRefresh`
   - `registerAfterAuth` when token non-empty and user has `api_token`
   - permission grant-after-deny resume path
4. On iOS: wait for `getAPNSToken()` with backoff before `getToken()`; do not send empty `fcm_token` (omit field or retry until timeout with telemetry).
5. After OTP success, if login had empty token, **register now** via new endpoint (fixes R5/R6).

### Phase 2 — Init ordering (behavior-preserving)

1. Await `FcmService.init()` on critical path after Firebase + before or immediately after local notifications init (still after `PushLaunchHandler.install`).
2. Keep iOS skip-local-when-notification-block to avoid double banners once presentation options are set early.
3. Keep Android always-local in foreground.

### Phase 3 — Payload contract (backend + docs)

1. User-visible pushes: always `notification` + `data` + `apns.payload.aps.alert` + `apns-priority: 10`.
2. Android: `channel_id: casazero_alerts_v2`, high priority.
3. Silent sync only: data-only / `content-available` with explicit non-UI type (`sync_notifications`).
4. Document required `data` keys: `type` / `notification_type`, `reference_id`, optional feed `id`.

### Phase 4 — iOS native hygiene

1. Remove manual `UNUserNotificationCenter.delegate`, `Messaging.delegate`, and raw `apnsToken =` assignments; let `firebase_messaging` own them (or document and regression-test if kept).
2. Add time-sensitive entitlement **or** lower `InterruptionLevel` to `.active`.
3. Wire badge from unread count; clear on read / open.
4. Delete or README-guard `ios_backup/`.

### Phase 5 — App status + polish

1. Align `/update-app-status` with backend (fix 404 or remove client call).
2. Report `background` on `paused`, `hidden`, and `detached`.
3. Android: white silhouette `ic_stat` + `default_notification_icon`.
4. Optional: Notification Service Extension for parity with BigText.

### Phase 6 — Verification matrix

| # | Scenario | Android | iOS |
|---|----------|---------|-----|
| 1 | Fresh install → login → token in login body non-empty | ✓ | ✓ |
| 2 | Token refresh mid-session → backend updated | ✓ | ✓ |
| 3 | Foreground push → one banner | ✓ | ✓ |
| 4 | Background tray → tap → correct screen | ✓ | ✓ |
| 5 | Terminated + `notification` payload → tray + cold tap deep link | ✓ | ✓ |
| 6 | Data-only terminated | May fail (document) | Expect no banner |
| 7 | Deny then grant permission → token re-registered | ✓ | ✓ |
| 8 | Logout → no further pushes to that token | ✓ | ✓ |
| 9 | TestFlight / Release | — | ✓ |
| 10 | 2FA OTP path after empty-token login → token registered post-OTP | ✓ | ✓ |

### Suggested priority order

1. Phase 0 (entitlement + APNs key) — without this, iOS work is wasted.  
2. Phase 1 (token sync + APNs wait) — fixes “login with empty token”.  
3. Phase 2 (init await) — fixes first-launch foreground.  
4. Phase 3 (payload) — fixes terminated iOS display.  
5. Phases 4–5 — hardening and polish.  
6. Phase 6 — gate release.

---

## Appendix A — Endpoint inventory (client)

| Constant | Path | Role in push |
|----------|------|--------------|
| `LOGIN` | `/user/login` | **Only** FCM token upload today (`fcm_token`) |
| `LOGOUT` | `/user/logout` | Session end; client also `deleteToken()` |
| `SEND_CHAT_NOTIFICATION` | `/send-chat-notification` | Outbound chat push trigger |
| `UPDATE_APP_STATUS` | `/update-app-status` | FG/BG gating (availability uncertain) |
| In-app feed | `/get_user/notifications`, unread, mark read, delete | Not FCM display |

## Appendix B — State × display cheat sheet

| | Android FG | Android BG | Android killed | iOS FG | iOS BG | iOS killed |
|--|------------|------------|----------------|--------|--------|------------|
| Who shows | Local plugin | OS or local | OS (`notification`) | System options or local | OS (`aps.alert`) | OS only |
| Needs Dart alive | Yes | For data-only | No (if notif block) | For local / options set | For data-only | No |
| Needs APNs entitlement | N/A | N/A | N/A | Yes | Yes | Yes |
| Needs FCM token on Laravel | Yes | Yes | Yes | Yes | Yes | Yes |

## Appendix C — Explicit non-goals of this audit

- No source files were modified.
- No entitlement files were added.
- Recommendations are ordered so existing Android behavior and current navigation/queue design remain intact while iOS is brought to parity.

---

*End of audit.*
