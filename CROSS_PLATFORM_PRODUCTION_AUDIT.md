# CasaZero Flutter Cross-Platform Production Audit

**Project:** CasaZero (`d:\Sajid\casazero`)  
**Audit date:** July 9, 2026  
**Method:** Static analysis only — no source modifications, no runtime device testing  
**Scope:** `lib/`, `android/`, `ios/`, `pubspec.yaml`, Firebase, assets, routing, permissions, services, controllers, repositories, widgets  

**Backend note:** API behavior is inferred from client code. Live backend verification was not performed.

---

## Executive Summary

CasaZero is a **GetX + Dio + Firebase** resident portal with **~206 Dart files**, a **Laravel REST backend**, and **Firestore** for realtime chat. Dart business logic is **largely shared** between Android and iOS — most features use identical widgets, controllers, and API calls.

**Cross-platform parity is NOT production-equal.** Android has stronger native file handling (full MethodChannel, FileProvider, MediaStore indexing). iOS has **critical native gaps** (malformed `Info.plist`, missing camera privacy key, missing push entitlements, incomplete file-opener channel). Both platforms share **identical Dart-level blockers**: broken refresh-token flow, stubbed push navigation, no offline layer, no deep links, and severe security hygiene issues (hardcoded credentials, plaintext token storage, unconditional token logging).

| Dimension | Score / 100 |
|-----------|-------------|
| Flutter Architecture | 78 |
| Android Native | 70 |
| iOS Native | 58 |
| Cross-Platform Consistency | 72 |
| Performance | 68 |
| Security | 42 |
| Accessibility | 55 |
| Responsive UI | 74 |
| Offline Readiness | 35 |
| Notification Reliability | 58 |
| Store Readiness | 48 |
| **Overall Production Readiness** | **62** |

**Verdict:** Suitable for **internal/staging QA on Android**. **Not store-ready** on either platform without resolving critical security, iOS native config, Android signing/package ID, and missing assets.

---

## Platform Comparison

| Area | Android | iOS | Parity |
|------|---------|-----|--------|
| Dart UI & navigation | Shared Flutter code | Shared Flutter code | ✅ Identical |
| Bottom nav visual metrics | Taller bar, full bottom inset | Shorter bar, 38% bottom inset scaling | 🟡 Intentional visual difference |
| FCM permission flow | `permission_handler` + POST_NOTIFICATIONS | `FirebaseMessaging.requestPermission` + APNs | 🟡 Different APIs, same intent |
| File open native channel | 3 methods implemented | 1 of 3 methods | 🔴 Parity broken |
| Camera permission (native) | Likely via plugin merge | Missing `NSCameraUsageDescription` | 🔴 iOS broken |
| Push entitlements | N/A (FCM) | Missing `aps-environment` | 🔴 iOS at risk |
| Package / bundle ID | `com.example.casazero` | `com.attoexa.casazero` | 🔴 Mismatch |
| Release signing | Debug keys | Automatic (team configured) | 🔴 Android not release-ready |
| Orientation | Runtime portrait lock | Plist still allows landscape | 🟡 Config mismatch |
| Privacy Manifest | N/A | Missing `PrivacyInfo.xcprivacy` | 🔴 iOS store risk |

---

## 1. Feature Parity Audit

Legend: ✅ Fully identical · 🟡 Partial difference · 🔴 Broken · ⚪ Missing

| Feature | Android | iOS | Status | Android Behavior | iOS Behavior | Difference | Severity | Recommendation |
|---------|---------|-----|--------|------------------|--------------|------------|----------|----------------|
| **Authentication** | ✅ | ✅ | Identical | Email/password login, device fingerprint, FCM on login | Same Dart code | None in Dart | — | Remove dev pre-filled credentials before release |
| **Session restore** | ✅ | ✅ | Identical | Splash → token check → HOME + Firebase sync | Same | None | — | — |
| **Logout** | ✅ | ✅ | Identical | API + Firebase sign-out + FCM delete + storage clear | Same | OTP cancel logout skips FCM delete (both platforms) | Medium | Align OTP logout with profile logout |
| **Refresh token** | 🔴 | 🔴 | Broken | 401 interceptor calls refresh; token never saved at login | Same | None — both broken | Critical | Persist `refresh_token` from login response |
| **2FA** | ✅ | ✅ | Identical | OTP, TOTP QR, SMS/email flows | Same | None | — | — |
| **Forgot password** | ✅ | ✅ | Identical | OTP → reset password routes | Same | None | — | — |
| **OTP** | ✅ | ✅ | Identical | Login / forgot / 2FA verification | Same | None | — | — |
| **Documents** | ✅ | ✅ | Identical | List, search, filter, upload, delete, share | Same | None | — | — |
| **Downloads** | ✅ | 🟡 | Partial | Native chooser + MediaStore index | Falls back to OpenFilex | iOS lacks `openWithChooser` channel | Medium | Implement iOS MethodChannel parity |
| **Uploads** | ✅ | ✅ | Identical | Multipart/base64 to Laravel | Same | None | — | — |
| **Maintenance** | ✅ | ✅ | Identical | CRUD + file_picker attachment | Same | None | — | — |
| **Tickets** | ✅ | 🟡 | Partial | Gallery + camera photos | Gallery works; camera denied | Missing iOS camera plist key | Critical | Add `NSCameraUsageDescription` |
| **Construction timeline** | ✅ | ✅ | Identical | API phases when `underConstruction` | Same | None | — | — |
| **Group chat** | ✅ | ✅ | Identical | Firestore text realtime | Same | None | — | — |
| **Private chat** | ✅ | ✅ | Identical | `PrivateChatScreen` + conversations collection | Same | None | — | — |
| **AI chat** | ✅ | ✅ | Identical | REST send/history | Same | Ticket shortcuts TODO (both) | Low | Wire AI ticket handlers |
| **Profile** | ✅ | ✅ | Identical | Edit, image, prefs, security cards | Same | None | — | — |
| **Notifications (in-app)** | ✅ | ✅ | Identical | List, badge, mark read, delete | Same | None | — | — |
| **Localization** | ✅ | ✅ | Identical | en/it via GetX translations | Same | None | — | — |
| **Settings** | ✅ | ✅ | Identical | Embedded in profile (no separate screen) | Same | None | — | — |
| **Residence switching** | ✅ | ✅ | Identical | Dialog selector in app bar | Same | None | — | — |
| **Smart Home** | ⚪ | ⚪ | Missing | Mock local devices only | Same mock | No backend either platform | Low | Implement API or hide feature |
| **Maps** | ⚪ | ⚪ | Missing | No maps SDK | Same | N/A | — | — |
| **Deep links** | ⚪ | ⚪ | Missing | No intent filters | No URL schemes | Neither platform | Medium | Add if product requires |
| **Share** | ✅ | ✅ | Identical | `share_plus` on documents | Same | None | — | — |
| **Camera** | 🟡 | 🔴 | Partial / Broken | `image_picker` camera in tickets; manifest may merge CAMERA | Camera will fail without plist | iOS native block | Critical | Fix iOS plist |
| **Gallery** | ✅ | ✅ | Identical | Profile + tickets gallery pick | Same | None | — | — |
| **File picker** | ✅ | ✅ | Identical | Documents, maintenance attachments | Same | None | — | — |
| **Push notifications** | 🟡 | 🟡 | Partial | Receive OK; tap nav stubbed | Receive at risk without entitlements | iOS APNs config | Critical | Entitlements + navigation |
| **Background sync** | 🟡 | 🟡 | Partial | FCM Dart isolate; resume refresh wrapper | Same | No true background sync | Medium | Document expected behavior |
| **Widgets (Flutter)** | ✅ | ✅ | Identical | Shared widget tree | Same | Bottom nav sizing differs | Low | Acceptable platform polish |
| **Navigation** | ✅ | ✅ | Identical | GetX routes + `AppScreen` stack | Same | None in logic | — | — |
| **Bottom navigation** | 🟡 | 🟡 | Partial | Visual: 72.h bar, full inset | Visual: 56.h bar, 0.38× inset | Intentional UX tuning | Low | Document design intent |
| **Drawer** | ⚪ | ⚪ | Missing | No drawer | Same | N/A | — | — |
| **Dialogs** | ✅ | ✅ | Identical | `Get.dialog`, `ResponsiveAlertDialog` | Same | Tickets use SnackBar (both) | Low | Unify feedback pattern |
| **Loading** | ✅ | ✅ | Identical | Spinners + construction skeleton | Same | No skeletons most screens | Low | Add skeletons for polish |
| **Error states** | 🟡 | 🟡 | Partial | Chat/docs/maintenance have retry | Same | Home/tickets weak offline UI | Medium | Add offline banners |
| **Search** | ✅ | ✅ | Identical | Documents client-side search | Same | None | — | — |
| **Filters** | ✅ | ✅ | Identical | Documents, maintenance, tickets | Same | None | — | — |
| **Pull to refresh** | ✅ | ✅ | Identical | Home, documents, maintenance | Same | None | — | — |
| **Offline mode** | ⚪ | ⚪ | Missing | No connectivity layer | Same | Firestore default cache only | High | Add connectivity + UI |
| **Caching** | 🟡 | 🟡 | Partial | `cached_network_image` in 4 files; GetStorage for auth | Same | No API response cache | Medium | Expand image cache usage |

---

## 2. Native Platform Audit

### Android

| Item | Status | Evidence |
|------|--------|----------|
| **Permissions** | Partial | `INTERNET`, location, `POST_NOTIFICATIONS`, `READ_MEDIA_IMAGES`, legacy storage (≤32) in `AndroidManifest.xml` |
| **Manifest** | OK structure | `MainActivity` singleTop, FileProvider, FCM default channel `casazero_alerts` |
| **Gradle** | OK | AGP 8.9.1, Kotlin 2.1.0, Firebase BoM 34.13.0, desugaring enabled |
| **Signing** | 🔴 FAIL | Release uses debug keystore (`build.gradle.kts` L37–39) |
| **Package name** | 🔴 FAIL | `com.example.casazero` placeholder |
| **Notification channels** | ✅ | Manifest meta-data + Dart channel creation aligned |
| **Deep links** | ⚪ | Launcher intent only |
| **Storage APIs** | ✅ | Scoped storage + FileProvider + MediaStore index channel |
| **Media APIs** | Partial | `READ_MEDIA_IMAGES` only; no video/audio read |
| **Camera** | Partial | Not in checked-in manifest; `image_picker` may merge |
| **FileProvider** | ✅ | `${applicationId}.fileprovider` + `file_paths.xml` |
| **Intent filters** | Launcher + `tel:` query | No App Links |
| **Foreground services** | ⚪ | None declared |
| **Background services** | FCM Dart handler only | No native `FirebaseMessagingService` override |
| **App Links** | ⚪ | Not configured |
| **Release config** | 🔴 | Debug signing, no minify/shrink |
| **ProGuard** | ⚪ | Not configured |
| **Crashlytics** | ⚪ | Only `firebase-analytics` in Gradle |
| **Play Integrity** | ⚪ | Not implemented |
| **Adaptive icons** | 🔴 | No `mipmap-*` in repo; manifest references `@mipmap/ic_launcher` |
| **Method channel** | ✅ Full | `com.example.casazero/file_opener` — 3 methods (`MainActivity.kt`) |

### iOS

| Item | Status | Evidence |
|------|--------|----------|
| **Info.plist** | 🔴 | Stray `</key>` L13; missing `NSCameraUsageDescription` |
| **Capabilities** | Partial | `remote-notification` background mode only |
| **Entitlements** | 🔴 | No `Runner.entitlements`; no `aps-environment` |
| **APNs** | Partial | `AppDelegate` registers + forwards token; needs entitlement |
| **Bundle identifier** | ✅ | `com.attoexa.casazero` in `project.pbxproj` |
| **Privacy keys** | Partial | Photo library + location; camera missing |
| **Universal links** | ⚪ | Not configured |
| **AppDelegate** | Partial | Firebase, FCM, partial file channel |
| **Background modes** | `remote-notification` | No location/fetch/processing |
| **Method channels** | 🟡 | `showOpenCancelConfirmation` only |
| **File preview** | 🟡 | OpenFilex fallback |
| **Camera** | 🔴 | No usage description |
| **Photo library** | ✅ | `NSPhotoLibraryUsageDescription` present |
| **Location** | ✅ when-in-use | Over-declared "always" key without background mode |
| **Notifications** | Partial | Native + Dart; entitlements missing |
| **Privacy Manifest** | 🔴 | No `PrivacyInfo.xcprivacy` |
| **Store config** | Partial | Team `2CKF37TSD9`, automatic signing, iOS 15+ |
| **App icons** | 🔴 | `AppIcon.appiconset/Contents.json` without PNG files in repo |
| **Launch screen** | Partial | Storyboard exists; launch image PNGs missing |

### Native comparison matrix

| Capability | Android | iOS | Parity |
|------------|---------|-----|--------|
| Firebase init | Gradle plugin + `google-services.json` | `AppDelegate` + plist | ✅ |
| FCM default channel | Manifest + Dart | Darwin notification settings | 🟡 |
| File open chooser | Native Intent chooser | OpenFilex fallback | 🔴 |
| MediaStore / Files indexing | `indexFileInMediaStore` | N/A (sandbox) | 🟡 Expected |
| Camera permission string | Plugin-dependent | Missing | 🔴 |
| Push entitlement | N/A | Missing | 🔴 |
| Package ID | `com.example.casazero` | `com.attoexa.casazero` | 🔴 |

---

## 3. Lifecycle Audit

| Event | Android | iOS | Identical? | Notes |
|-------|---------|-----|------------|-------|
| **Cold start** | Splash 3.5s → auth check → HOME/AUTH | Same | ✅ | `main.dart` → `splash_controller.dart` |
| **Warm start** | Resume observers fire | Same | ✅ | FCM, AppStatus, Presence, refresh wrapper |
| **Hot restart** | Dev-only | Dev-only | ✅ | N/A for production |
| **Resume** | Refresh notifications, documents, presence online | Same | ✅ | `app_lifecycle_refresh_wrapper.dart` |
| **Background** | App status `background`; presence offline | Same | ✅ | `app_status_service.dart`, `presence_service.dart` |
| **Foreground** | App status `foreground` | Same | ✅ | |
| **Killed app** | No route restoration; splash again | Same | ✅ | No `RestorationScope` |
| **Low memory** | No custom handling | Same | ✅ | Relies on OS |
| **Screen rotation** | Portrait locked at runtime | Plist allows landscape; runtime lock | 🟡 | iOS plist out of sync |
| **Device lock** | Standard Flutter | Same | ✅ | |
| **Phone calls** | No special handling | Same | ✅ | |
| **Internet loss** | Generic "Network error" | Same | ✅ | No connectivity pre-check |
| **Internet restore** | Manual pull-to-refresh / retry buttons | Same | ✅ | No auto-retry queue |
| **Session expiry** | Clear all → AUTH + popup | Same | ✅ | `session_expiry_service.dart` |
| **Push received (foreground)** | Local notification + data refresh | Same + iOS presentation options | 🟡 | Platform FCM branches |
| **Push tapped** | Stub navigation (log only) | Same | ✅ Identical bug | `notification_manager.dart` |
| **Deep link open** | N/A | N/A | ✅ | Not implemented |
| **Document download** | Permission flow + native open | Permission + OpenFilex | 🟡 | Native open differs |
| **Chat active** | Firestore streams active | Same | ✅ | Controller may leak if not deleted |
| **AI conversation** | In-memory messages | Same | ✅ | |

---

## 4. Permission Flow Audit

| Permission | Request mechanism | Denied | Permanently denied | Settings recovery | Fallback | Android vs iOS UX |
|------------|-------------------|--------|--------------------|-------------------|----------|-------------------|
| **Location** | `Geolocator.requestPermission()` at login | Returns `0,0` | Returns `0,0` | No settings deep link | Silent fallback | ✅ Identical |
| **Notifications** | FCM `requestPermission` + Android `Permission.notification` | Continues without push | Resume may re-prompt | User can enable in Settings; FCM rechecks on resume | App works without push | 🟡 Different APIs |
| **Camera** | `image_picker` implicit | Ticket photo fails | Ticket photo fails | No in-app settings link | Error from picker | 🔴 iOS broken at OS level |
| **Gallery** | `image_picker` / `file_picker` | Upload cancelled | Upload cancelled | None | User message | ✅ Identical |
| **Storage (downloads)** | `Permission.storage` / `Permission.photos` | Error message returned | Error message | `openAppSettings` not used | Download blocked message | ✅ Identical Dart branches |
| **Photos (Android 13+)** | `Permission.photos` in download flow | Same as storage | Same | None | Error returned | Android-only branch |
| **Microphone** | Not used | N/A | N/A | N/A | N/A | ✅ N/A |

**Gaps:** No unified permission education UI; no "open settings" pattern for permanently denied camera/storage; location failure is silent (`0,0` sent to backend).

---

## 5. Navigation Audit

| Topic | Android | iOS | Parity | Issue |
|-------|---------|-----|--------|-------|
| **Navigation stack** | GetX named routes + in-scaffold `AppScreen` history | Same | ✅ | Dual-stack complexity |
| **Back button** | `PopScope` intercepts; keyboard dismiss first | In-app back only | 🟡 | Expected platform difference |
| **Swipe back** | Disabled on main shell (`canPop: false`) | iOS edge swipe on pushed GetX routes | 🟡 | |
| **Bottom navigation** | Tab switch adds history | Same | ✅ | Back traverses tab history |
| **Nested navigation** | `MainScaffold` + pushed security routes | Same | ✅ | |
| **Modal routes** | Bottom sheets + `Get.dialog` | Same | ✅ | |
| **Route restoration** | None | None | ✅ | Always splash → home |
| **Deep links** | None | None | ✅ | |
| **Push → screen** | Stubbed | Stubbed | ✅ | Both broken |
| **Logout → AUTH** | `replaceStackWithAuth()` | Same | ✅ | |
| **Login → HOME/OTP/FIRST_LOGIN** | Branching in `auth_controller` | Same | ✅ | |
| **Session expiry → AUTH** | `offAllNamed(AUTH)` | Same | ✅ | |

**Navigation risks:** Bottom nav pollutes back stack; stale comments in `notifications_modal.dart` claim chat/tickets unimplemented while screens exist; local notification tap handler not registered (`local_notification_service.dart`).

---

## 6. UI & UX Consistency Audit

| Topic | Status | Android vs iOS | Finding |
|-------|--------|----------------|---------|
| **SafeArea** | Fragmented | Identical code | `PlatformSafeArea` defined but unused; manual padding in app bar + floating nav |
| **Status bar** | Global light icons | Android nav bar color set; iOS via system | `ThemeMode.light` hardcoded; no per-screen overlay |
| **Navigation bar** | Custom floating pill | Platform-tuned dimensions | Intentional difference in `floating_bottom_nav_bar.dart` |
| **Dynamic Island / notch** | Via `MediaQuery.padding` | Same | No custom Island logic |
| **Keyboard** | `resizeToAvoidBottomInset: false` + manual padding | Same | Well-handled in chat/dialogs |
| **Bottom insets** | iOS 0.38× scaling for nav | Android full inset | Intentional |
| **Dialogs** | `ResponsiveAlertDialog` keyboard-aware | Same | ✅ |
| **Snackbars** | Rare (tickets only) | Same | Inconsistent vs `MessagePopupController` |
| **Loading** | Spinners dominant | Same | Skeleton only on construction progress |
| **Spacing** | ScreenUtil `.h/.w` + some raw px | Same | 2FA screens use many raw `const` sizes |
| **Tablet layout** | 600px / 840px / 448.w mixed | Same | Home/Hub not using `TabletCenteredLayout` |
| **Landscape** | Locked portrait | Plist mismatch | Poor layout if rotation allowed |
| **Accessibility font scaling** | Clamped 0.85–1.3 | Same | `main.dart` text scaler clamp |
| **Dark mode** | Disabled | Same | `ThemeMode.light` forced |
| **RTL** | Not supported | Same | en/it only |
| **Animations** | `flutter_animate` staggered lists | Same | Re-runs on `Obx` updates |
| **Hero animations** | None | Same | No `Hero` widgets |
| **Platform UI** | Material only | Material only | Single `CupertinoIcons.back` usage |

---

## 7. Responsive Design Audit

| Target | Support | Evidence |
|--------|---------|----------|
| **320–390dp phones** | Good | ScreenUtil baseline 390×844; text clamp prevents extreme scale |
| **412–480dp phones** | Good | `splitScreenMode: true` |
| **Tablets** | Partial | `TabletCenteredLayout` on ~15 screens; Home/Hub full-bleed |
| **iPad** | Partial | iPad orientations in plist; portrait lock at runtime |
| **Landscape** | Poor | Locked; no landscape layouts |
| **Foldables** | Untested | No fold-aware code |
| **Display zoom / large fonts** | Partial | 0.85–1.3 clamp may clip some text |
| **Split screen** | Partial | `splitScreenMode` enabled |

**Issues found:** Mixed max-widths (448 / 600 / 840); raw pixel values in 2FA/preferences; nested `SingleChildScrollView` in construction cards; tickets use non-virtualized `Column` for all cards.

---

## 8. Push Notification Audit

| Scenario | Android | iOS | Parity |
|----------|---------|-----|--------|
| **Foreground** | Local notification + `NotificationManager` refresh | Same + `setForegroundNotificationPresentationOptions` | 🟡 |
| **Background** | Dart `@pragma('vm:entry-point')` handler | Same handler | ✅ |
| **Killed app** | `getInitialMessage` → stub nav | Same | ✅ |
| **Notification tap** | No navigation | No navigation | ✅ Broken both |
| **Grouping** | Not configured | Not configured | ✅ |
| **Badge count** | Unread API count in app bar | Same | ✅ In-app only |
| **Channels** | `casazero_alerts` | N/A | Android-only |
| **Categories** | None | None | ✅ |
| **Deep linking** | None | None | ✅ |
| **FCM token** | On login payload | Same | ✅ |
| **Token refresh** | Local cache only; not re-sent to API | Same + 1.5s iOS retry | 🟡 |
| **Logout cleanup** | `deleteToken()` on logout/expiry | Same | ✅ |
| **Multiple devices** | Backend-managed (assumed) | Same | Requires backend test |
| **Local notification tap** | No `onDidReceiveNotificationResponse` | Same | ✅ Gap both |

---

## 9. File Management Audit

| Operation | Android | iOS | Parity |
|-----------|---------|-----|--------|
| **Download** | Dio → app dir; storage permission branches | Same Dart | ✅ |
| **Upload** | Multipart/base64 to API | Same | ✅ |
| **Preview** | Open with chooser (native) | OpenFilex | 🟡 |
| **Open** | `openWithChooser` MethodChannel | OpenFilex fallback | 🔴 |
| **Share** | `share_plus` | Same | ✅ |
| **Delete** | API delete document | Same | ✅ |
| **ZIP extraction** | `archive` + password dialog | Same | ✅ |
| **Media Store index** | `indexFileInMediaStore` | N/A | Expected |
| **Document picker** | `file_picker` | Same | ✅ |
| **File chooser** | Native Intent chooser | System open via OpenFilex | 🔴 |
| **Native preview** | Third-party apps | Quick Look via OpenFilex | 🟡 |

---

## 10. Offline Audit

| Topic | Status | Evidence |
|-------|--------|----------|
| **No internet detection** | ⚪ Missing | No `connectivity_plus` |
| **Slow internet** | Timeout 30s | `app_constants.dart` |
| **Timeout UX** | Generic messages | `api_service.dart` `_handleError` |
| **Reconnect** | Manual refresh / retry buttons | No auto-retry queue |
| **API caching** | ⚪ | GetStorage auth only |
| **Firestore cache** | Default SDK | No explicit `persistenceEnabled` config |
| **Offline UI** | Partial | Chat/docs/maintenance retry; home/tickets weak |
| **Skeleton loaders** | Minimal | Construction + filter shimmer only |
| **Error messages** | Localized keys | ✅ |
| **Background retry** | Firestore stream reconnect only | `private_chat_service.dart` |

**Production readiness:** Not offline-ready. Acceptable for online-first if communicated to users.

---

## 11. Performance Audit

| Topic | Finding | Severity |
|-------|---------|----------|
| **Widget rebuilds** | Whole-screen `Obx` on `main_scaffold`, `home_screen`, `tickets_screen` | Medium |
| **Const usage** | Screen constructors const; inner trees mostly non-const | Low |
| **Memory leaks** | `ChatController` not `Get.delete` on back; `PresenceService.dispose` never called | High |
| **Controller disposal** | 10/22 controllers lack `onClose` (mostly low risk) | Low |
| **Stream cleanup** | Chat auth subs OK if `onClose` runs; `MessageProvider` permanent | Medium |
| **Animation performance** | `flutter_animate` stagger on dynamic lists | Low |
| **Image cache** | `cached_network_image` in 4 files; `NetworkImage` in private chat bubble | Medium |
| **Network cache** | None | Medium |
| **Pagination** | None for documents, tickets, chat, notifications | High |
| **Firestore listeners** | Unbounded message snapshots (no `.limit()`) | High |
| **Duplicate API calls** | Double unread count on resume; chat profile refresh each open | Medium |
| **Nested scroll** | Construction section nested `SingleChildScrollView` | Low |
| **Startup time** | Deferred Firebase init (good); 3.5s splash delay | Low |
| **Lazy loading** | `Get.lazyPut` for controllers | OK |

---

## 12. Accessibility Audit

| Topic | Android (TalkBack) | iOS (VoiceOver) | Parity |
|-------|-------------------|-----------------|--------|
| **Semantics** | Partial | Partial | ✅ |
| **Touch targets** | `accessibility.dart` min 44dp helpers | Same | ✅ |
| **Focus order** | Not audited for full app | Same | Unknown |
| **Large fonts** | Clamped 0.85–1.3 | Same | May clip |
| **Button labels** | Some `.tr` semantic labels on notifications | Same | Partial |
| **Images** | Logo `semanticsLabel` | Same | Partial |
| **Color contrast** | Not measured | Same | Requires design review |
| **Dynamic Type** | Flutter text scaler clamp | Same | Limited vs native Dynamic Type |
| **Screen reader on chat** | Phase semantics on construction | Same | Partial coverage |

**Gap:** No app-wide accessibility audit; `PlatformSafeArea` helpers unused.

---

## 13. Security Audit

| Topic | Status | Severity | Evidence |
|-------|--------|----------|----------|
| **Token storage** | Plaintext GetStorage | Critical | `storage_service.dart` |
| **Refresh token** | Never saved at login | Critical | `auth_repository.dart` |
| **Secure storage** | Not used | Critical | No `flutter_secure_storage` |
| **SSL pinning** | Not implemented | High | Default Dio TLS |
| **Certificate validation** | Default | — | |
| **Debug logging** | Full tokens in release | Critical | `api_service.dart` L45; `login_api_debug.dart` |
| **Sensitive logs** | TOTP secret printed | Critical | `first_login_controller.dart` |
| **Clipboard** | TOTP copied, no auto-clear | Medium | 2FA screens |
| **Screenshots** | Not blocked | Low | No `FLAG_SECURE` |
| **Root / jailbreak** | Not detected | High | No library |
| **Code obfuscation** | Not configured | High | No R8 / Dart obfuscate |
| **Release signing** | Android debug | Critical | `build.gradle.kts` |
| **Firebase rules** | Not in repo | — | Requires Firebase console review |
| **API exposure** | Single production URL hardcoded | Low | `api_constants.dart` |
| **Hardcoded credentials** | Active in login | Critical | `auth_controller.dart` L45–46 |
| **Firebase API keys** | In source (expected) | Low | `firebase_options.dart` |

---

## 14. Store Readiness Audit

### Android (Play Store)

| Item | Ready? |
|------|--------|
| Release signing | 🔴 Debug keys |
| AAB | 🔴 Blocked by signing |
| Version 1.0.0+1 | ✅ |
| Privacy policy link in app | Not verified |
| Permissions justification | Partial |
| Adaptive icons | 🔴 Missing mipmaps in repo |
| Splash | Partial (color only) |
| Crashlytics | 🔴 Not integrated |
| Play Integrity | 🔴 Not integrated |
| ProGuard | 🔴 Not configured |
| Store assets | Not in repo |

### iOS (App Store)

| Item | Ready? |
|------|--------|
| Provisioning / team | ✅ Team configured |
| Bundle ID | ✅ `com.attoexa.casazero` |
| Archive | Partial (icons missing) |
| Entitlements | 🔴 Push missing |
| Privacy Manifest | 🔴 Missing |
| Privacy labels | Requires manifest + review |
| Capabilities | Partial |
| App icons | 🔴 PNGs missing from repo |
| Launch screen | Partial |
| `NSCameraUsageDescription` | 🔴 Missing |
| Info.plist validity | 🔴 Malformed |

### Assets (`pubspec.yaml`)

| Asset | Status |
|-------|--------|
| `assets/images/` (SVGs) | ✅ 22 files |
| `assets/images/Hub_screen_logo_image.png` | 🔴 Referenced, not in repo |
| `assets/images/thumb_cubo.png` (launcher) | 🔴 Referenced, not in repo |
| `assets/fonts/Inter-*.ttf` | 🔴 Referenced, not in repo |
| `flutter_launcher_icons` | Config only; icons not generated in trees |

---

## 15. Production Checklist

| Feature | Android | iOS | Status | Severity |
|---------|---------|-----|--------|----------|
| Login / auth | ✅ | ✅ | Ready (Dart) | Critical if dev creds ship |
| Token refresh | 🔴 | 🔴 | Broken | Critical |
| 2FA | ✅ | ✅ | Ready | — |
| Documents | ✅ | ✅ | Ready | — |
| Downloads | ✅ | 🟡 | Partial | Medium |
| Tickets + camera | 🟡 | 🔴 | iOS camera broken | Critical |
| Chat | ✅ | ✅ | Ready | — |
| Push receive | 🟡 | 🟡 | Partial | High |
| Push tap navigate | 🔴 | 🔴 | Broken | High |
| Profile | ✅ | ✅ | Ready | — |
| Maintenance | ✅ | ✅ | Ready | — |
| AI | ✅ | ✅ | Ready | — |
| Construction timeline | ✅ | ✅ | Ready | — |
| Offline | ⚪ | ⚪ | Missing | High |
| Deep links | ⚪ | ⚪ | Missing | Medium |
| Smart Home | ⚪ | ⚪ | Mock | Low |
| Release signing | 🔴 | 🟡 | Android fail | Critical |
| Store assets | 🔴 | 🔴 | Missing fonts/icons | Critical |
| Security hygiene | 🔴 | 🔴 | Fail | Critical |

---

## 16. Risk Assessment

### Critical

| ID | Description | Platform | Impact | User impact | Technical cause | Production risk | Recommended fix | Effort |
|----|-------------|----------|--------|-------------|-----------------|-----------------|-----------------|--------|
| C1 | Hardcoded login credentials | Both | Account compromise | Anyone with APK/IPA can extract creds | Dev values in `auth_controller.dart` | Store rejection / breach | Remove pre-fill | S |
| C2 | Plaintext token storage | Both | Session hijack | Account takeover on compromised device | GetStorage unencrypted | Data breach liability | `flutter_secure_storage` | M |
| C3 | Token logging in release | Both | Token leak via logcat/console | Session hijack | Unconditional `print()` | Compliance failure | Guard with `kDebugMode` | M |
| C4 | Refresh token never saved | Both | Forced re-login on expiry | Sudden logout | Login omits `saveRefreshToken` | Poor UX / support load | Parse login response | S |
| C5 | Android debug release signing | Android | Cannot ship Play Store | N/A | `build.gradle.kts` | No production release | Production keystore | S |
| C6 | Android placeholder package ID | Android | Wrong app identity | N/A | `com.example.casazero` | Firebase/store mismatch | Rename + update JSON | M |
| C7 | iOS malformed Info.plist | iOS | Build/parse failure | App may not install | Stray `</key>` L13 | Store rejection | Fix XML | S |
| C8 | iOS missing camera permission | iOS | Ticket camera broken | Cannot attach photo via camera | No `NSCameraUsageDescription` | Feature broken | Add plist key | S |
| C9 | iOS missing push entitlements | iOS | Push unreliable | Miss notifications | No `aps-environment` | Core feature failure | Xcode capability | S |
| C10 | Missing fonts & launcher assets | Both | Build/runtime failure | Broken typography/icons | Files not in repo | Cannot ship | Add assets + run icon gen | M |

### High

| ID | Description | Platform | Impact | Recommended fix | Effort |
|----|-------------|----------|--------|-----------------|--------|
| H1 | Push tap navigation stubbed | Both | Notifications don't deep-link | Implement `handleNotificationNavigation` | M |
| H2 | FCM token not re-registered after restore | Both | Stale/missing push targeting | Backend token update endpoint | M |
| H3 | iOS file opener channel incomplete | iOS | Inconsistent file open UX | Port Android channel methods | M |
| H4 | No SSL pinning | Both | MITM risk | Certificate pinning policy | L |
| H5 | No Crashlytics | Both | Blind to crashes | Add Firebase Crashlytics | S |
| H6 | No iOS Privacy Manifest | iOS | App Store rejection | Add `PrivacyInfo.xcprivacy` | M |
| H7 | ChatController lifecycle leak | Both | Memory/battery drain | `Get.delete` on screen exit | S |
| H8 | No list pagination | Both | Performance degrades at scale | Cursor/limit APIs | L |
| H9 | No connectivity layer | Both | Poor offline UX | `connectivity_plus` + banners | M |

### Medium

| ID | Description | Platform | Impact | Effort |
|----|-------------|----------|--------|--------|
| M1 | Bottom nav pollutes back stack | Both | Confusing back behavior | S |
| M2 | Home dashboard sections commented out | Both | Reduced functionality | S |
| M3 | iOS/Android bundle ID mismatch | Both | Ops confusion | M |
| M4 | TOTP copied to clipboard without clear | Both | Secret exposure | S |
| M5 | Duplicate API on app resume | Both | Extra load | S |
| M6 | Tickets use SnackBar vs app popups | Both | UX inconsistency | S |
| M7 | No route restoration after kill | Both | Lost navigation state | M |
| M8 | `NetworkImage` in private chat bubble | Both | No disk cache | S |

### Low

| ID | Description | Effort |
|----|-------------|--------|
| L1 | Dark mode defined but disabled | S |
| L2 | RTL not supported | L |
| L3 | No Hero transitions | — |
| L4 | Folder typo `viwes` | S |
| L5 | Unused `firebase_storage` dependency | S |
| L6 | Demo panel not wired | — |

---

## 17. Final Scores

| Category | Score / 100 | Rationale |
|----------|-------------|-----------|
| **Flutter Architecture** | 78 | Clean feature-first layout, GetX DI, repositories, deferred Firebase init; dual navigation complexity |
| **Android Native** | 70 | Solid FileProvider, full MethodChannel, notification channel; signing/package/icons fail |
| **iOS Native** | 58 | AppDelegate FCM wiring good; plist, entitlements, camera, icons, privacy manifest gaps |
| **Cross-Platform Consistency** | 72 | Dart identical; native file open, camera, push, bundle IDs diverge |
| **Performance** | 68 | No pagination; broad Obx; chat leak risk; otherwise acceptable for MVP scale |
| **Security** | 42 | Plaintext tokens, hardcoded creds, logging, no pinning/obfuscation |
| **Accessibility** | 55 | Partial Semantics and touch targets; not comprehensive |
| **Responsive UI** | 74 | ScreenUtil + tablet layouts + floating nav; inconsistent tablet on home/hub |
| **Offline Readiness** | 35 | Firestore implicit cache only; no connectivity UX |
| **Notification Reliability** | 58 | Receive path OK; tap nav broken; iOS entitlements; token re-sync gap |
| **Store Readiness** | 48 | Missing assets, Android signing, iOS privacy/entitlements/icons |
| **Overall Production Readiness** | **62** | Weighted: strong feature coverage in Dart undermined by security and native release blockers |

---

## Recommended Action Plan (Analysis Only — No Fixes Applied)

### Phase 1 — Ship blockers (1–2 weeks)
1. Security: remove hardcoded credentials, stop token logging, migrate tokens to secure storage  
2. Auth: persist refresh token from login  
3. iOS: fix plist, camera key, push entitlements, Privacy Manifest  
4. Android: production signing, package ID, launcher icons  
5. Assets: commit fonts, launcher source image, iOS icon PNGs  

### Phase 2 — Parity & UX (2–3 weeks)
1. iOS file-opener MethodChannel parity  
2. Push notification tap → screen navigation  
3. FCM token backend re-registration on session restore  
4. Connectivity detection + offline UI  
5. Chat controller lifecycle fix  

### Phase 3 — Scale & polish (ongoing)
1. Pagination for lists and chat history  
2. Crashlytics + optional Play Integrity  
3. SSL pinning policy  
4. Accessibility pass  
5. Uncomment or remove home dashboard sections  

---

*This report is analysis-only. No source code was modified. Backend API behavior requires live environment testing to confirm.*
