# Platform Parity Fix Report

**Date:** July 10, 2026  
**Scope:** Camera, Gallery, Downloads, Uploads, Push, Notifications, Permissions, Lifecycle, Deep links, Navigation, Back button, Swipe back, SafeArea, Keyboard, File opening  
**Constraint:** Fix platform differences only — no business logic, workflow, API, or UI design changes.

---

## Executive Summary

A full cross-platform audit was performed across `lib/`, `android/`, and `ios/`. Seven localized fixes were applied to close Android/iOS parity gaps. No feature behavior, navigation flow, API contracts, or state management architecture was changed.

---

## Feature Analysis

### Camera

| Platform | Status Before | Status After |
|----------|---------------|--------------|
| Android | Camera used in ticket creation (`create_ticket_dialog.dart`) but `CAMERA` permission not declared in manifest | `android.permission.CAMERA` added to `AndroidManifest.xml` |
| iOS | Camera used via `ImagePicker.pickImage(source: ImageSource.camera)` but `NSCameraUsageDescription` missing — would crash/fail on device | `NSCameraUsageDescription` added to `Info.plist` |

**Unchanged:** Profile photo remains gallery-only. Ticket multi-photo UI and single-photo API upload unchanged (business logic).

---

### Gallery / Image Picker

| Area | Finding |
|------|---------|
| Profile | `ImageSource.gallery` with resize/quality — identical Dart code on both platforms |
| Tickets | Gallery + camera bottom sheet — identical Dart code on both platforms |
| Documents / Maintenance | `file_picker` — identical Dart code on both platforms |
| iOS plist | `NSPhotoLibraryUsageDescription` already present |
| Android manifest | `READ_MEDIA_IMAGES` + legacy storage permissions already present |

**No changes required** — picker logic is platform-agnostic; permissions now aligned for camera path.

---

### Downloads

| Platform | Behavior | Change |
|----------|----------|--------|
| Android | Saves to `/storage/emulated/0/Download`, indexes via MediaStore channel | **Fixed** MediaStore indexing: replaced empty `ContentValues.insert()` with `MediaScannerConnection.scanFile()` so existing files are indexed without creating phantom entries |
| iOS | Saves to app Documents directory (Files app visible via `UIFileSharingEnabled`) | No change — OS-appropriate behavior preserved |

**Unchanged:** Download directory strategy, permission fallback logic, and user-facing save locations intentionally preserved.

---

### Uploads

All upload paths (`document_repository.dart`, `profile_repository.dart`, `ticket_repository.dart`) use platform-agnostic Dio multipart/base64. **No platform differences found in upload layer.**

**Not changed:** Maintenance task file picker UI that does not wire to API (feature gap, not platform gap).

---

### Push Notifications

| Area | Android | iOS | Parity |
|------|---------|-----|--------|
| Permission | `Permission.notification` + FCM | FCM `requestPermission` + APNs via AppDelegate | Already aligned |
| Foreground | Local notifications via `LocalNotificationService` | FCM foreground presentation options set | Already aligned |
| Background | `POST_NOTIFICATIONS` in manifest | `UIBackgroundModes: remote-notification` | Already aligned |
| Token | Standard FCM | APNs token forwarded in AppDelegate + retry delay | Already aligned |

**No changes required.**

---

### Permissions

| Permission | Android | iOS | Fix Applied |
|------------|---------|-----|-------------|
| Camera | Missing | Missing usage string | ✅ Both fixed |
| Photo library | Present | Present | — |
| Location | Present | Present | — |
| Notifications | Present | Present (APNs) | — |
| Storage / media | Present | N/A (app sandbox) | — |

**Also fixed:** Malformed `Info.plist` — stray `</key>` tag on line 13 removed (could cause plist parse issues).

---

### Lifecycle

Observers in `AppLifecycleRefreshWrapper`, `FcmService`, `AppStatusService`, and `PresenceService` use identical Dart `WidgetsBindingObserver` code on both platforms. **No platform branching — no changes required.**

---

### Deep Links

Not implemented on either platform (no `app_links`/`uni_links`, no intent filters, no `CFBundleURLTypes`). **Intentionally unchanged** — adding deep links would be new functionality, not parity.

Notification tap navigation (`NotificationManager.handleNotificationNavigation`) remains a stub on both platforms. **Intentionally unchanged.**

---

### Navigation / Back Button / Swipe Back

| Area | Finding | Fix |
|------|---------|-----|
| Main app | `PopScope(canPop: false)` in `main_scaffold.dart` — handles Android back + iOS swipe via custom `HomeController` stack | Already aligned |
| 2FA screens | `PopScope` used in `two_fa_activation_screen.dart` | — |
| Document password 2FA | Used deprecated `WillPopScope` | ✅ Migrated to `PopScope(canPop: false)` with identical back-cancel behavior |

**Unchanged:** Custom in-app screen history, GetX routes, and `SystemNavigator.pop()` exit flow.

---

### SafeArea

Screens use Flutter `SafeArea` directly; `PlatformSafeArea` wrapper exists but is only referenced by `FloatingBottomNavBar` for inset math. **No platform-specific bugs found — no changes required** (using wrapper everywhere would be a UI refactor, out of scope).

---

### Keyboard

| Area | Pattern |
|------|---------|
| `MainScaffold` | `resizeToAvoidBottomInset: false` + manual `_KeyboardBottomPadding` |
| Chat / dialogs / sheets | `MediaQuery.viewInsets` bottom padding |
| Android manifest | `windowSoftInputMode="adjustResize"` |

Identical Dart handling on both platforms. **No changes required.**

---

### File Opening

| Path | Before | After |
|------|--------|-------|
| Documents download flow | `FileOpenerService.openWithChooser` → Android native chooser; iOS fell back to `OpenFilex` (auto-open risk) | iOS now implements `openWithChooser` via `UIDocumentInteractionController` with `UIActivityViewController` fallback |
| Notifications download flow | Direct `OpenFilex.open` | ✅ Now uses `FileOpenerService.openWithChooser` (matches documents) |
| ZIP download flow | Direct `OpenFilex.open` | ✅ Now uses `FileOpenerService.openWithChooser` (matches documents) |

Both platforms now expose the same MethodChannel API:
- `showOpenCancelConfirmation` — native alert on Android and iOS
- `openWithChooser` — forced app chooser on Android and iOS

---

## Files Modified

| File | Change |
|------|--------|
| `ios/Runner/Info.plist` | Added `NSCameraUsageDescription`; removed malformed `</key>` |
| `android/app/src/main/AndroidManifest.xml` | Added `CAMERA` permission |
| `ios/Runner/AppDelegate.swift` | Implemented `openWithChooser` MethodChannel handler |
| `android/.../MainActivity.kt` | Fixed MediaStore indexing via `MediaScannerConnection.scanFile()` |
| `lib/core/widgets/notifications_modal.dart` | Route file open through `FileOpenerService` |
| `lib/core/services/zip_download_service.dart` | Route file open through `FileOpenerService` |
| `lib/presentation/profile/views/document_password_2fa_verification_screen.dart` | `WillPopScope` → `PopScope` |

---

## Intentionally Not Changed

The following were identified but excluded per scope constraints:

1. **Maintenance file upload UI** — file selected but not sent to API (feature bug, both platforms)
2. **Ticket multi-photo vs single-photo API** — business logic
3. **Deep link / notification navigation** — not implemented on either platform
4. **Download directory paths** — Android public Downloads vs iOS Documents is OS-appropriate UX
5. **SafeArea wrapper adoption** — would change layout patterns across screens
6. **Package version updates** — not required
7. **FCM duplicate lifecycle observers** — architectural, not platform-specific
8. **Portrait lock vs Info.plist landscape orientations** — pre-existing; no user-reported platform mismatch

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` on changed Dart files | Pass (no errors; pre-existing info-level lints only) |
| API contracts | Unchanged |
| Navigation flow | Unchanged |
| User workflows | Unchanged |
| Business logic | Unchanged |
| Backward compatibility | Preserved |

### Recommended Manual QA

1. **iOS camera:** Create support ticket → Take Photo → verify permission prompt and capture
2. **Android camera:** Same flow on Android 13+
3. **File open (iOS):** Download document → Open → verify app chooser appears (not auto-open for images)
4. **File open (Android):** Same flow → verify chooser unchanged
5. **Notification document:** Tap document notification → download → verify chooser via `FileOpenerService`
6. **ZIP download:** Download encrypted ZIP → verify chooser on extracted file
7. **Back button:** Document password 2FA screen → system back / swipe → verify flow cancels same as before
8. **Downloads (Android):** Save file → verify visible in file manager / Downloads app

---

## Phase Status

**Phase complete.** All identified platform parity gaps within scope have been addressed with minimal, localized changes. No further optimization phases started.
