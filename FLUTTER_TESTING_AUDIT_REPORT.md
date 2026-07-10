# Flutter Testing Audit

**Project:** CasaZero (`d:\Sajid\casazero`)  
**Date:** July 10, 2026  
**Scope:** Static analysis of unit, widget, integration, repository, controller, Firebase, API, mock, golden, and critical-flow test coverage  
**Constraint:** Analysis only — no source modifications

---

## Executive Summary

CasaZero is a **feature-rich production Flutter app** (~197 `lib/` Dart files, ~49K LOC) with **effectively zero automated test coverage**. The sole test file is a **stale Flutter template** that fails at runtime because it expects a counter UI and does not bootstrap GetX dependencies.

| Dimension | Score |
|-----------|-------|
| Test Infrastructure | 4 |
| Unit Test Coverage | 0 |
| Widget Test Coverage | 1 |
| Integration Test Coverage | 0 |
| Repository Test Coverage | 0 |
| Controller Test Coverage | 0 |
| Firebase Test Coverage | 0 |
| API / Network Test Coverage | 0 |
| Mock & Testability | 3 |
| Golden / Visual Regression | 0 |
| Critical Flow Coverage | 0 |
| CI Test Gating | 0 |
| **Overall Testing Score** | **4 / 100** |
| **Production Confidence (Testing)** | **18 / 100** |

**Verdict:** The app ships on manual QA and production monitoring. Regressions in auth, 2FA, documents, chat, session expiry, and push notification routing are **undetectable by automation** until they surface in production or manual testing.

---

## 1. Test Infrastructure

### 1.1 Current State

| Asset | Status | Path / Notes |
|-------|--------|--------------|
| `flutter_test` | ✅ In `dev_dependencies` | `pubspec.yaml` |
| `mockito` / `mocktail` | ❌ Not installed | — |
| `integration_test` | ❌ Not installed | — |
| `golden_toolkit` / `alchemist` | ❌ Not installed | — |
| `fake_cloud_firestore` / `firebase_auth_mocks` | ❌ Not installed | — |
| `http_mock_adapter` / `dio` test helpers | ❌ Not installed | — |
| Test helpers / fixtures | ❌ None | No `test/helpers/`, `test/fixtures/`, `test/mocks/` |
| Coverage config | ❌ None | `.gitignore` excludes `/coverage/` but nothing generates it |
| CI test pipeline | ❌ None | No `.github/workflows/`; no `flutter test` in any script |

### 1.2 Existing Test Execution

```text
$ flutter test
00:00 +0 -1: Counter increments smoke test [E]
  LocaleController not found
  Expected text "0" — Found 0 widgets
```

The test at `test/widget_test.dart` is the default Flutter counter template. It:
- Pumps `CasaZeroApp` without `InitialBinding`, `GetStorage`, or `LocaleController`
- Asserts counter UI (`'0'`, `Icons.add`) that does not exist in CasaZero
- **Fails 100% of the time** — the test suite is broken, not merely empty

### 1.3 Native Test Stubs

Empty Xcode test targets exist (`ios/RunnerTests/`, `macos/RunnerTests/`) but contain no Flutter-relevant assertions and are not wired to `flutter test`.

---

## 2. Unit Tests

| Metric | Value |
|--------|-------|
| Unit test files | **0** |
| Models with `fromJson` / `toJson` | **14** (testable serialization) |
| Utility modules | **11** in `lib/core/utils/` |
| Services | **15** in `lib/core/services/` |

### 2.1 High-Value Untested Units

| Target | Why It Matters | Complexity |
|--------|----------------|------------|
| `UserModel.fromJson` / `toJson` | Auth session, profile, 2FA flags | Low |
| `ResidenceModel`, `DocumentModel`, `TicketModel` | Core data shapes across features | Low |
| `firebase_response_parser.dart` | Normalizes heterogeneous API payloads | Medium |
| `firebase_error_handler.dart` | User-facing error mapping | Medium |
| `SessionExpiryService` | 401 → forced logout (security-critical) | Medium |
| `ApiService._refreshToken` / interceptors | Token refresh, session expiry | High (needs Dio mock) |
| `StorageService` | Token persistence, first-login flags | Medium |
| `firebase_config_audit.dart` | Startup config validation | Low |

### 2.2 Unit Test Score: **0 / 100**

No `test/unit/` directory. No pure-function tests for parsers, models, or utilities.

---

## 3. Widget Tests

| Metric | Value |
|--------|-------|
| Widget test files | **1** (failing) |
| Screens (`*Screen` classes) | **~27** |
| Core reusable widgets | **~41** in `lib/core/widgets/` |
| Section / dialog widgets | **~60+** under `presentation/*/views/` |

### 3.1 Widget Test Gaps

| Category | Count | Tested |
|----------|------:|-------:|
| Auth screens | 4 | 0 |
| Profile / 2FA screens | 6 | 0 |
| Home sections | 12 | 0 |
| Chat screens | 5 | 0 |
| Documents / Maintenance / Tickets | 6+ | 0 |
| Core widgets (`CustomButton`, `PasswordInput`, `StatusBadge`, etc.) | 41 | 0 |

### 3.2 Widget Testability Blockers

1. **GetX global DI** — widgets/controllers call `Get.find()` without test bindings
2. **Firebase init in `main.dart`** — `CasaZeroApp` assumes `LocaleController` is pre-registered
3. **ScreenUtil** — `flutter_screenutil` requires `ScreenUtilInit` wrapper in tests
4. **Network images** — `CachedNetworkImage` needs mock HTTP or golden overrides
5. **No `pumpCasaZeroApp` test helper** — every widget test would duplicate bootstrap boilerplate

### 3.3 Widget Test Score: **1 / 100**

One file exists but provides negative value (fails CI if ever enabled).

---

## 4. Integration Tests

| Metric | Value |
|--------|-------|
| `integration_test/` directory | **None** |
| `integration_test` package | **Not in pubspec** |
| E2E flow tests | **0** |

### 4.1 Missing Integration Coverage

No device/emulator tests for:
- Cold start → splash → auth routing
- Full login → first-login setup → home
- Tab navigation via `MainScaffold` / `HomeController.currentScreen`
- Document upload → download → open
- Push notification → deep link navigation (`NotificationManager`)
- Background FCM handler (`_firebaseMessagingBackgroundHandler`)
- Offline / airplane mode behavior

### 4.2 Integration Test Score: **0 / 100**

---

## 5. Repository Tests

| Repository | Public Methods | Tests | Mock Strategy Available |
|------------|---------------|------:|-------------------------|
| `AuthRepository` | 19 | 0 | ❌ No interface; hard `Get.find()` on 4 services |
| `HomeRepository` | 11 | 0 | ❌ Direct `ApiService` dependency |
| `DocumentRepository` | 8 | 0 | ❌ |
| `ProfileRepository` | 7 | 0 | ❌ |
| `TicketRepository` | 4 | 0 | ❌ |
| `AiRepository` | 2 | 0 | ❌ |
| `PrivateChatRepository` | 4 | 0 | ❌ Firebase + API |
| `NotificationRepository` | 2 | 0 | ❌ |

**Total:** 8 repositories, **57 public methods**, **0 tests**.

### 5.1 Repository Testability Issues

- **No abstract interfaces** — cannot swap implementations without refactor
- **Concrete `Get.find()` in constructors/fields** — tests must boot full GetX graph
- **`AuthRepository` is 1,086 lines** — login, 2FA, OTP, document password, profile in one class
- **`MaintenanceController` bypasses repository layer** — API logic in controller (1,277 lines) with no repository to test in isolation

### 5.2 Repository Test Score: **0 / 100**

---

## 6. Controller Tests

| Category | Count | Tests |
|----------|------:|------:|
| Feature controllers | 21 | 0 |
| Core controllers | 2 | 0 |
| Chat providers | 2 | 0 |
| **Total** | **25** | **0** |

### 6.1 Critical Untested Controllers

| Controller | Risk | Key Untested Behaviors |
|------------|------|------------------------|
| `AuthController` | **Critical** | Login validation, trusted device flow, language toggle, hardcoded dev credentials path |
| `SplashController` | **Critical** | Token check → route to auth/home/first-login |
| `FirstLoginController` | **Critical** | Password change + 2FA setup state machine |
| `OtpVerificationController` | **Critical** | OTP send/verify/resend/cancel |
| `TwoFAManagementController` | **Critical** | Activation/deactivation flows, method selection |
| `HomeController` | **High** | Residence selection, notification CRUD, tab navigation, logout state reset |
| `DocumentsController` | **High** | Upload/download/delete/share, file open |
| `MaintenanceController` | **High** | Task CRUD, file pick, direct API calls |
| `ChatController` / `PrivateChatController` | **High** | Firebase auth retry, message send, stream handling |
| `TicketsController` | **Medium** | Filter, photo attach, ticket creation |
| `TrustedDevicesController` | **Medium** | Device revoke, geocoding display |

### 6.2 Controller Testability Issues

- Controllers use `Get.find()`, `Get.toNamed()`, `Get.snackbar()` — need GetX test mode or wrappers
- Many controllers **instantiate repositories directly** (`AuthRepository()`, `HomeRepository()`) bypassing DI mocks
- `HomeController` is a god object (~1,500+ lines) mixing navigation, data fetching, and preload logic
- Rx/Obx state changes are not verified anywhere

### 6.3 Controller Test Score: **0 / 100**

---

## 7. Firebase Tests

### 7.1 Firebase Surface Area

| Component | Files Touching Firebase | Tests |
|-----------|------------------------|------:|
| `firebase_core` / `firebase_options.dart` | `main.dart`, bindings | 0 |
| `firebase_auth` | `firebase_auth_service.dart`, `auth_repository.dart`, chat controllers | 0 |
| `cloud_firestore` | `private_chat_service.dart`, `presence_service.dart`, chat providers | 0 |
| `firebase_messaging` | `fcm_service.dart`, `main.dart` background handler | 0 |
| `firebase_storage` | Document/profile upload paths | 0 |

**~30+ files** reference Firebase APIs. **0** use `firebase_auth_mocks`, `fake_cloud_firestore`, or emulator configuration.

### 7.2 Untested Firebase Behaviors

| Behavior | Risk |
|----------|------|
| Custom-token sign-in after API login | Auth failure → chat unavailable |
| FCM token attach on login | Missing push on new device |
| Background FCM isolate handler | Crashes or silent notification loss |
| Firestore message streams | Duplicate messages, missed reads |
| Presence online/offline | Stale presence indicators |
| Firebase auth retry in chat | Message send failures |

### 7.3 Firebase Test Score: **0 / 100**

---

## 8. API Tests

### 8.1 Network Layer

| Component | Details | Tests |
|-----------|---------|------:|
| `ApiService` | Dio client, auth header injection, 401 refresh, session expiry | 0 |
| `ApiConstants` | **58** endpoint constants | 0 |
| Repositories | 57 methods calling API | 0 |
| `MaintenanceController` | Direct `ApiService` calls (no repository) | 0 |

### 8.2 Untested API Scenarios

| Scenario | Impact |
|----------|--------|
| 401 → token refresh → retry | Silent failure or logout loop |
| 401 → refresh fails → `SessionExpiryService` | User stranded or session leak |
| Malformed JSON → model parse | Crash on feed/documents/tickets |
| Timeout / offline | Unhandled error states in UI |
| Pagination / empty responses | Empty states vs error states |
| Multipart document upload | Upload failures, progress handling |

### 8.3 API Test Score: **0 / 100**

No contract tests, no `http_mock_adapter`, no recorded fixtures. (See also `API_CONTRACT_AUDIT_REPORT.md` for endpoint documentation gaps.)

---

## 9. Mock Coverage

| Mock Type | Required For | Present |
|-----------|--------------|---------|
| Repository interfaces | Controller unit tests | ❌ |
| `ApiService` mock | Repository tests | ❌ |
| `StorageService` mock | Auth/session tests | ❌ |
| `FcmService` mock | Login payload tests | ❌ |
| `DeviceInfoService` mock | Login metadata tests | ❌ |
| `FirebaseAuth` mock | Chat/auth tests | ❌ |
| `Firestore` fake | Private chat tests | ❌ |
| `Dio` adapter | HTTP tests | ❌ |
| Navigation mock | Flow tests | ❌ |
| File picker / image picker | Document/profile upload | ❌ |

### 9.1 Mock Coverage Score: **3 / 100**

`fake_async` is present transitively via `flutter_test` but unused. No project-owned mocks, no code generation (`@GenerateMocks`), no manual fake classes.

---

## 10. Golden Tests

| Metric | Value |
|--------|-------|
| Golden files (`*.png` beside tests) | **0** |
| `golden_toolkit` / Flutter `matchesGoldenFile` usage | **0** |
| Screens with complex responsive layouts | Home, Profile, Documents, Maintenance, Smart Home |

### 10.1 Golden Test Candidates

| Screen / Widget | Rationale |
|-----------------|-----------|
| `AuthScreen` | Brand entry point; regression visible to all users |
| `HomeScreen` sections | Construction progress, notifications, quick tiles |
| `CustomButton` / `GradientButton` | Design system consistency |
| `StatusBadge` | Status color mapping |
| `FloatingBottomNavBar` | Primary navigation chrome |
| `MainScaffold` | Tablet vs phone layout (`tablet_centered_layout.dart`) |

### 10.2 Golden Test Score: **0 / 100**

---

## 11. Critical User Flow Tests

| Flow | Steps | Unit | Widget | Integration | Status |
|------|-------|:----:|:------:|:-----------:|--------|
| **F1** App launch / splash routing | Token check → auth or home | — | — | — | ❌ Untested |
| **F2** Email/password login | Auth → API → Firebase sync → storage | — | — | — | ❌ Untested |
| **F3** Trusted device / OTP gate | Login → OTP screen → verify | — | — | — | ❌ Untested |
| **F4** First-login setup | Change password → 2FA method → verify | — | — | — | ❌ Untested |
| **F5** Forgot / reset password | Email → link → new password | — | — | — | ❌ Untested |
| **F6** 2FA activation / deactivation | Method select → OTP → enable/disable | — | — | — | ❌ Untested |
| **F7** Document password + 2FA | Set/view document password | — | — | — | ❌ Untested |
| **F8** Residence selection | Multi-building → home data refresh | — | — | — | ❌ Untested |
| **F9** Document upload/download | Pick file → upload → download → open | — | — | — | ❌ Untested |
| **F10** Maintenance task lifecycle | Create → schedule → complete → delete | — | — | — | ❌ Untested |
| **F11** Support ticket creation | Issue type → photos → submit | — | — | — | ❌ Untested |
| **F12** Admin / private chat | Firebase auth → send → receive stream | — | — | — | ❌ Untested |
| **F13** Push → navigation | FCM payload → `NotificationManager` route | — | — | — | ❌ Untested |
| **F14** Session expiry | 401 → refresh fail → logout → auth screen | — | — | — | ❌ Untested |
| **F15** Logout | Clear storage → reset controllers → auth | — | — | — | ❌ Untested |
| **F16** Language switch | Locale change → API sync → UI update | — | — | — | ❌ Untested |
| **F17** Profile image upload | Pick → upload → refresh profile | — | — | — | ❌ Untested |
| **F18** Trusted device revoke | List → revoke → API confirm | — | — | — | ❌ Untested |

**Critical flow coverage: 0 / 18 (0%)**

---

## 12. Coverage Matrix

**Legend:** ✅ Tested · ⚠️ Partial · ❌ None · 🔴 High risk untested

### 12.1 By Feature Module

| Feature Module | Unit | Widget | Repo | Controller | Firebase | API | Integration | Golden | Risk |
|----------------|:----:|:------:|:----:|:----------:|:--------:|:---:|:-----------:|:------:|:----:|
| Splash / routing | ❌ | ❌ | — | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| Auth (login/logout) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| Forgot password | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | 🔴 |
| First-login setup | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| OTP verification | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| 2FA management | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| Document password | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | 🔴 |
| Home / feed | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | 🟠 |
| Notifications | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟠 |
| Documents | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| Maintenance | ❌ | ❌ | — | ❌ | — | ❌ | ❌ | ❌ | 🟠 |
| Tickets | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | 🟠 |
| Chat (admin) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| Private chat | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔴 |
| AI assistant | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | 🟡 |
| Profile | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟠 |
| Trusted devices | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | 🟠 |
| Hub | ❌ | ❌ | — | ❌ | — | — | ❌ | ❌ | 🟡 |
| Smart home | ❌ | ❌ | — | — | — | — | ❌ | ❌ | 🟡 |
| Push / FCM | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | ❌ | 🔴 |
| Session / API core | ❌ | ❌ | — | — | — | ❌ | ❌ | ❌ | 🔴 |
| Localization | ❌ | ❌ | — | ❌ | — | ❌ | ❌ | ❌ | 🟡 |
| Demo mode | ❌ | ❌ | — | ❌ | — | — | ❌ | ❌ | 🟢 |

### 12.2 By Layer

| Layer | Files | Estimated Testable Units | Tests Written | Coverage |
|-------|------:|-------------------------:|--------------:|---------:|
| Models (`fromJson`/`toJson`) | 14 | ~40 factory/round-trip cases | 0 | **0%** |
| Repositories | 8 | 57 methods | 0 | **0%** |
| Controllers + providers | 25 | ~120 public methods | 0 | **0%** |
| Services | 15 | ~80 methods | 0 | **0%** |
| Utils / parsers | 11 | ~25 functions | 0 | **0%** |
| Screens | ~27 | 27 smoke tests minimum | 0 | **0%** |
| Core widgets | 41 | 41 render tests minimum | 0 | **0%** |
| API endpoints | 58 | 58 contract tests (ideal) | 0 | **0%** |
| Critical user flows | 18 | 18 integration tests | 0 | **0%** |

### 12.3 Aggregate Coverage Estimate

| Test Type | Files / Targets | Covered | Estimated % |
|-----------|----------------:|--------:|------------:|
| Unit | ~270 testable units | 0 | **0.0%** |
| Widget | ~68 screens/widgets | 0 | **0.0%** |
| Integration | 18 critical flows | 0 | **0.0%** |
| Golden | ~10 priority surfaces | 0 | **0.0%** |
| **Overall line/branch coverage** | ~49,200 LOC | ~0 | **< 0.1%** |

---

## 13. Untested Features (Complete List)

All production features are untested. Grouped by user visibility:

### 13.1 Security & Identity (Highest Priority)

- Email/password authentication with device metadata
- Trusted device verification and OTP gate
- First-login forced password change
- 2FA: authenticator QR, email OTP, SMS OTP
- 2FA activation and deactivation flows
- Document password set/verify with 2FA
- Session token refresh and forced expiry logout
- Trusted device list and revoke
- Firebase custom-token synchronization post-login

### 13.2 Core Resident Experience

- Multi-residence selection and switching
- Home feed, construction phases, residence info
- In-app notification list, read, delete, unread count
- Document categories, filtering, unit-wise view
- Document upload (multipart), download, delete, share, open
- Encrypted ZIP download with password prompt
- Maintenance task CRUD, scheduling, file attachments
- Support ticket creation with photos and issue types
- AI chat history and message send
- Profile view/edit, image upload, notification preferences
- Language switch (en/it) with backend sync

### 13.3 Real-Time & Push

- FCM registration and token refresh on login
- Foreground / background / terminated push handling
- `NotificationManager` deep-link routing by push type
- Admin chat (Firestore stream)
- Private resident chat (Firestore + API notifications)
- Online presence indicators

### 13.4 Shell & Navigation

- `MainScaffold` tab switching via `HomeController.currentScreen`
- Back navigation stack per tab
- Tablet-centered layout breakpoints
- App lifecycle refresh wrapper
- Demo mode controls (unwired but present)

### 13.5 Placeholder / Low-Traffic

- Smart Home screen (mock UI, 886 lines)
- Hub card grid
- Orphaned `AdminChatScreen` / `AdminChatController`

---

## 14. Missing Test Coverage (Prioritized)

### 14.1 P0 — Must Have Before Production Confidence

| # | Gap | Suggested Test Type |
|---|-----|---------------------|
| 1 | `AuthRepository.login` success/failure/2FA branches | Unit + fixture JSON |
| 2 | `SessionExpiryService` on 401 | Unit |
| 3 | `SplashController` routing logic | Controller unit |
| 4 | `ApiService` token refresh interceptor | Unit with Dio mock |
| 5 | Model `fromJson` round-trips (`UserModel`, `DocumentModel`) | Unit |
| 6 | Login → home integration smoke | Integration |
| 7 | Delete or fix failing `widget_test.dart` | Hygiene |

### 14.2 P1 — High Value

| # | Gap | Suggested Test Type |
|---|-----|---------------------|
| 8 | `TwoFAManagementController` state machine | Controller unit |
| 9 | `DocumentsController` upload/download error paths | Controller + repo |
| 10 | `NotificationManager` payload → route mapping | Unit |
| 11 | `firebase_response_parser` edge cases | Unit |
| 12 | `AuthScreen` / `HomeScreen` smoke widget tests | Widget |
| 13 | `CustomButton`, `PasswordInput`, `StatusBadge` | Widget / golden |
| 14 | CI: `flutter test` on every PR | Pipeline |

### 14.3 P2 — Medium Value

| # | Gap | Suggested Test Type |
|---|-----|---------------------|
| 15 | `MaintenanceController` API methods | Unit (after repository extraction) |
| 16 | `ChatController` send/retry | Unit with Firebase mocks |
| 17 | `PrivateChatService` conversation ID logic | Unit |
| 18 | Golden tests for responsive layouts | Golden |
| 19 | Ticket creation flow | Integration |
| 20 | FCM background handler | Integration / emulator |

---

## 15. Testing Risk Assessment

### 15.1 Risk Register

| ID | Risk | Likelihood | Impact | Detectability | Severity |
|----|------|:----------:|:------:|:-------------:|:--------:|
| TR-01 | Auth/login regression ships silently | High | Critical | None (no tests) | **Critical** |
| TR-02 | 2FA bypass or broken OTP lockout | Medium | Critical | None | **Critical** |
| TR-03 | Session expiry fails → stale token / auth loop | Medium | High | None | **High** |
| TR-04 | Document upload/download data loss | Medium | High | None | **High** |
| TR-05 | Firebase desync after login → chat broken | Medium | High | None | **High** |
| TR-06 | Push notification mis-routing | Medium | Medium | None | **High** |
| TR-07 | Model parse crash on API schema change | High | High | Manual only | **High** |
| TR-08 | `HomeController` state leak after logout | Medium | High | None | **High** |
| TR-09 | Maintenance API logic regression | High | Medium | None | **Medium** |
| TR-10 | UI layout break on tablet/phone | Medium | Medium | None | **Medium** |
| TR-11 | i18n string regression | Low | Low | Manual | **Low** |
| TR-12 | Broken test suite blocks CI adoption | High | Medium | Known | **Medium** |

### 15.2 Testability Debt (Blocks Fast Test Adoption)

| Blocker | Affected Tests | Remediation |
|---------|----------------|-------------|
| No repository interfaces | All controller/repo unit tests | Introduce abstract repos |
| `Get.find()` in constructors | All layers | Constructor injection or `Get.testMode` + fakes |
| God controllers (`HomeController`, `MaintenanceController`) | Unit isolation | Split responsibilities |
| Firebase required at init | Widget/integration | `Firebase.initializeApp` test mocks or emulators |
| Direct `new Repository()` in controllers | Mock swapping | Enforce DI from `InitialBinding` |
| No test bootstrap helper | Widget tests | Create `test/helpers/pump_app.dart` |

### 15.3 Risk Heatmap

```
                 Impact →
           Low      Medium    High      Critical
      ┌─────────┬─────────┬─────────┬─────────┐
 Low  │ TR-11   │         │         │         │
      ├─────────┼─────────┼─────────┼─────────┤
 Med  │         │ TR-10   │ TR-05   │ TR-02   │
      │         │ TR-12   │ TR-06   │         │
      ├─────────┼─────────┼─────────┼─────────┤
 High │         │ TR-09   │ TR-03   │ TR-01   │
      │         │         │ TR-04   │         │
      │         │         │ TR-07   │         │
      │         │         │ TR-08   │         │
      └─────────┴─────────┴─────────┴─────────┘
```

---

## 16. Scoring Methodology

### 16.1 Testing Score (4 / 100)

Weighted average across test dimensions:

| Dimension | Weight | Score | Weighted |
|-----------|-------:|------:|---------:|
| Test infrastructure & tooling | 10% | 4 | 0.4 |
| Unit tests | 15% | 0 | 0.0 |
| Widget tests | 10% | 1 | 0.1 |
| Integration tests | 15% | 0 | 0.0 |
| Repository tests | 10% | 0 | 0.0 |
| Controller tests | 10% | 0 | 0.0 |
| Firebase tests | 10% | 0 | 0.0 |
| API / network tests | 10% | 0 | 0.0 |
| Mock coverage & testability | 5% | 3 | 0.15 |
| Golden / visual tests | 5% | 0 | 0.0 |
| Critical flow tests | 10% | 0 | 0.0 |
| **Total** | **100%** | — | **3.65 → 4** |

**Rationale:** `flutter_test` is present (+4 infra). One widget test file exists but fails (-negligible). Zero meaningful coverage across all layers.

### 16.2 Production Confidence Score — Testing Lens (18 / 100)

This score answers: *"How much can we trust automated testing to catch regressions before release?"*

| Factor | Score | Notes |
|--------|------:|-------|
| Automated regression detection | 0 | No passing tests |
| Security-flow verification | 0 | Auth/2FA/session untested |
| Data integrity verification | 0 | Models/repos untested |
| Real-time / Firebase reliability | 0 | Chat/FCM untested |
| CI gate preventing broken merges | 0 | No pipeline |
| Manual QA / code review baseline | +10 | Implied from feature completeness |
| Existing audit documentation | +5 | API, Firebase, GetX audits provide static analysis |
| Test tooling present (not used) | +3 | `flutter_test` available |
| **Total** | **18** | |

**Cross-reference:** `CROSS_PLATFORM_PRODUCTION_AUDIT.md` rates overall production readiness at **62/100** — that score reflects feature breadth and native packaging, not test coverage. The testing-specific confidence score is **far lower** because no automated safety net exists.

---

## 17. Recommended Testing Roadmap

### Phase 0 — Hygiene (1–2 days)

1. Remove or replace `test/widget_test.dart` with a minimal passing smoke test
2. Add `mocktail`, `http_mock_adapter` to `dev_dependencies`
3. Create `test/helpers/pump_app.dart` with GetX + ScreenUtil bootstrap
4. Add GitHub Actions / CI job: `flutter test --coverage`

### Phase 1 — Foundation (1–2 weeks)

1. Model unit tests: all 14 `fromJson` factories with fixture JSON files
2. Utility tests: `firebase_response_parser`, `firebase_error_handler`
3. `ApiService` unit tests: auth header, 401 refresh, session expiry redirect
4. `SessionExpiryService` unit tests
5. Abstract repository interfaces for `Auth`, `Home`, `Document`

### Phase 2 — Core Flows (2–3 weeks)

1. `AuthRepository` + `AuthController` login/OTP tests with mocks
2. `SplashController` routing tests
3. `TwoFAManagementController` activation/deactivation tests
4. Widget smoke tests: `AuthScreen`, `SplashScreen`, `HomeScreen`
5. Golden tests for `CustomButton`, `StatusBadge`, `FloatingBottomNavBar`

### Phase 3 — Integration & Firebase (2–4 weeks)

1. Add `integration_test` package
2. Login → home E2E on emulator
3. `fake_cloud_firestore` for `PrivateChatService`
4. `firebase_auth_mocks` for chat controllers
5. FCM payload → navigation tests for `NotificationManager`

### Phase 4 — Coverage Targets

| Milestone | Target |
|-----------|--------|
| 3 months | 40% unit coverage on `data/` + `core/utils/` |
| 6 months | 60% on repositories + critical controllers |
| 6 months | 5 integration tests for P0 flows |
| 12 months | 70% overall line coverage, CI gate at 50% |

---

## 18. Test File Structure (Proposed)

```text
test/
├── helpers/
│   ├── pump_app.dart              # GetX + ScreenUtil + bindings
│   ├── mock_bindings.dart         # Replace services with fakes
│   └── fixtures/                  # JSON API responses
│       ├── login_success.json
│       ├── user_profile.json
│       └── documents_list.json
├── unit/
│   ├── models/
│   ├── utils/
│   ├── services/
│   │   ├── api_service_test.dart
│   │   └── session_expiry_service_test.dart
│   ├── repositories/
│   └── controllers/
├── widget/
│   ├── auth/
│   ├── home/
│   └── core/
│       └── custom_button_test.dart
├── golden/
│   └── goldens/
└── integration/
    └── app_test.dart

integration_test/
├── login_flow_test.dart
└── document_flow_test.dart
```

---

## 19. Summary

| Question | Answer |
|----------|--------|
| Are tests passing? | **No** — 1 test, 1 failure |
| Line coverage | **< 0.1%** (effectively zero) |
| Repositories tested? | **0 / 8** |
| Controllers tested? | **0 / 25** |
| Firebase tested? | **No** |
| API layer tested? | **No** |
| Mocks exist? | **No** |
| Golden tests? | **No** |
| Critical flows tested? | **0 / 18** |
| CI runs tests? | **No** |
| **Testing Score** | **4 / 100** |
| **Production Confidence (Testing)** | **18 / 100** |

CasaZero has mature feature code and companion static audits (API, Firebase, GetX, network), but **no automated testing discipline**. The highest-ROI first step is fixing the broken widget test, adding mock infrastructure, and unit-testing models + `ApiService` session handling — the areas most likely to catch security and data regressions with minimal refactor.

---

*Generated by static analysis. Run `flutter test --coverage` after implementing Phase 0 to establish a baseline.*
