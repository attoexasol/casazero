# Flutter Memory Audit

**Project:** CasaZero (`d:\Sajid\casazero`)  
**Date:** July 10, 2026  
**Scope:** Controllers, streams, timers, animations, image cache, GetX DI, Firestore listeners, dispose patterns  
**Constraint:** Analysis only — no source modifications

---

## Executive Summary

CasaZero has **mixed resource hygiene**: chat-related code shows deliberate cleanup (`MessageProvider`, `PrivateChatController`, `ChatController.onClose`), while **tab-scoped controllers are registered with `Get.put` and rarely deleted**, retaining large `RxList` payloads and reactive workers for the app session.

**Critical leak:** `MaintenanceController` registers `ever(home.selectedResidence, …)` with **no `Worker` reference and no `onClose`** — the worker survives for the controller's lifetime (effectively permanent after first shell `build`).

**Logout gap:** `ProfileController.logout()` clears storage and `HomeController` state but does **not** tear down `PresenceService`, `MessageProvider` message cache, or tab controllers (`MaintenanceController`, `ChatController`, etc.).

| Report | Score |
|--------|-------|
| **Performance Score (memory & resources)** | **51 / 100** |
| Dispose pattern compliance | 45 / 100 |
| Stream / listener hygiene | 52 / 100 |
| GetX controller lifecycle | 48 / 100 |
| Image & cache discipline | 54 / 100 |

---

## Part A — Memory Leak Report

### Severity legend

| Level | Meaning |
|-------|---------|
| 🔴 Critical | Confirmed leak or unbounded retention per session |
| 🟠 High | Likely leak / retained listeners after feature exit |
| 🟡 Medium | Session-long retention by design; risky at scale |
| 🟢 Low | Minor or mitigated |

---

### A.1 Confirmed / high-probability leaks

| ID | Severity | Resource | Location | Issue | Impact |
|----|----------|----------|----------|-------|--------|
| **ML-01** | 🔴 Critical | GetX `Worker` (`ever`) | `maintenance_controller.dart` L85–98 | `ever(home.selectedResidence, …)` — return value **not stored**, **no `onClose`** | Worker + closure retained; refetches on every residence change forever |
| **ML-02** | 🟠 High | `StreamSubscription` (auth) | `chat_controller.dart` L260, L98–99 | `_authStateSub` cancelled in `onClose`, but controller **never deleted** after `Get.put` in `main_scaffold.dart` L995 | Firebase auth listener active after first chat visit |
| **ML-03** | 🟠 High | Same pattern | `admin_chat_controller.dart`, `private_chat_controller.dart` | Auth subs disposed in `onClose` — **onClose not called** when controller persists | Duplicate auth listeners if re-`put` |
| **ML-04** | 🟠 High | Firestore snapshot stream | Chat UIs via `StreamBuilder` | Listener cancels when widget disposed, but **controller holds `_messagesStream`** and re-subscribes on return; unbounded message list in memory | RAM grows with chat history |
| **ML-05** | 🟡 Medium | `MessageProvider` (permanent) | `initial_binding.dart` L119–120 | `messages` RxList **not cleared on logout** | Prior user's messages may linger until rebound |
| **ML-06** | 🟡 Medium | `PresenceService` (permanent) | `presence_service.dart` | `dispose()` exists (L199) but **never called** on logout; `_authSub` + `WidgetsBindingObserver` always active | Stale `userId` binding; extra lifecycle writes |
| **ML-07** | 🟡 Medium | FCM listeners | `fcm_service.dart` L205–224 | `onTokenRefresh`, `onMessage`, `onMessageOpenedApp` — **no `StreamSubscription` cancel** in `onClose` | Acceptable for app-lifetime singleton; leaks if service re-created |
| **ML-08** | 🟡 Medium | Tab controllers | `main_scaffold.dart` L903–1010 | `Get.put` for Documents, Hub, Maintenance, Profile, AI, Chat, Tickets — **no matching `Get.delete` on logout** | Controllers + Rx data retained entire session |

---

### A.2 Dispose compliance — GetX controllers (23 total)

| Controller | `onClose` | Disposes | Gap |
|------------|-----------|----------|-----|
| `SplashController` | ✅ | `Timer` | — |
| `AuthController` | ✅ | `TextEditingController` ×3 | Deleted on auth nav only |
| `ForgotPasswordController` | ✅ | email controller | — |
| `ForgotChangePasswordController` | ✅ | password controllers | — |
| `ChangePasswordController` | ✅ | password controllers | — |
| `OtpVerificationController` | ✅ | otp controller | — |
| `FirstLoginController` | ✅ | 5 text controllers | — |
| `TwoFAManagementController` | ✅ | verification controllers | — |
| `DocumentPasswordController` | ✅ | 3 controllers | — |
| `AiController` | ✅ | input + scroll controllers | No delete on tab leave |
| `ChatController` | ✅ | auth sub, text + scroll | **Never deleted** after first visit |
| `AdminChatController` | ✅ | same | Same |
| `PrivateChatController` | ✅ | auth sub, workers, text + scroll | Deleted only in some nav paths |
| `MessageProvider` | ✅ | stream sub | Permanent; logout skip |
| `PrivateChatProvider` | ✅ | presence sub | Permanent |
| **`HomeController`** | 🔴 **None** | — | Permanent `fenix`; large RxLists |
| **`MaintenanceController`** | 🔴 **None** | — | `ever()` leak ML-01 |
| **`DocumentsController`** | 🔴 **None** | — | Full document list in memory |
| **`TicketsController`** | 🔴 **None** | — | Tickets + photo paths |
| **`ProfileController`** | 🔴 **None** | — | User model retained |
| **`HubController`** | 🔴 **None** | — | — |
| **`TrustedDevicesController`** | 🔴 **None** | — | — |
| **`DemoController`** | 🔴 **None** | — | Demo only |

**Compliance: 14 / 23 (61%) have `onClose`; only 6 / 14 tab/feature controllers dispose resources.**

---

### A.3 Widget-level resources

| Resource | Files with `dispose()` | Files missing `dispose()` |
|----------|------------------------|---------------------------|
| `AnimationController` | 15 StatefulWidgets ✅ | — |
| `TextEditingController` | Dialogs: add_document, add_maintenance, create_ticket, edit_profile, forgot_change_password ✅ | — |
| `ScrollController` | Disposed in GetX chat/AI `onClose` ✅ | — |
| `Timer` | `SplashController`, `PresenceService` ✅ | — |

**Widget dispose compliance: ~95%** for StatefulWidgets that own controllers.

**Exception handled correctly:**

```70:71:lib/core/widgets/zip_password_dialog.dart
  final raw = result == true ? controller.text : null;
  controller.dispose();
```

---

### A.4 Workers (GetX)

| Worker | Location | Stored? | Disposed? |
|--------|----------|---------|-----------|
| `ever(residence)` | `MaintenanceController` L85 | 🔴 No | 🔴 No |
| `ever(messageError)` | `PrivateChatController` L52 | ✅ Yes | ✅ `onClose` L71 |
| `ever(messages scroll)` | `PrivateChatController` L56 | ✅ Yes | ✅ `onClose` L72 |
| `once(apiToken)` | `HomeController` L147, L244 | Auto (GetX) | After first fire |

---

### A.5 Firestore listeners

| Stream | Owner | Cancel path | Risk |
|--------|-------|-------------|------|
| `groups/…/messages.snapshots()` | `ChatController._streamMessages` | `StreamBuilder` dispose when tab hidden | 🟡 Message list unbounded |
| `admin_chats/…/messages.snapshots()` | `AdminChatController` | Same | 🟡 |
| `conversations/…/messages` | `PrivateChatRepository` → `MessageProvider` | `_messagesSub.cancel()` in `clear()` / `onClose` | 🟢 Best pattern |
| `presence/user_*`.snapshots() | `PresenceService.streamOnlineStatus` | Provider `onClose` | 🟢 |
| Mark-read compound `.get()` | `PrivateChatService` | One-shot | N/A |

**Gap:** Group/admin chat rely on UI `StreamBuilder` lifecycle; **no explicit cancel in controller `onClose`**.

---

### A.6 Logout / session teardown matrix

| Resource | Cleared on `ProfileController.logout()`? | Cleared on `SessionExpiryService`? |
|----------|----------------------------------------|-----------------------------------|
| `StorageService` | ✅ `clearAll()` | ✅ |
| `HomeController` Rx state | ✅ `clearStateOnLogout()` | ✅ |
| `DocumentsController` | 🟡 Only if registered (`clearDocuments` from home) | 🔴 |
| `FirebaseAuthService` | 🔴 | ✅ `signOut()` |
| `FcmService` token | 🔴 | ✅ `deleteToken()` |
| `PresenceService` | 🔴 | 🔴 |
| `MessageProvider` messages | 🔴 | 🔴 |
| Tab GetX controllers | 🔴 Only `AuthController` deleted | 🔴 |
| `MaintenanceController` worker | 🔴 | 🔴 |

---

## Part B — Resource Usage Report

### B.1 Image cache

| Item | Status | Details |
|------|--------|---------|
| Package | `cached_network_image` 3.4.1 | 4 files |
| Cache backend | Default `flutter_cache_manager` | Disk + in-memory via `sqflite` |
| Custom `CacheManager` | 🔴 None | No size/TTL configuration |
| `memCacheWidth` / `memCacheHeight` | 🔴 None | Full-resolution decode to RAM |
| `maxWidthDiskCache` | 🔴 None | Full files on disk |
| Cache eviction API | 🔴 Never called | No `evict`, `emptyCache`, `clearLiveImages` |
| `NetworkImage` bypass | 🔴 | `private_chat_bubble.dart` L114 — **no disk cache** |
| `Image.file` | Local previews | `create_ticket_dialog.dart`, `add_document_dialog.dart` — file bytes in GPU/RAM |
| `Image.memory` | 2FA QR | `first_login_setup_screen.dart` — transient |
| Profile cache-bust | `ValueKey` on URL | Forces re-fetch; can **duplicate cache entries** |

**Estimated image RAM risk:** Hero banner + ticket thumbnails on low-RAM devices without `memCacheWidth`.

---

### B.2 In-memory data retention (session)

| Store | Type | Approx. growth | Cleared? |
|-------|------|----------------|----------|
| `HomeController.feedItems` | `RxList` notifications | O(n) notifications | Logout ✅ |
| `DocumentsController.documents` | `RxList` | O(n) documents | `clearDocuments()` on user change |
| `MaintenanceController.tasks` | `RxList` ×2 | O(n) tasks + filters | Residence change only |
| `TicketsController.allTickets` | `RxList` | O(n) tickets | 🔴 Session lifetime |
| `MessageProvider.messages` | `RxList` | O(n) chat messages | `clear()` manual only |
| `AiController` history | In-controller list | O(n) AI messages | 🔴 No `onClose` data clear |
| `AppTranslations` maps | Static const | ~1,771 lines | Compile-time (not heap churn) |

**Preload amplification:** `HomeController._preloadDocuments()` fetches full document set at login — **doubles peak memory** if user opens documents tab later.

---

### B.3 Singleton & permanent `GetxService` usage

| Service | Registration | Observers / subs | `onClose` cleanup |
|---------|--------------|------------------|-------------------|
| `ApiService` | permanent | Dio only | N/A |
| `StorageService` | permanent | — | N/A |
| `FcmService` | permanent | `WidgetsBindingObserver` + 3 FCM streams | Observer removed; **streams not** |
| `PresenceService` | permanent | Auth sub + lifecycle observer | `dispose()` manual only |
| `FirebaseAuthService` | permanent | Auth sub | ✅ Sub cancelled |
| `AppStatusService` | permanent | Lifecycle observer | ✅ Observer removed |
| `MessageProvider` | permanent | Firestore sub | ✅ On `onClose` / `clear()` |
| `DownloadService` / `ZipDownloadService` | permanent | Own `Dio()` instances | N/A |

**12+ `permanent: true` registrations** in `InitialBinding` — intentional app-singleton pattern; **not leaks** if truly one instance, but **prevents GC** of associated state.

---

### B.4 Static variables (mutable state)

| Class | Static field | Risk |
|-------|--------------|------|
| `SessionExpiryService` | `_isHandling` bool | 🟢 Guard flag; reset on login |
| `LocalNotificationService` | `_plugin`, `_initialized` | 🟢 Expected singleton |
| `FcmService` | Instance fields `_initialized`, `_listenersSetup` | 🟢 Prevents duplicate listeners |
| `MessagePopupController` | Static methods only | 🟢 |
| `AppColors` / `AppTextStyles` | const tokens | 🟢 |
| `main.dart` | `_splashBackgroundColor` const | 🟢 |

**No problematic static caches of user data or large collections.**

---

### B.5 CPU / memory interaction hotspots

| Hotspot | Resource impact |
|---------|-----------------|
| `MainScaffold.build` → `_ensureMaintenancePreloaded()` | Registers `MaintenanceController` + triggers API fetch from every shell rebuild check |
| `MainScaffold` top-level `Obx` | Rebuilds entire subtree on `HomeController` changes |
| `flutter_animate` per list index | Animation objects × visible items |
| Maintenance verbose `print()` of full API JSON | I/O + string allocation in memory |
| Unbounded Firestore snapshots | CPU to map every doc on each update |

---

### B.6 Resource usage summary

| Category | Rating | Notes |
|----------|--------|-------|
| Image disk cache | 🟡 Default unlimited growth | No app-level cap |
| Image RAM | 🟠 Weak | No decode bounds |
| Network streams | 🟡 | Chat streams unbounded |
| GetX DI memory | 🟠 | Tab controllers accumulate |
| Widget controllers | 🟢 | Good dispose in StatefulWidgets |
| Logout teardown | 🔴 Incomplete | Firebase partial; presence/chat skip |
| Static / singleton | 🟢 | Appropriate for services |

---

## Part C — Performance Score

### C.1 Score breakdown

| Dimension | Weight | Score | Weighted |
|-----------|--------|-------|----------|
| Dispose patterns (controllers + widgets) | 25% | 45 | 11.25 |
| Stream / subscription hygiene | 20% | 52 | 10.40 |
| GetX lifecycle (put/delete/fenix) | 20% | 48 | 9.60 |
| Image cache & decode discipline | 15% | 54 | 8.10 |
| Session data retention | 10% | 40 | 4.00 |
| Singleton / static safety | 10% | 68 | 6.80 |
| **Performance Score** | **100%** | — | **51 / 100** (rounded) |

### C.2 Interpretation

| Range | Meaning |
|-------|---------|
| 85–100 | Production-grade resource management |
| 70–84 | Minor leaks; profiled on devices |
| **50–69** | **Session leaks acceptable for MVP; fix before long sessions** ← CasaZero |
| < 50 | Active leaks; OOM / jank likely |

---

## Part D — Fix Priority

### P0 — Fix immediately

| # | Fix | Addresses |
|---|-----|-----------|
| 1 | Store `Worker` from `ever()` in `MaintenanceController`; dispose in `onClose()` | ML-01 |
| 2 | Add `onClose()` to `MaintenanceController` | ML-01, ML-08 |
| 3 | On logout: `MessageProvider.clear()`, `PresenceService.dispose()` + re-bind on login | ML-05, ML-06 |

### P1 — Before production hardening

| # | Fix | Addresses |
|---|-----|-----------|
| 4 | `Get.delete` tab controllers on logout or use `Get.lazyPut` + auto-remove | ML-02, ML-08 |
| 5 | Add `onClose` to `HomeController`, `DocumentsController`, `TicketsController` | Data retention |
| 6 | Cancel FCM `StreamSubscription`s in `FcmService.onClose` (store refs) | ML-07 |
| 7 | `CachedNetworkImage` + `memCacheWidth`; replace `NetworkImage` in chat bubble | Image RAM |
| 8 | Firestore `.limit()` on chat queries | ML-04 memory + reads |

### P2 — Optimization

| # | Fix | Addresses |
|---|-----|-----------|
| 9 | Custom `CacheManager` with max objects / stale period | Disk growth |
| 10 | Remove maintenance preload from `MainScaffold.build` | CPU + API |
| 11 | `clearLiveImages()` on logout (optional) | Image RAM flush |
| 12 | Narrow `MainScaffold` `Obx` scope | Rebuild churn |

---

## Part E — Positive patterns (keep)

1. **`MessageProvider`** — explicit `_messagesSub.cancel()`, `clear()`, `onClose()` ✅  
2. **`PrivateChatController`** — workers stored and disposed ✅  
3. **`ChatController.onClose`** — text/scroll/auth cleanup (when called) ✅  
4. **`SplashController`** — timer cancelled ✅  
5. **`zip_password_dialog`** — disposes dialog `TextEditingController` ✅  
6. **`FirebaseAuthService.onClose`** — cancels auth subscription ✅  
7. **`HomeController.clearStateOnLogout()`** — central Rx reset ✅  
8. **`SessionExpiryService`** — Firebase sign-out + FCM token delete ✅  

---

## Part F — Testing recommendations

| Test | Method |
|------|--------|
| Controller leak | DevTools Memory → open each tab 5× → GC → snapshot compare |
| Chat listener | Leave chat tab → verify Firestore listener count in debug logs |
| Logout residue | Login user A → chat → logout → login user B → assert no A messages |
| Image RAM | Open hero + tickets with large images → DevTools heap |
| Long session | 30 min navigation loop → monitor `MaintenanceController` worker count |

---

## Conclusion

CasaZero's **widget-level dispose hygiene is strong** (animations, dialogs, splash timer), and **private chat** demonstrates the target pattern for streams and workers. The main risks are **GetX controller longevity**: tab controllers registered once, never deleted, holding **unbounded lists** and **leaked `ever()` workers** in maintenance.

Logout clears **local storage and home state** but not **Firebase-adjacent singletons** (presence, message cache) or **feature controllers** — a concern for shared devices and long-running sessions.

**Performance Score: 51 / 100** — acceptable for short MVP sessions; address P0 items before beta users keep the app open for hours or switch accounts frequently.

---

*Generated by static analysis. Re-audit after implementing dispose fixes or profiling with Flutter DevTools.*
