# FCM Analysis — Why Push Works for Some Users and Not Others

**Project:** CasaZero Flutter app  
**Date:** 2026-06-11  
**Scope:** Full client-side FCM flow (token registration, backend sync, delivery, permissions, user flows)

---

## Executive summary

FCM in this app has **two separate problems** that are often confused:

| Layer | Question | If broken, user sees… |
|-------|----------|------------------------|
| **1. Token registration** | Is this device’s FCM token stored on Laravel for this user? | **No pushes at all** (server sends to wrong/missing token) |
| **2. Message delivery** | When FCM arrives, does the app show it and refresh in-app data? | Push “missing” in tray or bell icon not updating |

**User-to-user variance** is mostly caused by **different login/navigation paths**, **timing races at cold start**, **notification permission state**, **iOS native setup gaps**, and **backend not persisting the token or notification record**.

Push is **not role-gated in Flutter** — admin vs resident use the same `FcmService`. Differences come from **auth flow**, **device trust / 2FA**, **platform**, and **server-side user/device records**.

---

## How FCM is wired in this codebase

### Key files

| File | Responsibility |
|------|----------------|
| `lib/main.dart` | Firebase init (10s timeout), background handler registration |
| `lib/app/bindings/initial_binding.dart` | Registers `FcmService`, calls `init()` (fire-and-forget) |
| `lib/core/services/fcm_service.dart` | Permissions, token, `POST /user/update-fcm-token`, listeners |
| `lib/data/repositories/auth_repository.dart` | Sends `fcm_token` on login; deletes FCM token on logout |
| `lib/presentation/auth/controllers/auth_controller.dart` | `sendTokenToBackend()` after login |
| `lib/presentation/otp_verification/controllers/otp_verification_controller.dart` | `sendTokenToBackend()` after OTP success (login flow only) |
| `lib/presentation/splash/controllers/splash_controller.dart` | Auto-login to HOME — **no** explicit FCM re-register |
| `lib/helpers/local_notification_service.dart` | Foreground tray notifications |
| `lib/core/services/notification_manager.dart` | Refreshes home notifications/documents from REST API |

### Backend endpoints

| Endpoint | When used | Body |
|----------|-----------|------|
| `POST /user/login` | Every login | `fcm_token` (may be empty string) |
| `POST /user/update-fcm-token` | Init (if session exists), after login, after OTP, on token refresh | `{ "fcm_token": "..." }` with Bearer token |

**Important:** `StorageKeys.DEVICE_TOKEN` is Laravel’s **trusted-device token** from login — it is **not** the FCM token.

---

## End-to-end flow (registration)

```
App start
  → Firebase.initializeApp() [main.dart, may fail/timeout]
  → InitialBinding: FcmService.init() [async, not awaited]
       → requestPermission()
       → getToken()
       → sendTokenToBackend()  ← skipped if no access token yet
  → User logs in
       → login payload includes fcm_token
       → AuthController.sendTokenToBackend()
  → Untrusted + 2FA user
       → OTP success → sendTokenToBackend() again
  → onTokenRefresh → sendTokenToBackend()
```

### Conditions where token is **not** sent to backend

From `FcmService.sendTokenToBackend()`:

1. Firebase not initialized (`Firebase.apps.isEmpty`)
2. `getToken()` returns null/empty (permissions denied, iOS APNs issues, init failure)
3. **No Laravel access token** in storage (user not logged in yet)
4. Token unchanged since last successful send (`_lastSentToken` dedup)
5. `StorageService` or `ApiService` not registered yet
6. API call fails (network, **404** on missing route, 401 after session cleared) → sets `_pendingTokenSend = true`

---

## Why some users get push and others do not

### 1. User login / navigation path (high impact)

Different users hit different post-login routes. FCM re-registration is **not identical** on all paths.

| User scenario | `fcm_token` in login API | `update-fcm-token` after login | Notes |
|---------------|--------------------------|--------------------------------|-------|
| **Trusted device → HOME** | Yes | Yes (`AuthController`) | Usually works if token available at login |
| **Untrusted + 2FA → OTP → HOME** | Yes (may be empty at login) | Yes after OTP (`OtpVerificationController`) | Extra register after OTP; better if token was late |
| **First login (admin-set password)** | Yes | Yes (`AuthController`) then FIRST_LOGIN screen | No FCM code on first-login screen itself |
| **Untrusted, no 2FA → HOME** | Yes | Yes (`AuthController`) | Same as trusted for FCM |
| **Splash auto-login (session restore)** | N/A | **Only** via `FcmService.init()` at cold start | **No** `sendTokenToBackend()` in splash |
| **OTP cancelled (login flow)** | N/A | **No** — `clearAll()` only | FCM token **not** deleted; server may still target old token |
| **Document password + OTP** | N/A | **Not** on doc-password OTP success | Irrelevant to push unless user never completed login FCM path |

**Typical failure:** User logs in on a **slow device** or **denies permission initially**. Login sends `fcm_token: ""`. User later grants permission, but never logs out/in again and never hits OTP re-register → backend has **no valid token**.

**Typical success:** User on **trusted device** or completes **OTP** after token is ready → two chances to register (`login` + `update-fcm-token`).

---

### 2. Cold-start timing race (medium impact)

In `initial_binding.dart`:

```dart
fcmService.init(); // fire-and-forget; not awaited
```

`init()` runs in parallel with splash (3.5s) and possible navigation. Sequence matters:

- If `init()` runs **before** login completes → `sendTokenToBackend()` skips (no access token).
- Recovery depends on `AuthController.sendTokenToBackend()` after login — **unless** login happened before token was obtained (race).

Also: if user **already has session** from splash, registration depends entirely on init-time `sendTokenToBackend()`. Splash does **not** call it explicitly.

---

### 3. Notification permissions (high impact)

`FcmService._requestPermission()`:

- Requests Firebase permission (iOS) and `Permission.notification` (Android 13+).
- **Logs** `authorizationStatus` but **does not block** token fetch or backend send based on denial.

Effects:

| Permission state | FCM token | User experience |
|------------------|-----------|-----------------|
| Granted | Usually obtained | Push can work |
| Denied / not determined (iOS) | Often null or unreliable | Login sends `""`; no backend mapping |
| Denied then enabled in Settings later | Token may appear on refresh | May work only after **app restart** or `onTokenRefresh` **if** user still logged in |

**This alone explains “works on my phone, not on theirs”** when users differ on notification permission.

---

### 4. iOS vs Android native setup (high impact on iOS users)

#### Android

- `POST_NOTIFICATIONS` in `AndroidManifest.xml` ✓
- `google-services.json` for `com.example.casazero` ✓
- FCM generally works if token registers and backend sends correctly

#### iOS — active `ios/Runner/AppDelegate.swift`

Current AppDelegate only calls `FirebaseApp.configure()`. It does **not**:

- Call `application.registerForRemoteNotifications()`
- Set `UNUserNotificationCenter` delegate
- Set `Messaging.messaging().delegate`
- Forward APNs device token to FCM

#### iOS — backup reference `ios_backup/Runner/AppDelegate.swift`

Contains the **full** FCM/APNs setup (permission request, `registerForRemoteNotifications`, `MessagingDelegate`, APNs token forwarding).

#### iOS `Info.plist`

- **Missing** `UIBackgroundModes` → `remote-notification`
- No push-specific entitlements documented in repo

**Conclusion:** iOS users are more likely to have **missing or delayed FCM tokens** compared to Android users, unless `firebase_messaging` plugin fully compensates via Dart-only APIs (often insufficient without APNs registration on real devices).

Bundle ID `com.attoexa.casazero` matches `GoogleService-Info.plist` ✓ — configuration file is present, but **native push registration is minimal**.

---

### 5. Firebase initialization failure (medium impact)

`main.dart` wraps Firebase init in 10s timeout. On failure:

- App continues without Firebase
- `FcmService` skips entirely (`Firebase.apps.isEmpty`)
- **No push for that install/session**

Users on slow networks or devices may hit this intermittently.

---

### 6. Backend / server-side (high impact, not visible in Flutter alone)

Even with a valid client token, push fails if:

| Server issue | Symptom |
|--------------|---------|
| Laravel stores `fcm_token` only on login but **overwrites** on multi-device login | Only **last logged-in device** gets push |
| `POST /user/update-fcm-token` returns **404** (logged in `FcmService`) | Token never updated after login |
| Server sends FCM but **does not** create row for `GET /get_user/notifications` | Tray may show nothing; **bell modal empty** |
| Server sends **data-only** messages | Background/terminated may be silent (see below) |
| User disabled notification preferences in profile | Server may skip sending (Laravel-side) |

Client logs on failed register:

```
❌ [FcmService] POST /user/update-fcm-token returned 404 — add this route on Laravel...
```

---

### 7. Logout and session edge cases (medium impact)

| Logout path | FCM `deleteToken()` | Server unregister |
|-------------|---------------------|-------------------|
| `AuthRepository.logout()` (profile/home) | Yes | Depends on Laravel logout API |
| OTP cancel `_logout()` | **No** | Local session cleared; server may still have old FCM token |

After `ApiService` **401** refresh failure, access token is cleared → subsequent `sendTokenToBackend()` calls skip until re-login.

---

### 8. “Push received” vs “in-app notification list” (UX confusion)

These are **different systems**:

- **FCM** → foreground: local notification + `NotificationManager` → `HomeController.fetchNotifications()`
- **Notifications modal** → only shows data from `POST /get_user/notifications`

A user can appear to “not get notifications” when:

- FCM arrived but backend never persisted the notification record
- FCM was data-only with no `notification` block (empty tray in foreground)
- Background handler only **prints** — no local notification for data-only background messages

See also: `PUSH_NOTIFICATION_ANALYSIS.md` for delivery/modal details.

---

## User comparison matrix (quick reference)

| Factor | User A (push works) | User B (push fails) |
|--------|---------------------|---------------------|
| Platform | Android, notifications ON | iOS, minimal AppDelegate / APNs |
| Login path | Trusted or completed OTP | Stuck at first login, or login before token ready |
| Session | Fresh login with token | Splash restore only; init race; empty token at login |
| Permission | Granted at first prompt | Denied; never re-triggered register |
| Backend | Token saved; notifications persisted | Token empty; or last-device overwrite |
| Payload | Notification + data | Data-only, app in background |

---

## Diagnostic checklist (per affected user)

Ask support/dev to capture logs for these lines:

### Token registration

```
🔑 [FcmService] Token: ...
📤 [FcmService] No auth token, skip sending FCM token
📤 [FcmService] Token unchanged, skip send
✅ [FcmService] Token sent to backend
❌ [FcmService] Error sending token to backend: ...
❌ [FcmService] POST /user/update-fcm-token returned 404
```

### Login payload

```
FCM Token: <empty or value>
```

### Firebase health

```
✅ Firebase initialized successfully
❌ Firebase initialization failed
⚠️ [FcmService] Firebase not initialized, skipping
[FirebaseAudit] ...
```

### Delivery (after server sends)

```
📨 [FcmService] Foreground push
📩 [FCM Background] messageId: ...
📬 [NotificationManager] Push type: ...
```

### Backend verification (outside app)

1. Check Laravel user record: is `fcm_token` populated for this user/device?
2. Send test FCM from Firebase Console to that exact token.
3. Confirm notification row exists in DB before/after FCM for modal visibility.

---

## Root causes ranked by likelihood

1. **Empty or stale FCM token on backend** — permission denied, login before token ready, splash/init race, no re-register after permission granted  
2. **iOS APNs / native setup gap** — active AppDelegate vs full setup in `ios_backup`  
3. **Multi-device token overwrite** — only one device per user receives push (backend behavior)  
4. **Backend not persisting notification for REST modal** — user thinks push “doesn’t work”  
5. **Data-only FCM payload + app backgrounded** — background handler does not show notification  
6. **Firebase init timeout** — entire FCM stack inactive  
7. **`update-fcm-token` API missing or failing** — 404 / network  

---

## Recommended fixes (prioritized)

### P0 — Client

1. **Await FCM init after login/session restore**  
   Call `await FcmService.sendTokenToBackend()` from splash when access token exists, not only from init.

2. **Re-register when permission granted**  
   If `authorizationStatus` is denied then user enables in Settings, re-call `getToken()` + `sendTokenToBackend()` on app resume.

3. **Restore iOS native FCM setup**  
   Port APNs registration + `MessagingDelegate` from `ios_backup/Runner/AppDelegate.swift` into active `ios/Runner/AppDelegate.swift`. Add `remote-notification` background mode to `Info.plist`.

4. **Remove useless guard**  
   `fcmService.toString().contains('FcmService')` is always true — replace with proper null/check.

### P1 — Client

5. **OTP cancel logout** — call `fcmService.deleteToken()` and optionally server unregister.  
6. **Login retry** — if `fcm_token` empty at login, retry `getDeviceToken()` after short delay before `update-fcm-token`.  
7. **Background handler** — for data-only pushes, show local notification or sync via `NotificationManager`.  
8. **Foreground payload** — derive title/body from `message.data` when `message.notification` is null.

### P2 — Backend (verify with Laravel team)

9. Confirm `POST /user/update-fcm-token` exists and returns 200.  
10. Store FCM token **per device** (device_id + fcm_token), not single field per user.  
11. Always persist notification record when sending FCM.  
12. Use hybrid FCM payload (`notification` + `data`) for reliable tray display.

---

## Summary

FCM is **implemented centrally** in `FcmService` and is **not intentionally disabled per user role**. Inconsistent behavior comes from:

- **When** the token reaches Laravel (login vs OTP vs init-only vs never)
- **Whether** the device obtains a token (permissions, iOS native stack, Firebase init)
- **Whether** the backend stores and uses the correct token per device
- **Whether** “not working” means no tray push, empty bell list, or both

**Most actionable client fix for user variance:** ensure token registration runs **after every successful auth** (including splash session restore) and **after permission is granted**, and restore **full iOS APNs integration**.

**Most actionable server check:** verify `fcm_token` in DB for affected users and test direct FCM to that token from Firebase Console.

---

## Related docs

- `PUSH_NOTIFICATION_ANALYSIS.md` — delivery paths, modal vs FCM, payload types  
- `FIREBASE_SETUP.md` — Firebase project setup notes  
