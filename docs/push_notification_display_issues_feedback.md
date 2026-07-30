# CasaZero — Push Notification Display Issues Feedback

**Date:** 26 Jul 2026  
**Reported symptoms:** Native tray / heads-up notification appears when the app is in **background**, but **not** when the app is **foreground (active)** or **killed / closed**.  
**Scope:** Display path only (not deep-link navigation).  
**Stack:** `firebase_messaging` ^16.0.4 + `flutter_local_notifications` ^19.5.0  
**Observed device context:** Android / MIUI (`com.example.casazero` logs).

---

## 1. Verdict

Background display working while foreground and terminated fail is **expected** given how this codebase splits responsibilities — unless the backend always sends a visible `notification` block and the client always shows a local banner in foreground.

| App state | Who can show a banner | Current client behavior | Likely failure mode |
|-----------|----------------------|-------------------------|---------------------|
| **Background** (process alive) | OS (if `notification` block) **or** Dart background handler (data-only → local) | Handler shows local when `message.notification == null` | Works — matches report |
| **Foreground** | **Not** the OS on Android; must be `LocalNotificationService` via `onMessage` | Local show is coded, but depends on deferred `FcmService.init()` and OEM heads-up rules | Banner missing |
| **Killed / force-closed** | **Only** the OS (needs FCM `notification` + `data`). Data-only often never wakes Dart on OEM ROMs | Background handler cannot run reliably when process is dead | Banner missing |

**Primary suspects (ordered):**

1. **Backend payload shape** — data-only (or silent) pushes rely on a live Dart isolate; that works in background, fails when killed.
2. **Foreground path is 100% local-notification dependent on Android** — any miss in `onMessage` / plugin / MIUI = no banner.
3. **`AppStatusService` lifecycle gap** — kill may leave backend believing the app is still `foreground` (dangerous once `/update-app-status` exists).
4. **Deferred FCM listener setup** — `FcmService.init()` runs after `runApp` and is not awaited.

---

## 2. How display is wired today

```
main.dart (critical)
  ├─ Firebase.initializeApp
  ├─ FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)
  ├─ PushLaunchHandler.install()          // open / cold-start tap only
  └─ LocalNotificationService.initialize() // channel casazero_alerts_v2

main.dart (deferred, after runApp)
  └─ FcmService.init()
        ├─ requestPermission + getToken
        ├─ onMessage → handlePushMessage → LocalNotificationService.show  // FOREGROUND DISPLAY
        └─ iOS setForegroundNotificationPresentationOptions

Background isolate (_firebaseMessagingBackgroundHandler)
  └─ if notification == null → LocalNotificationService.show  // DATA-ONLY ONLY

Terminated
  └─ No Dart code runs unless OS delivers a notification-payload FCM message
```

Relevant files:

| File | Role |
|------|------|
| `lib/main.dart` | Background handler; Firebase + local init order |
| `lib/core/services/fcm_service.dart` | Foreground `onMessage` → local banner |
| `lib/helpers/local_notification_service.dart` | Channel `casazero_alerts_v2`, `show()` |
| `lib/core/services/app_status_service.dart` | Reports FG/BG to Laravel |
| `android/.../AndroidManifest.xml` | `default_notification_channel_id` = `casazero_alerts_v2` |

---

## 3. Issue analysis by app state

### 3.1 Background — working (baseline)

**Why it works**

- Process is still alive.
- If FCM includes a `notification` block → system tray shows it.
- If payload is **data-only** → `_firebaseMessagingBackgroundHandler` runs and calls `LocalNotificationService.showNotification`.

```46:54:lib/main.dart
  // Data-only pushes: show localized local notification with tap payload.
  // Notification-payload pushes are rendered by the OS; taps use PushLaunchHandler.
  if (message.notification == null) {
    try {
      await LocalNotificationService.showNotification(message);
    } catch (e) {
      print('❌ [FCM Background] Local notification error: $e');
    }
  }
```

This is the only state where **both** OS display and Dart fallback can succeed. That explains why background looks “fine” while other states do not.

---

### 3.2 Foreground / app active — native banner missing

#### Root cause A (architecture): Android never auto-shows FCM in foreground

When the app is open, Firebase delivers the message to `FirebaseMessaging.onMessage` only. The system tray does **not** render FCM’s `notification` block on Android. Display **must** go through `LocalNotificationService`.

```226:240:lib/core/services/fcm_service.dart
  /// Android: always show local (OS does not show FCM banners while foreground).
  Future<void> handlePushMessage(RemoteMessage message) async {
    try {
      final skipLocalOnIos =
          !kIsWeb && Platform.isIOS && message.notification != null;
      if (skipLocalOnIos) {
        // ...
      } else {
        await LocalNotificationService.showNotification(message);
      }
```

If the user expects a “native” FCM tray item while the app is open, that will never happen on Android by design. The product must treat the **local** heads-up as the foreground banner.

#### Root cause B (P0): `FcmService.init()` is deferred and fire-and-forget

```124:128:lib/main.dart
Future<void> _initializeDeferredServices() async {
  InitialBinding.registerFirebaseDependentServices();
  // ...
}
```

```127:128:lib/app/bindings/initial_binding.dart
    if (Get.isRegistered<FcmService>()) {
      Get.find<FcmService>().init();  // not awaited
```

Consequences:

- `onMessage` listener is registered **after** first frame, not during critical startup.
- iOS `setForegroundNotificationPresentationOptions` is also delayed.
- Early foreground pushes (or a slow init failure) produce **no banner**.

**Recommendation:** Await `FcmService.init()` on the critical path (or immediately after Firebase + `LocalNotificationService.initialize()`), before relying on foreground display.

#### Root cause C (P1): Backend may not send a visible push while “active”

`AppStatusService` is explicitly designed so Laravel can gate pushes:

```8:11:lib/core/services/app_status_service.dart
/// Reports foreground/background lifecycle to Laravel so push delivery can be gated.
class AppStatusService extends GetxService with WidgetsBindingObserver {
  static const String _foreground = 'foreground';
  static const String _background = 'background';
```

If the backend suppresses FCM while `app_status == foreground`, the client will correctly show **nothing** in the tray (in-app feed refresh alone is not a native banner).

**Runtime note (26 Jul 2026):** device logs show:

```text
POST .../api/update-app-status → 404
The route api/update-app-status could not be found.
```

So gating via this endpoint is **not live** today. Either:

- another server-side rule suppresses foreground pushes, or  
- the push **is** delivered and the local-notification path is failing (B / D / E).

Confirm with logs: look for `📨 [FcmService] Foreground push` and `📣 [LocalNotificationService] Shown`.

| Log present? | Meaning |
|--------------|---------|
| No `Foreground push` | Push not delivered (backend / token / gating) |
| `Foreground push` but no `Shown` | Local plugin / permission / exception |
| Both present, still no UI | OEM / channel / heads-up / icon (esp. MIUI) |

#### Root cause D (P1): MIUI / OEM heads-up behavior

Logs confirm **MIUI**. Xiaomi frequently:

- Blocks heads-up while the app is in the foreground
- Requires “Autostart”, “Show on Lock screen”, and unrestricted battery for reliable alerts
- Demotes channels or collapses banners

Channel id was bumped to `casazero_alerts_v2` (correct approach — Android never raises importance of an existing channel). Still verify on-device that **CasaZero Alerts** is Importance = Urgent / High and that “Display pop-up windows” / floating notifications are allowed for the app.

#### Root cause E (P2): Notification small icon uses launcher mipmap

```334:334:lib/helpers/local_notification_service.dart
      icon: '@mipmap/ic_launcher',
```

Android status-bar icons should be a **white silhouette** (`@drawable/ic_stat_...`). A full-color launcher icon can render blank or be rejected by some OEM notification pipelines. Prefer a dedicated mono icon + `com.google.firebase.messaging.default_notification_icon` in the manifest.

#### Root cause F (iOS-only): System presentation vs local

On iOS, when `message.notification != null`, local show is **skipped** and system presentation options are used. If those options are not set yet (deferred init) or APNs permission is limited, foreground alert can be silent. Data-only foreground still uses local banners.

---

### 3.3 Killed / closed — native banner missing

#### Root cause A (P0): Data-only FCM does not display when the process is dead

When the app is killed:

- `_firebaseMessagingBackgroundHandler` often **does not run** (especially on MIUI / aggressive OEMs, and always after **Force stop**).
- The only reliable tray UI is an FCM message that includes a top-level **`notification`** block (title/body), optionally with a `data` map for deep links.

Current client only synthesizes a local banner for data-only messages **inside the background isolate**:

```dart
if (message.notification == null) {
  await LocalNotificationService.showNotification(message);
}
```

That path works in **background** (isolate can start) and fails in **terminated** (isolate often never starts). This single fact explains the reported matrix almost completely if the backend sends data-only (or “data + content_available”) payloads.

**Recommendation for backend (required for killed-state display):**

```json
{
  "notification": {
    "title": "...",
    "body": "..."
  },
  "data": {
    "type": "document_uploaded",
    "reference_id": "123",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "casazero_alerts_v2",
      "priority": "max"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "alert": { "title": "...", "body": "..." },
        "sound": "default"
      }
    }
  }
}
```

Do **not** rely on data-only for user-visible alerts when the app may be killed.

#### Root cause B (P0): `AppStatusService` never reports background on kill

```42:55:lib/core/services/app_status_service.dart
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_reportStatus(_foreground));
        break;
      case AppLifecycleState.paused:
        unawaited(_reportStatus(_background));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break; // ← kill / swipe-away often never hits paused → background
    }
  }
```

Typical kill / swipe-away sequence may hit `inactive` → `detached` **without** a durable `paused` report. Backend (once `/update-app-status` is deployed) can keep `foreground` and **suppress** pushes precisely when the user needs them most.

**Recommendation:**

- Treat `paused`, `hidden`, and `detached` as `background`.
- Optionally send `background` from `AppLifecycleListener` / `WidgetsBindingObserver` with a short debounce.
- On next cold start, always re-sync status.

#### Root cause C (P1): Force stop vs “closed from recents”

| User action | FCM behavior |
|-------------|--------------|
| Home / switch app (background) | Delivery OK (matches current success case) |
| Swipe away from recents | OEM-dependent; MIUI often kills process → data-only fails |
| Settings → Force stop | **No FCM** until user opens the app again |

Acceptance tests must distinguish these. “App closed” on MIUI is often equivalent to process death.

#### Root cause D (P2): Default channel exists only after Dart init

Manifest points FCM at `casazero_alerts_v2`, which is created in `LocalNotificationService.initialize()`. After the user has opened the app once, the channel exists and OS can use it while killed. Fresh install + kill before first successful init is an edge case. Still safe to also create the channel from native Application code if killed-state reliability is critical before first Flutter frame.

#### Root cause E (P2): Token lifecycle still login-bound

FCM token is sent to the backend mainly via `fcm_token` on `POST /user/login`. `onTokenRefresh` only updates the **local** cache. Long-lived sessions or token rotation can cause silent delivery failure (sometimes mistaken for “killed doesn’t work”). Less likely here because **background still works** on the same install, but still a production risk.

---

## 4. Confirmed runtime findings (from device logs)

| Finding | Evidence | Impact |
|---------|----------|--------|
| MIUI device | `MIUIInput` / `VRI[MainActivity]` logs | Aggressive background / notification policies |
| App status API missing | `POST /update-app-status` → **404** | Client gating contract broken; when route is added, lifecycle bug (3.3-B) becomes critical |
| Background status attempted | `updateAppStatus status=background` on hide | Client tries to cooperate; server ignores |

---

## 5. Scorecard (display only)

| Capability | Foreground | Background | Killed |
|------------|------------|------------|--------|
| FCM delivery (token OK) | Unknown — verify logs | Working | Likely blocked if data-only / force-stop |
| OS / “native” tray banner | **No on Android** (by design) | Yes (notif block) or local | **Only if `notification` block** |
| Local heads-up banner | Intended path; currently unreliable | Used for data-only | Not available |
| Channel `casazero_alerts_v2` | Created in Dart | Same | Depends on prior open |
| App-status gating | Reports FG; API 404 | Reports BG on pause only | Often never reports BG |

---

## 6. Recommended fixes (priority)

### P0 — Make killed-state display work

1. **Backend:** Always send FCM with both `notification` and `data` for user-visible events. Include `android.notification.channel_id = casazero_alerts_v2` and high priority.
2. **Client:** Document that data-only is for silent sync (`sync_notifications`) only — never for alerts the user must see when the app is closed.
3. **Client:** On `detached` / `hidden` / `paused`, report `background` (and fix or remove the 404 `/update-app-status` contract with backend).

### P0 — Make foreground display work

1. **Move `FcmService.init()` earlier** and **await** it (same phase as local notification init).
2. **Verify with logs** whether `onMessage` fires; if not, fix backend delivery / gating; if yes but no UI, fix local plugin / MIUI / icon.
3. **Product expectation:** On Android foreground, the banner is always `flutter_local_notifications`, not the FCM system notification.

### P1 — Harden local / OEM display

1. Add `@drawable/ic_stat_casazero` (white silhouette) and set it as local + `default_notification_icon`.
2. Keep channel importance `max`; avoid renaming again without a new id.
3. Add a short in-app / QA note for MIUI: Autostart + no battery restriction + floating notifications.

### P2 — Hygiene

1. Re-register FCM token with backend on refresh / session restore (not only login).
2. Optionally create the Android notification channel in native code so it exists before any Flutter run.
3. Align chat push payloads (`private_chat` vs `private_chat_message`) so display + navigation stay consistent (separate from display, but often tested together).

---

## 7. Suggested debug / acceptance checklist

Run these on the **same device** that shows the bug (ideally MIUI + a stock Android):

| # | Test | Pass criteria | What to watch in logcat |
|---|------|---------------|-------------------------|
| 1 | App open → send push with `notification` + `data` | Heads-up / shade entry appears | `Foreground push` + `LocalNotificationService] Shown` |
| 2 | App open → data-only push | Local banner still appears | Same as above |
| 3 | App background (Home) → same payload as #1 | Tray notification | OS or `FCM Background` |
| 4 | Swipe away from recents → wait 10s → push with **`notification` block** | Tray notification without opening app | No Dart logs required |
| 5 | Same as #4 but **data-only** | Expect **fail** on MIUI — proves root cause 3.3-A | No `FCM Background` line |
| 6 | Force stop → push | Expect **fail** until app opened (Android policy) | — |
| 7 | Kill app → confirm backend `app_status` | Should be `background`, not stuck `foreground` | After API exists |

---

## 8. Summary

Native banners work in **background** because a live process can either let the OS render a `notification` payload or run the Dart handler for data-only messages. They fail in **foreground** because Android will not show FCM natively and the app’s local-banner path is deferred / OEM-sensitive / possibly never reached if the push is not sent. They fail when **killed** because data-only (or any path that needs Dart) does not run, and `AppStatusService` may leave the server thinking the user is still in foreground once status gating is enabled.

Fix **payload shape + foreground local init timing + lifecycle status reporting** first; then polish MIUI/channel/icon. Until the backend always includes a visible `notification` block for user alerts, terminated-state “native push” will remain unreliable on this device class.
