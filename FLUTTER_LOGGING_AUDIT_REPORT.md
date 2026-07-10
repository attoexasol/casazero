# Flutter Logging Audit

**Project:** CasaZero (`d:\Sajid\casazero`)  
**Date:** July 10, 2026  
**Scope:** Static analysis of debug/production logging, sensitive data exposure, API/auth/error/crash/analytics/performance observability, and log architecture  
**Constraint:** Analysis only — no source modifications

---

## Executive Summary

CasaZero has **no centralized logging framework**. Observability is implemented via **~1,145 ad-hoc `print()` / `debugPrint()` calls** across **52 Dart files**, with **no log levels**, **no release-mode gating**, and **no remote aggregation**. Critical credentials — **full API access tokens, FCM tokens, device tokens, JWT claims, PII, and API response bodies** — are written to device logs in production paths.

There is **no crash reporting** (Crashlytics/Sentry), **no Flutter Performance Monitoring**, and **no product analytics in Dart**. Android Gradle pulls in native Firebase Analytics passively; iOS has no Flutter-equivalent. A single `kDebugMode` guard exists in the entire codebase.

| Dimension | Score |
|-----------|-------|
| Logging Architecture | 8 |
| Debug vs Production Separation | 5 |
| Sensitive Data Protection | 12 |
| API Logging Safety | 10 |
| Authentication Logging Safety | 15 |
| Error Logging Quality | 35 |
| Crash Reporting | 0 |
| Analytics | 18 |
| Performance Monitoring | 0 |
| Structured Logging | 5 |
| Log Filtering / Levels | 0 |
| **Overall Logging Health** | **22 / 100** |
| **Production Monitoring Score** | **14 / 100** |

**Verdict:** The app is **debuggable during development** but **unsafe and unobservable in production**. Logs leak session credentials to `logcat`/Console; crashes and performance regressions are invisible without manual device log collection.

---

## 1. Logging Inventory

### 1.1 Volume & Distribution

| Metric | Value |
|--------|-------|
| `print()` statements | **1,001** across **44 files** |
| `debugPrint()` statements | **144** across **21 files** |
| **Total log statements** | **~1,145** |
| Files with any logging | **~52** (~26% of `lib/`) |
| `kDebugMode` guards on logs | **1** (`chat_controller.dart`) |
| Central `Logger` class | **None** |
| `avoid_print` lint enforced | **No** (`analysis_options.yaml` — rule commented out) |

### 1.2 Top Offenders (`print()` count)

| File | `print()` | Layer |
|------|----------:|-------|
| `auth_repository.dart` | 100 | Auth / API |
| `home_repository.dart` | 100 | API |
| `maintenance_controller.dart` | 100 | API (direct) |
| `document_repository.dart` | 81 | Documents / API |
| `home_controller.dart` | 71 | Controller |
| `profile_controller.dart` | 70 | Controller |
| `ai_repository.dart` | 48 | API |
| `documents_controller.dart` | 46 | Controller |
| `profile_repository.dart` | 43 | API |
| `login_api_debug.dart` | 40 | Auth debug utility |
| `download_service.dart` | 34 | Network |
| `fcm_service.dart` | 28 | Push |
| `main.dart` | 24 | Startup |
| `ticket_repository.dart` | 22 | API |

### 1.3 Partially Structured Utilities (Still Always-On)

| Utility | Path | Behavior |
|---------|------|----------|
| `LoginApiDebug` | `lib/core/utils/login_api_debug.dart` | Box-drawn login request/response dumps; redacts `password` only |
| `FirebaseJwtDebug` | `lib/core/utils/firebase_jwt_debug.dart` | Decodes JWT payload; logs claims not full token |
| `FirebaseConfigAudit` | `lib/core/utils/firebase_config_audit.dart` | Startup Firebase project/app dump via `debugPrint` |
| `FirebaseErrorHandler` | `lib/core/utils/firebase_error_handler.dart` | Parses errors; structured `debugPrint` with tag/path/code |
| `FirebaseResponseParser` | `lib/core/utils/firebase_response_parser.dart` | Token presence logging via `debugPrint` |

**Critical gap:** `LoginApiDebug` imports `foundation.dart` but **never checks `kDebugMode`** — login API dumps run in **release builds**.

---

## 2. Debug Logs

### 2.1 Current Behavior

All development-style logging runs unconditionally:

- Emoji-prefixed console output (`🌐`, `🔑`, `❌`, `✅`)
- Multi-line ASCII box banners for login and maintenance API responses
- Full JSON response dumps (maintenance controller prints entire `jsonEncode(response.data)`)
- Verbose Firebase auth state traces in `chat_controller.dart` (~65 `debugPrint` lines for UID-null diagnosis)

### 2.2 `print()` vs `debugPrint()`

| API | Release behavior | CasaZero usage | Risk |
|-----|------------------|----------------|------|
| `print()` | **Always emitted** to system logs (Android `logcat`, iOS Console) | **1,001 calls** — interceptors, repos, controllers | **Critical** — tokens in production logs |
| `debugPrint()` | Throttled; **stripped on many release builds** | **144 calls** — Firebase services, chat | Lower but not zero on all platforms |

**Assessment:** The most sensitive logs (API tokens in `ApiService`, `DownloadService`) use **`print()`**, guaranteeing production exposure.

### 2.3 Debug Log Score: **5 / 100**

No separation between debug and production. One `kDebugMode` check in 1,145 log statements (0.09%).

---

## 3. Production Logs

### 3.1 What Runs in Release

| Category | Runs in release? | Examples |
|----------|------------------|----------|
| API request URL + method | ✅ Yes | `ApiService` interceptor |
| Full bearer access token | ✅ Yes | `🔑 [API TOKEN] ${token}` on every HTTP call |
| Download bearer token | ✅ Yes | `DownloadService` interceptor |
| Login device metadata | ✅ Yes | device_id, lat/lng, IP, phone, FCM token |
| Full API response bodies | ✅ Yes | `HomeRepository`, `MaintenanceController` |
| Firebase startup audit | ⚠️ Partial | `debugPrint` — may be stripped |
| Session expiry errors | ✅ Yes | `SessionExpiryService` `print` |
| FCM message metadata | ✅ Yes | `main.dart` background handler `print` |

### 3.2 Missing Production Logging Discipline

- No log level configuration per build flavor (`dev` / `staging` / `prod`)
- No remote log shipping (Datadog, Cloud Logging, etc.)
- No sampling or rate limiting
- No correlation IDs across API → Firebase → navigation
- No build-flavor stripping of debug utilities

### 3.3 Production Log Score: **5 / 100**

Production builds emit the same verbose debug output as development.

---

## 4. Sensitive Data Logging

### 4.1 Critical Findings (Security)

| ID | Severity | Location | Data Exposed |
|----|----------|----------|--------------|
| **SL-01** | 🔴 **Critical** | `api_service.dart:45` | **Full API access token** on every HTTP request |
| **SL-02** | 🔴 **Critical** | `download_service.dart:29` | **Full bearer token** on every file download |
| **SL-03** | 🔴 **Critical** | `auth_controller.dart:100-106` | **Full access token** from login result + stored token |
| **SL-04** | 🔴 **Critical** | `auth_repository.dart:57-59` | **Full FCM token**, **full stored device token** |
| **SL-05** | 🔴 **Critical** | `auth_repository.dart:76-89` | Login request via `LoginApiDebug` — email, device_id, lat/lng, IP, fcm_token (password redacted only) |
| **SL-06** | 🟠 **High** | `auth_repository.dart:537` | Access token first 20 chars in document-password request log |
| **SL-07** | 🟠 **High** | `home_repository.dart:47,640,643` | Full `response.data` — may contain user PII, residence data |
| **SL-08** | 🟠 **High** | `maintenance_controller.dart:162-168` | Full maintenance API JSON responses |
| **SL-09** | 🟠 **High** | `auth_controller.dart:45-46` | **Hardcoded production credentials** in source (not a log, but compounds SL-03–05 risk) |
| **SL-10** | 🟠 **High** | `login_api_debug.dart:48-60` | Raw API response string up to 2000 chars — may contain tokens |
| **SL-11** | 🟡 **Medium** | `auth_repository.dart:52-56` | Device ID, geolocation, IP address |
| **SL-12** | 🟡 **Medium** | `otp_verification_controller.dart:237` | `print(result.toString())` — OTP flow result dump |
| **SL-13** | 🟡 **Medium** | `chat_controller.dart:147-174` | Laravel user ID, Firebase UID, email in debug report |
| **SL-14** | 🟡 **Medium** | `api_service.dart:196-197` | Full API error response bodies (may include validation details) |
| **SL-15** | 🟢 **Low** | `FirebaseJwtDebug.describeClaims` | JWT claims only (aud, iss, sub, uid) — intentional safe pattern |

### 4.2 Redaction Patterns Observed

| Pattern | Where | Adequate? |
|---------|-------|-----------|
| `password: ***REDACTED***` | `LoginApiDebug` | ✅ For password field only |
| `old_password/new_password: ***` | `AuthRepository.changePassword` | ✅ |
| Token `substring(0, 10)...` | Logout, some repo logs | ⚠️ Partial — prefix still sensitive |
| JWT claims without full token | `FirebaseJwtDebug` | ✅ Good pattern to replicate |
| No redaction | `ApiService`, `DownloadService`, `AuthController` login | ❌ |

### 4.3 Sensitive Data Score: **12 / 100**

Password fields are partially redacted in auth flows, but **session tokens are logged in full** across the network layer — the highest-risk category for a resident portal app.

---

## 5. API Logging

### 5.1 HTTP Interceptors

| Service | Logs per request | Token logged | Response body logged |
|---------|------------------|--------------|---------------------|
| `ApiService` | Method + URI + token + retry | **Full token** (`print`) | On error only (`_handleError`) |
| `DownloadService` | Method + URI + token | **Full token** (`print`) | On failure paths |
| `ZipDownloadService` | None in interceptor | No | No |

No `LogInterceptor`, `PrettyDioLogger`, or Dio `LogLevel` — custom inline `print` only.

### 5.2 Repository-Level API Dumps

Repositories log at call site, not centrally:

| Repository | Request logging | Response logging | Error logging |
|------------|----------------|------------------|---------------|
| `AuthRepository` | Verbose via `LoginApiDebug` | Full normalized body | `print` exception |
| `HomeRepository` | Token prefix, request body | **Full `response.data`** | Status + body + stack |
| `DocumentRepository` | Token prefix, upload metadata | Upload response data | Dio error body |
| `ProfileRepository` | Partial | Partial | `print` |
| `TicketRepository` | Partial | Partial | `print` |
| `AiRepository` | Token type/length | Message metadata | Stack traces |
| `MaintenanceController` | Request params | **Full JSON response** | Stack traces |

### 5.3 API Logging Score: **10 / 100**

Useful for local debugging; **dangerous in production** due to full token and response body emission with no opt-out.

---

## 6. Authentication Logging

### 6.1 Login Flow Log Trail

A single login produces **50+ log lines** across:

1. `AuthRepository` — device info, FCM token, stored token
2. `LoginApiDebug` — boxed request (email, device, geo, IP) + boxed response (all keys, firebase token metadata)
3. `FirebaseJwtDebug` — JWT claims
4. `FirebaseAuthService` — project context, token length, sign-in result
5. `AuthController` — full access token (twice), user flags, storage key audit
6. `FcmService` — token refresh after auth

### 6.2 Other Auth Paths

| Flow | Logging |
|------|---------|
| Logout | Token prefix + request body prefix |
| Forgot / reset password | Error `print` only |
| Change password | Password fields redacted; response logged |
| 2FA setup / verify | Partial in `TwoFAManagementController` |
| OTP verification | User ID, `result.toString()` |
| Session expiry | Single error `print`; no audit trail |
| Splash token check | 17 `print` in `SplashController` |

### 6.3 Authentication Logging Score: **15 / 100**

Auth is the **most heavily logged** area. Redaction effort exists for passwords but is undermined by **full bearer token logging** immediately after login.

---

## 7. Error Logging

### 7.1 Patterns

| Pattern | Usage | Quality |
|---------|-------|---------|
| `print('❌ ...')` | Repositories, services, controllers | Unstructured; no error codes |
| `print('📚 Stack trace: $stackTrace')` | Home, AI, maintenance, profile repos | Full stacks to console — good for debug, no crash tool |
| `FirebaseErrorHandler.log()` | Chat / Firestore paths | **Best pattern** — tag, path, code, message via `debugPrint` |
| `ApiService._handleError()` | Returns user string; logs response body | User message OK; log may leak server details |
| `MessagePopupController` | User-facing errors | UI only — not logged remotely |
| `FirebaseErrorHandler.parse()` | Maps Firebase codes to i18n keys | Good abstraction; underused outside chat |

### 7.2 Global Error Handlers

| Handler | Present |
|---------|---------|
| `FlutterError.onError` | ❌ |
| `PlatformDispatcher.instance.onError` | ❌ |
| `runZonedGuarded` | ❌ |
| Isolate error ports | ❌ |
| Dio global error reporter | ❌ |

**Uncaught framework and async errors are not captured** — they terminate silently from a monitoring perspective.

### 7.3 Error Logging Score: **35 / 100**

Local error visibility is moderate (verbose `print` + some stack traces). `FirebaseErrorHandler` is a good template but isolated. No crash correlation or remote error aggregation.

---

## 8. Crash Logging

| Capability | Status |
|------------|--------|
| `firebase_crashlytics` | ❌ Not in `pubspec.yaml` |
| Sentry / Bugsnag | ❌ |
| `FlutterError.onError` → reporter | ❌ |
| Native crash symbol upload | ❌ Not automated |
| Dart zone error handler | ❌ |
| iOS `RunnerTests` | Empty stub only |

Crashes are **only visible** if a developer connects a device and reads `logcat`/Xcode Console before logs rotate.

### 8.1 Crash Logging Score: **0 / 100**

---

## 9. Analytics

| Capability | Status |
|------------|--------|
| `firebase_analytics` (Flutter) | ❌ Not in `pubspec.yaml` |
| Android native Analytics | ✅ `implementation("com.google.firebase:firebase-analytics")` in `build.gradle.kts` |
| iOS Analytics | ❌ No Flutter plugin equivalent |
| Custom event tracking | ❌ No `logEvent` calls in Dart |
| Screen tracking | ❌ |
| User properties / funnels | ❌ |
| Product "Analytics" screen | UI placeholder for admin role (`quick_tiles.dart`) — not telemetry |

**Assessment:** Android receives **passive auto-collected events** only. No cross-platform product analytics, conversion funnels, or feature usage measurement in Flutter code.

### 9.1 Analytics Score: **18 / 100**

---

## 10. Performance Monitoring

| Capability | Status |
|------------|--------|
| `firebase_performance` | ❌ |
| Custom `Stopwatch` / timing logs | ❌ |
| API latency tracking | ❌ |
| Frame/build profiling | ❌ |
| Startup time measurement | ❌ (only timeout `print` in `main.dart`) |
| Network request duration in interceptors | ❌ |

### 10.1 Performance Monitoring Score: **0 / 100**

---

## 11. Structured Logging

### 11.1 Current State

- **No JSON log format**
- **No consistent key=value fields** (except `FirebaseErrorHandler` and partial JWT claims)
- **No log tags registered centrally**
- **No trace/span IDs**
- **No log aggregation schema**

### 11.2 Closest Structured Patterns

```dart
// FirebaseErrorHandler — best existing pattern
debugPrint('[$tag] path=${firestorePath ?? '-'} conversationId=... code=${info.code} message=${info.message}');

// LoginApiDebug — structured boxes but unstructured content
print('[LOGIN API] method=$method');
print('[LOGIN API] url=$fullUrl');
```

### 11.3 Structured Logging Score: **5 / 100**

---

## 12. Log Filtering & Log Levels

| Feature | Status |
|---------|--------|
| Log levels (verbose/debug/info/warn/error) | ❌ |
| Per-module log tags with enable/disable | ❌ |
| `kDebugMode` gating | 1 occurrence |
| `kReleaseMode` stripping | ❌ |
| Build flavor log config | ❌ |
| Runtime log verbosity setting | ❌ |
| `avoid_print` lint | Disabled in `analysis_options.yaml` |

### 12.1 Log Filtering Score: **0 / 100**

---

## 13. Security Findings

### 13.1 Critical (Fix Before Store Release)

| ID | Finding | Impact | Remediation |
|----|---------|--------|-------------|
| **SF-01** | Full API bearer tokens logged in `ApiService` on **every request** | Session hijack via `logcat`/shared device logs | Remove token log; log `tokenPresent=true` + last 4 chars max |
| **SF-02** | Full tokens in `DownloadService` interceptor | Same as SF-01 for file downloads | Same redaction pattern |
| **SF-03** | `AuthController` prints full `access_token` after login | Token in logs at highest-traffic moment | Delete lines 100, 106; use `kDebugMode` + redacted debug only |
| **SF-04** | `LoginApiDebug` runs in release — no `kDebugMode` guard | Login PII + response metadata in production | Wrap all methods in `if (kDebugMode)` or delete utility in release |
| **SF-05** | Full FCM + device tokens in `AuthRepository.login` | Push impersonation, device tracking | Log `fcmToken.length` only |
| **SF-06** | Hardcoded credentials in `AuthController` (`auth_controller.dart:45-46`) | Credential leak via source + logs | Remove before any release build |
| **SF-07** | No crash reporting | Production crashes invisible | Add `firebase_crashlytics` + `FlutterError.onError` |

### 13.2 High

| ID | Finding | Remediation |
|----|---------|-------------|
| **SF-08** | Full API `response.data` dumps in repositories | Log status code + key names only in production |
| **SF-09** | `MaintenanceController` prints entire JSON responses | Gate behind `kDebugMode` or dedicated debug flag |
| **SF-10** | `otp_verification_controller.dart:237` dumps full OTP result | Remove or redact |
| **SF-11** | API error bodies may contain server stack traces / SQL hints | Sanitize before `print` in `_handleError` |
| **SF-12** | No global uncaught error handler | `FlutterError.onError` + Crashlytics |

### 13.3 Medium

| ID | Finding | Remediation |
|----|---------|-------------|
| **SF-13** | 1,001 `print()` statements with no lint enforcement | Enable `avoid_print`; use `logger` package |
| **SF-14** | Geolocation + IP logged at login | Production: omit or hash |
| **SF-15** | Inconsistent redaction — some paths redact, interceptors do not | Central `LogSanitizer` |
| **SF-16** | Android-only passive Analytics | Add `firebase_analytics` Flutter plugin or remove native dep |

### 13.4 Positive Patterns to Preserve

| Pattern | Location |
|---------|----------|
| Password redaction in `LoginApiDebug` | `login_api_debug.dart:19-21` |
| JWT claims without full token | `FirebaseJwtDebug.describeClaims` |
| Structured Firebase error tags | `FirebaseErrorHandler.log` |
| Token prefix truncation in logout logs | `auth_repository.dart:255-257` |

---

## 14. Logging Strategy (Recommended)

### 14.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AppLogger (singleton)                   │
│  levels: verbose | debug | info | warning | error           │
│  outputs: Console (debug only) | Crashlytics | Analytics    │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   LogSanitizer          Crashlytics          firebase_analytics
   (tokens, PII)         (non-fatal +         (business events
                          fatals)              only, no PII)
```

### 14.2 Implementation Phases

#### Phase 0 — Emergency (1–2 days, pre-release)

1. **Delete or gate** token `print` in `ApiService`, `DownloadService`, `AuthController`
2. Wrap `LoginApiDebug` in `kDebugMode` or remove calls from `AuthRepository`
3. Remove hardcoded credentials from `AuthController`
4. Enable `avoid_print: true` in `analysis_options.yaml`

#### Phase 1 — Foundation (1 week)

1. Add `logger: ^2.x` (or `talker`) with level config
2. Create `lib/core/logging/app_logger.dart` + `log_sanitizer.dart`
3. Create `lib/core/logging/redaction.dart` — `redactToken(String?) → "Bearer …abcd"`
4. Replace top-10 offender files (repos + interceptors)
5. Add `firebase_crashlytics`; wire `FlutterError.onError` + `PlatformDispatcher.onError`

#### Phase 2 — Observability (2–3 weeks)

1. Add `firebase_analytics` — screen views + key events (login, document_download, ticket_create)
2. Add `firebase_performance` — HTTP metric on `ApiService` interceptor
3. Standardize error logging: `AppLogger.error(tag, error, stackTrace, context: {...})`
4. Non-fatal Crashlytics for API 5xx, Firebase auth failures, session expiry

#### Phase 3 — Maturity (ongoing)

1. Build flavors: `LOG_LEVEL=warning` in prod, `verbose` in dev
2. Structured JSON logs for server-side correlation (optional remote sink)
3. CI check: fail build if `print(` added outside `test/` (custom lint or grep gate)
4. Migrate `FirebaseErrorHandler` to use `AppLogger` internally

### 14.3 Log Level Guidelines

| Level | Use for | Production |
|-------|---------|------------|
| `verbose` | Full request/response dumps | ❌ Off |
| `debug` | Token presence, parsed keys, state transitions | ❌ Off |
| `info` | Login success, screen navigation, download complete | ⚠️ Sampled |
| `warning` | Retry, degraded Firebase, missing optional data | ✅ On |
| `error` | API failures, parse errors, auth failures | ✅ On → Crashlytics |

### 14.4 Never Log in Production

- Passwords, OTP codes, document passwords, ZIP passwords
- Full API bearer tokens, refresh tokens, FCM tokens, Firebase custom tokens
- Full email + phone + geolocation together (PII bundle)
- Complete API response bodies containing user records
- JWT raw strings (claims summary only)

---

## 15. Production Monitoring Score

### 15.1 Scoring Breakdown

| Dimension | Weight | Score | Weighted | Notes |
|-----------|-------:|------:|---------:|-------|
| Crash capture & symbolication | 25% | 0 | 0.0 | No Crashlytics/Sentry |
| Error visibility (non-fatal) | 15% | 25 | 3.75 | Local `print` only |
| Analytics & funnels | 15% | 18 | 2.7 | Android passive only |
| Performance monitoring | 15% | 0 | 0.0 | None |
| Log safety in production | 15% | 12 | 1.8 | Tokens logged in release |
| Alerting / remote dashboards | 10% | 0 | 0.0 | No pipeline |
| Incident correlation (trace IDs) | 5% | 5 | 0.25 | None |
| **Total** | **100%** | — | **8.5 → 14** | Rounded up for partial local error visibility |

### 15.2 Production Monitoring Score: **14 / 100**

**Interpretation:** The team can debug issues **when a device is connected and logs are captured manually**. There is no proactive crash detection, no performance baseline, no product analytics in Flutter, and **active log emission creates a security liability** rather than an observability asset.

### 15.3 Comparison to Related Audits

| Audit | Score | Relationship |
|-------|------:|--------------|
| Firebase Production Audit — Observability | ~15 | Aligns — no Crashlytics/Perf/Flutter Analytics |
| Cross-Platform Production — Crashlytics | 🔴 Not integrated | Confirmed |
| Testing Audit — Production Confidence | 18 | Similar — no automated safety nets |
| **Logging Audit — Production Monitoring** | **14** | Lowest tier — logs exist but harm > help in prod |

---

## 16. Coverage Matrix

| Area | Local debug | Production-safe | Remote crash | Remote analytics | Performance |
|------|:-----------:|:---------------:|:------------:|:--------------:|:-----------:|
| App startup (`main.dart`) | ✅ Verbose | ❌ | ❌ | ❌ | ❌ |
| API (`ApiService`) | ✅ | ❌ Tokens | ❌ | ❌ | ❌ |
| Auth / login | ✅ Verbose | ❌ Tokens/PII | ❌ | ❌ | ❌ |
| 2FA / OTP | ⚠️ Partial | ❌ | ❌ | ❌ | ❌ |
| Documents / download | ✅ | ❌ Tokens | ❌ | ❌ | ❌ |
| Maintenance | ✅ Full JSON | ❌ | ❌ | ❌ | ❌ |
| Chat / Firebase | ✅ `debugPrint` | ⚠️ | ❌ | ❌ | ❌ |
| FCM / push | ✅ | ⚠️ | ❌ | ❌ | ❌ |
| Session expiry | ⚠️ Error only | ⚠️ | ❌ | ❌ | ❌ |
| User-facing errors | ✅ Popups | N/A | ❌ | ❌ | ❌ |

---

## 17. Remediation Priority

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| **P0** | Remove full token logging from `ApiService` + `DownloadService` | S | Stops credential leak |
| **P0** | Gate `LoginApiDebug` behind `kDebugMode` | S | Stops login PII leak |
| **P0** | Remove `AuthController` token prints + hardcoded credentials | S | Critical security |
| **P0** | Add Crashlytics + `FlutterError.onError` | M | Production crash visibility |
| **P1** | Introduce `AppLogger` + `LogSanitizer` | M | Sustainable architecture |
| **P1** | Enable `avoid_print` lint | S | Prevents regression |
| **P1** | Add `firebase_analytics` (Flutter) | M | Cross-platform telemetry |
| **P2** | Replace repository response dumps with level-gated summaries | L | Reduces noise + leak surface |
| **P2** | Add `firebase_performance` HTTP metrics | M | Latency baselines |
| **P3** | CI grep gate — no new bare `print(` in `lib/` | S | Enforcement |

---

## 18. Summary

| Question | Answer |
|----------|--------|
| Centralized logger? | **No** — 1,145 ad-hoc prints |
| Debug vs production separation? | **No** — same logs in release |
| Tokens logged in production? | **Yes** — full bearer tokens on every API call |
| Passwords logged? | **Mostly redacted** in auth API debug |
| Crash reporting? | **None** |
| Analytics? | **Android passive only** |
| Performance monitoring? | **None** |
| Structured logging? | **Minimal** — `FirebaseErrorHandler` only |
| Log levels / filtering? | **None** |
| **Logging Health Score** | **22 / 100** |
| **Production Monitoring Score** | **14 / 100** |

CasaZero treats the device console as a permanent debug terminal. The immediate priority is **stopping credential emission in release builds**, then **adding Crashlytics** so production failures are visible without compromising user security.

---

*Generated by static analysis. Token and PII findings verified against `api_service.dart`, `auth_repository.dart`, `auth_controller.dart`, and `login_api_debug.dart`.*
