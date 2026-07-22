# CasaZero — Notification Implementation Feedback

**Date:** 22 Jul 2026  
**Scope:** Foreground, background, and terminated (app closed) push handling, plus in-app notification center  
**Stack:** Firebase Cloud Messaging (`firebase_messaging` ^16.0.4) + `flutter_local_notifications` (^19.5.0)

---

## 1. Architecture overview

```
App start (main.dart)
  ├─ Firebase.initializeApp
  ├─ FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)
  ├─ LocalNotificationService.initialize()
  └─ FcmService.init()
        ├─ requestPermission + getToken
        ├─ onMessage              → foreground
        ├─ onMessageOpenedApp     → background → tap
        └─ getInitialMessage()    → terminated → tap

Push arrives
  ├─ Foreground  → LocalNotificationService.show + NotificationManager.refresh
  ├─ Background  → OS displays (notification payload) OR local show (data-only)
  └─ Terminated  → OS displays; cold-start tap via getInitialMessage

In-app feed (separate from FCM display)
  Bell → NotificationsModal → HomeController → Laravel APIs
```

| Layer | File | Role |
|-------|------|------|
| FCM entry | `lib/core/services/fcm_service.dart` | Permissions, token, listeners, dispatch |
| Local banners | `lib/helpers/local_notification_service.dart` | Android channel + heads-up UI |
| Payload routing | `lib/core/services/notification_manager.dart` | Refresh feed/docs; navigation stub |
| Background isolate | `lib/main.dart` | `_firebaseMessagingBackgroundHandler` |
| Chat push hooks | `lib/core/services/private_chat_notification_service.dart` | Stub — not wired into FCM |
| App presence | `lib/core/services/app_status_service.dart` | Reports FG/BG to Laravel |
| In-app center | `lib/core/widgets/notifications_modal.dart` | Feed UI, mark read, delete |
| Types | `lib/core/constants/push_types.dart` | `document_uploaded`, `sync_notifications`, `private_chat_message` |

---

## 2. State-by-state assessment

### 2.1 Foreground — mostly working

**What happens**

1. `FirebaseMessaging.onMessage` → `FcmService.handlePushMessage`
2. Always shows a local notification via `LocalNotificationService.showNotification`
3. Dispatches data to `NotificationManager.handlePushPayload` (refresh notifications + unread; refresh documents if `document_uploaded`)
4. iOS also enables system presentation: `setForegroundNotificationPresentationOptions(alert/badge/sound: true)`

**What works well**

- Clear separation: FCM service does not touch controllers; `NotificationManager` does
- Local notification channel (`casazero_alerts`) is created with max importance, sound, vibration, badge
- Content resolution falls back across many data keys and localizes ticket content (EN/IT)
- Duplicate FCM deliveries are deduped by `messageId`
- Permission request covers iOS + Android 13+ (`Permission.notification`)

**Needs improvement**

| Issue | Severity | Detail |
|-------|----------|--------|
| Possible double banners on iOS | Medium | System presentation options **and** local notification both fire. Users may see two alerts for one push. Prefer one path: either disable system presentation and keep local only, or skip local show when `message.notification != null` on iOS. |
| Local notification tap ignored | High | `LocalNotificationService.initialize()` has no `onDidReceiveNotificationResponse`. Tapping a foreground banner does nothing (no payload passed to `show()` either). |
| Chat type not handled | Medium | `private_chat_message` case is empty; chat list / conversation is not refreshed |

**Verdict:** Display and feed refresh work. Tap-through and iOS double-display need fixes.

---

### 2.2 Background (app not visible, process alive) — partially working

**What happens**

- If the FCM payload includes a `notification` block → **OS** renders the tray notification (title/body come from the backend language).
- If the payload is **data-only** (`message.notification == null`) → background Dart handler shows a localized local notification.
- Background handler **does not** call `NotificationManager` (correct: separate isolate, no GetX controllers).
- On resume, `AppLifecycleRefreshWrapper` + `AppStatusService` refresh the feed / report status.

**What works well**

- Background handler is top-level with `@pragma('vm:entry-point')` and initializes Firebase + GetStorage safely
- Correct split: don’t touch UI controllers from the isolate
- Data-only pushes still get a localized banner
- App status reporting lets the backend gate pushes when the app is in foreground

**Needs improvement**

| Issue | Severity | Detail |
|-------|----------|--------|
| Notification-payload language | Medium | OS shows backend language; data-only path localizes on device. Inconsistent UX depending on payload shape. Prefer data-only + local display, or send bilingual fields and resolve on client for both paths. |
| No sync until resume | Low | Feed/unread stay stale until the user opens the app again (acceptable for most apps; badge on OS tray still works if backend sets it). |
| Tap navigation stub | High | `onMessageOpenedApp` refreshes data but `handleNotificationNavigation` only logs — no route to chat, documents, or tickets. |

**Verdict:** Delivery and display are fine. Deep-link navigation on tap is missing.

---

### 2.3 Terminated / app closed — partially working

**What happens**

- OS shows the system notification when a `notification` block is present (or data-only may wake the background handler depending on platform/OEM).
- Cold start: `getInitialMessage()` → `_onNotificationOpenedApp` → refresh + stub navigation.

**What works well**

- Terminated launch path is registered and wired the same as background tap
- Android default channel meta-data matches Dart channel id (`casazero_alerts`)
- iOS: `remote-notification` background mode, APNs → FCM token bridging in `AppDelegate.swift`

**Needs improvement**

| Issue | Severity | Detail |
|-------|----------|--------|
| Same navigation stub as background | High | User opens the app from a push and lands on the default home screen with no context. |
| Race on cold start | Medium | `getInitialMessage` may fire before `HomeController` / routes are ready. Refresh may no-op if controllers are not registered yet; navigation would also fail. Consider queuing the pending payload until after splash/auth binding. |
| Android icon | Low | Uses launcher icon; no dedicated `default_notification_icon` / white silhouette status-bar icon. |
| iOS entitlements in repo | Low | No checked-in `.entitlements` for Push; capability may exist only in Xcode/Apple portal — risky for CI/new machines. |

**Verdict:** System display works. Cold-start deep linking and controller-ready timing need work.

---

## 3. Scorecard

| Capability | Foreground | Background | Terminated |
|------------|------------|------------|------------|
| Permission request | Good | — | — |
| Token obtained | Good | — | — |
| Token sent to backend | Partial (login only) | — | — |
| Banner / tray display | Good* | Good | Good |
| Feed / unread refresh | Good | On resume | On open / resume |
| Document list refresh | Good (typed) | On resume | On open |
| Chat list / conversation refresh | Missing | Missing | Missing |
| Tap → deep navigation | Broken | Stub | Stub |
| Local banner tap | Broken | N/A (OS tap) | N/A |
| Localization of banner | Good (local path) | Mixed | Mixed (OS language) |

\*iOS may double-display.

---

## 4. Cross-cutting gaps

### 4.1 Deep-link navigation is a stub (highest priority)

```dart
// notification_manager.dart — handleNotificationNavigation
// Future: document_uploaded → open document screen;
//         new_message → open chat; announcement → open feed
```

Today it only prints the type. Recommended mapping:

| `type` | Destination |
|--------|-------------|
| `document_uploaded` | Documents tab / specific document |
| `private_chat_message` / `private_chat` / `group_chat` | Private/group chat conversation |
| ticket / maintenance types | Ticket detail or maintenance section |
| `sync_notifications` / default | Notification center modal |

Also wire `LocalNotificationService` with:

- `payload` in `show()` (JSON of FCM data)
- `onDidReceiveNotificationResponse` → same navigation path
- `getNotificationAppLaunchDetails()` for terminated local-notification launch

### 4.2 FCM token lifecycle is incomplete

- Token is attached only on `POST /user/login` as `fcm_token`
- `registerAfterAuth()` and `onTokenRefresh` update the **local** cache only
- Token rotation (common on iOS/Android) is never re-sent until the next login → **silent push failure** for long-lived sessions

**Recommendation:** Add `POST /update-fcm-token` (or reuse an existing profile endpoint) and call it from `onTokenRefresh`, `registerAfterAuth`, and after permission grant on resume.

### 4.3 Chat push type mismatch

| Source | Type string |
|--------|-------------|
| `PushTypes.privateChatMessage` | `private_chat_message` |
| Outgoing chat API (`PrivateChatController`) | `private_chat` / `group_chat` |
| In-app feed model (`FeedItemModel`) | recognizes `private_chat` |

`PrivateChatNotificationService.handleIncomingPayload` is never called from `FcmService` / `NotificationManager`. Even if called, type filtering would miss `private_chat`.

**Recommendation:** Align on one canonical type (or accept aliases), and dispatch chat payloads into the private-chat service.

### 4.4 In-app notification center vs push

The in-app center (bell, modal, home “latest notifications”) is solid: fetch, unread badge, mark read, delete, document open. Non-document taps mostly only mark as read — no navigation to chat/tickets. Align modal tap behavior with push deep links so both entry points feel the same.

### 4.5 Platform polish

**Android**

- Channel + `POST_NOTIFICATIONS` + default channel meta-data: good
- Consider `VIBRATE` if vibration is required on older APIs
- Add a monochrome notification icon (`@drawable/ic_stat_...`) and `default_notification_icon` meta-data

**iOS**

- AppDelegate APNs ↔ FCM wiring: good
- Resolve double foreground presentation
- Check Push Notifications entitlement is committed / documented for the team

---

## 5. What is already in good shape

1. **Clean layering** — `FcmService` → `NotificationManager` → controllers; no controller calls from the background isolate  
2. **Foreground local banners** with BigText style, max priority channel  
3. **Content localizer** for ticket/support copy (EN/IT)  
4. **Dedup** by FCM `messageId`  
5. **Permission recovery** on resume when the user enables notifications in Settings  
6. **Token delete** on logout / session expiry  
7. **App status** reporting so Laravel can suppress redundant pushes while the app is open  
8. **In-app feed APIs** (list, unread, mark read, delete) and UI (bell badge, modal, preferences card)  
9. **Native plumbing** — Android channel meta-data, iOS `remote-notification`, Firebase init in AppDelegate  

---

## 6. Recommended priority order

1. **P0 — Deep navigation** from FCM tap (background + terminated) and local notification tap (foreground)  
2. **P0 — Queue pending launch payload** until after splash/auth so cold start does not drop navigation  
3. **P1 — Re-register FCM token** with backend on refresh / after auth (not only login)  
4. **P1 — Fix chat type strings** and wire `PrivateChatNotificationService` into the FCM dispatch path  
5. **P2 — iOS double banner** (pick system OR local in foreground)  
6. **P2 — Align in-app modal taps** with the same navigation map as push  
7. **P3 — Android notification icon**, bilingual consistency for OS-displayed payloads  

---

## 7. Suggested acceptance tests

| # | Scenario | Expected |
|---|----------|----------|
| 1 | App open, receive document push | One banner; unread badge updates; documents refresh |
| 2 | App open, tap banner | Opens documents (or correct screen), not just dismiss |
| 3 | App backgrounded, receive push | Tray notification appears |
| 4 | Tap tray notification | App opens on the correct screen |
| 5 | Force-stop app, receive push, tap | Cold start → correct screen after login/splash |
| 6 | Chat message push while in another chat | Conversation / list updates; tap opens that thread |
| 7 | Token refresh (reinstall or long session) | Backend still delivers pushes without re-login |
| 8 | Deny then grant notification permission | Token refreshed and registered; banners work |
| 9 | Switch app language to IT | Banner title/body in Italian (especially data-only / local path) |
| 10 | Logout | Token deleted; no further pushes to that device |

---

## 8. Summary

Push **delivery and display** across foreground, background, and terminated are largely in place and correctly structured. The biggest product gaps are **tap → navigation** (stub everywhere), **local-notification tap** (not wired), **token re-registration** (login-only), and **chat push integration** (type mismatch + unused service). Fixing those four areas will take the notification experience from “alerts show up” to “alerts take you to the right place reliably.”
