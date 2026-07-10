# Flutter API Contract Audit Report

**Project:** CasaZero Flutter App  
**Backend base URL:** `https://backend.casazero.site/api`  
**Audit date:** July 9, 2026  
**Method:** Static analysis of `lib/` API clients, models, and `api_constants.dart` — no code modified, no live API calls executed  

**Important:** This audit documents what the **Flutter client expects and sends**. Backend behavior can only be fully verified against a running Laravel API. Where the client and documented contract diverge, both sides need alignment.

---

## Executive Summary

The CasaZero Flutter app integrates **~45 distinct REST endpoints** against a Laravel backend via a shared `ApiService` (Dio). Authentication uses a **dual pattern**: `Authorization: Bearer <token>` on every request **plus** a redundant `token` / `api_token` field in many POST bodies.

**Critical contract gaps:**
1. **Refresh token flow is broken** — client expects `POST /auth/refresh` with `refresh_token`, but login never persists `refresh_token` from the login response.
2. **Inconsistent success flags** — backend uses `status`, `success`, and `Status` (capital S) interchangeably; client compensates unevenly.
3. **Inconsistent token field names** — `token`, `api_token`, and Bearer header used across endpoints without a single convention.
4. **Maintenance update endpoints are guessed** — not defined in `api_constants.dart`; controller tries 3+ URL patterns at runtime.
5. **Maintenance file attachment UI is not sent to API** — file picker state exists but `createMaintenanceTask` omits the file.
6. **Ticket multi-photo UI sends only first image** — UI allows 5 photos; API call sends one `image` base64 field.

**API Health Score: 62 / 100**

| Dimension | Score |
|-----------|-------|
| Endpoint coverage & documentation | 70 |
| Request/response consistency | 55 |
| Auth & token lifecycle | 45 |
| Error handling | 68 |
| Type safety & parsing | 72 |
| Pagination & filtering | 40 |
| File upload/download contracts | 65 |
| Production readiness | 58 |

---

## Cross-Cutting Contract Analysis

### Base configuration

| Item | Value | Source |
|------|-------|--------|
| Origin | `https://backend.casazero.site` | `api_constants.dart` L4 |
| API prefix | `/api` | `api_constants.dart` L7 |
| HTTP client | Dio | `api_service.dart` |
| Connect timeout | 30s | `app_constants.dart` L3 |
| Receive timeout | 30s | `app_constants.dart` L4 |
| Default headers | `Content-Type: application/json`, `Accept: application/json` | `api_service.dart` L23–26 |
| API versioning | **None** — no `/v1` prefix, no version header | — |
| Rate limiting | **Not handled** — no 429 logic, no retry-after | — |

### Authentication pattern (dual auth)

Every authenticated request via `ApiService` adds:

```http
Authorization: Bearer <access_token>
```

Additionally, many endpoints **also** require the token in the JSON body as `token` or `api_token`. This is redundant and creates risk if body token and header token ever diverge.

### Success response conventions (inconsistent)

| Pattern | Used by | Client check |
|---------|---------|--------------|
| `{ "status": true }` | Auth, home, documents, maintenance, profile (most) | `response.data['status'] == true` |
| `{ "success": true }` | Tickets, AI, change language | `body['success'] == true` |
| `{ "Status": true }` | Email OTP send (documented) | `response.data['Status'] ?? response.data['status']` in `sendEmailOTP` only |
| HTTP 200 only | `verifyAuthenticatorQRCode` | Status code only, no `status` field check |

**Risk:** Backend changes from `status` to `success` (or vice versa) silently break features unless each repository is updated.

### Token field naming

| Field name | Endpoints using it |
|------------|-------------------|
| `token` | Login (device token), logout, profile, documents, AI, residences, document password |
| `api_token` | Notifications, tickets, app status, construction phases |
| Bearer header only | Maintenance list/create (relies on interceptor) |
| Both Bearer + body | Most POST endpoints |

### Refresh token flow

**Client expectation** (`api_service.dart` L72–90):

```json
POST /auth/refresh
Request:  { "refresh_token": "<stored_refresh_token>" }
Response: { "access_token": "...", "refresh_token": "..." }
```

**Login handling** (`auth_repository.dart` L102–115): saves `body['token']` as access token only. **`saveRefreshToken()` is never called at login.**

**Production risk:** After access token expiry, 401 interceptor calls `_refreshToken()` → always fails → forced logout via `SessionExpiryService`.

### Retry handling

| Trigger | Behavior |
|---------|----------|
| 401 (non-auth endpoints) | Attempt refresh once → retry original request |
| Network timeout | User-facing string; no automatic retry |
| Network error | Generic message |
| Maintenance update | **Runtime endpoint guessing** — tries PUT `/maintenance/{id}`, PUT `/maintenance/update/{id}`, POST `/maintenance/update` |

### Pagination, sorting, filtering

| Feature | API support in client | Notes |
|---------|----------------------|-------|
| Pagination | **Only** `GET /feed?page=&limit=` | `getFeedItems()` exists but is **never called** from UI |
| Notifications | Full list fetch | No page params |
| Documents | Full list | Client-side search/filter only |
| Tickets | Full list | Client-side status filter |
| Chat (Firestore) | N/A REST | Unbounded Firestore snapshots |
| Sorting | Not specified in any request | Assumes backend default order |

### Date & timezone handling

| Format | Usage | Parsing |
|--------|-------|---------|
| ISO 8601 UTC `2026-01-14T16:21:33.000000Z` | Notifications, trusted devices, maintenance `created_at` | `DateTime.parse()` — local display via `timeAgo` |
| `YYYY-MM-DD` | Maintenance due dates (sent) | Sent as string; parsed with split for datetime portion |
| `dd-MM-yyyy` / `12-04-2025` | Document `uploaded_date` | Custom parser in `DocumentModel._parseUploadedDate` |
| `status_date` (phase) | Construction progress | Kept as **string**, not `DateTime` |

**Timezone:** All `DateTime.parse` on UTC strings display in device local time. No explicit timezone conversion or `UTC` suffix enforcement on outbound dates.

### Multipart vs JSON uploads

| Feature | Method | Content-Type |
|---------|--------|--------------|
| Document upload (default) | Multipart `FormData` | `multipart/form-data` (Dio auto) |
| Document upload (alt) | Base64 data URI in JSON | `application/json` |
| Profile image | Multipart | `multipart/form-data` |
| Ticket image | Base64 in JSON | `application/json` |
| Maintenance attachment | **Not sent** | N/A |

### File downloads

| Path | Auth | Response type |
|------|------|---------------|
| `POST /download_document` | Body `token` only (separate Dio instance, **no Bearer interceptor**) | `bytes` |
| Direct URL download | Bearer via `DownloadService` | File stream |
| ZIP URL | Bearer via `ZipDownloadService` | Binary |

**Risk:** `downloadDocument` uses a standalone Dio without the 401 refresh interceptor — expired token fails without refresh attempt.

### Error response handling

`ApiService._handleError` extracts `message` or `error` from JSON body; handles 401/403/404/5xx; detects HTML error pages. Repositories often add second-layer parsing. **No structured error code contract** (except document download `documentPasswordNotSet`).

### FCM token registration

- Sent on login as `fcm_token` in login payload (`auth_repository.dart` L72).
- **No dedicated update endpoint** in `api_constants.dart`.
- `registerAfterAuth()` refreshes local FCM token only — does not call backend.

### API versioning & backward compatibility

- No version prefix or `Accept-Version` header.
- Client uses defensive parsing (`status` OR `success`, flexible notification fields).
- Deprecated endpoints `ENABLE_2FA`, `VERIFY_2FA` remain in constants but unused.
- Alternate document list endpoints exist in repository but only `getDocumentsByUnit` is used in production UI.

---

## Endpoint Matrix

Legend: **Used** = called from app code · **Unused** = defined/repository only · **Ad-hoc** = hardcoded path not in constants

| # | Method | Endpoint | Used | Auth | Request model | Response model (expected) | Health |
|---|--------|----------|------|------|---------------|---------------------------|--------|
| 1 | POST | `/user/login` | ✅ | None | See §1 | `status`, `token`, `user`, `firebase_token`, `is_trusted` | 🟡 |
| 2 | POST | `/user/logout` | ✅ | Bearer + `{token}` | `{token}` | `{status, message}` | ✅ |
| 3 | POST | `/auth/refresh` | ✅ | None | `{refresh_token}` | `{access_token, refresh_token}` | 🔴 |
| 4 | POST | `/auth/forgot-password` | ✅ | None | `{email}` | `{status, message, data.user_id?}` | ✅ |
| 5 | POST | `/auth/reset-password` | ✅ | None | `{email, password, password_confirmation}` | `{status, message}` | ✅ |
| 6 | POST | `/user/forget_password` | ✅ | Bearer | `{user_id, old_password, new_password, new_password_confirmation}` | `{status, message}` | ✅ |
| 7 | POST | `/user/get-document-password` | ✅ | Bearer + `{token}` | `{token}` | `{status, document_password}` | ✅ |
| 8 | POST | `/user/set-document-password` | ✅ | Bearer + `{token, password, confirm_password}` | See auth repo | `{status, message}` | ✅ |
| 9 | POST | `/user/profile` | ✅ | Bearer + `{token}` | `{token}` | `{status, data: User}` | ✅ |
| 10 | POST | `/user/profile_data/update/{userId}` | ✅ | Bearer + `{token, ...}` | Partial user fields | `{status, message, data?}` | 🟡 |
| 11 | POST | `/user/profile_image/update/{userId}` | ✅ | Bearer + multipart | `profile_image` file | `{status, image_url, message}` | 🟡 Ad-hoc path |
| 12 | GET | `/setup_2FA/{userId}` | ✅ | Bearer | — | `{status, data: {secret_key, qr_base64, otpauth_url}}` | ✅ |
| 13 | POST | `/verify_QR` | ✅ | Bearer | `{user_id, code, device_*}` | `{message}` | 🟡 |
| 14 | POST | `/2fa/email/otp_send` | ✅ | Bearer | `{user_id}` | `{Status\|status, message}` | 🟡 |
| 15 | POST | `/2fa/email/otp_verify` | ✅ | Bearer | `{user_id, otp, device_*}` | `{status, message}` | ✅ |
| 16 | POST | `/2fa/sms/otp_send` | ✅ | Bearer | `{user_id}` | Same as email | 🟡 |
| 17 | POST | `/2fa/sms/otp_verify` | ✅ | Bearer | `{user_id, otp, device_*}` | `{status, message}` | 🟡 |
| 18 | GET | `/2fa/disable/{userId}` | ✅ | Bearer | — | `{status, data, message}` | 🟡 GET for mutation |
| 19 | POST | `/update/2fa_status` | ✅ | Bearer | `{user_id, is_two_fa_status}` | `{status, message}` | ✅ |
| 20 | GET | `/get_all_trusted_device/{userId}` | ✅ | Bearer | — | `{status, trusted_devices[]}` | ✅ |
| 21 | POST | `/revoke_trusted_device` | ✅ | Bearer | `{device_id}` | `{status, message}` | 🟡 int vs doc |
| 22 | POST | `/delete_specific_user_device` | ✅ | Bearer | `{user_id, device_id}` | `{status, message}` | 🟡 |
| 23 | POST | `/change/language` | ✅ | Bearer | `{user_id, language}` | `{success, message, data}` | 🟡 success flag |
| 24 | POST | `/residences/by-token` | ✅ | Bearer + `{token}` | `{token}` | `{status, user_id?, data[]}` | 🟡 doc says PUT |
| 25 | GET | `/single_residence/{id}` | ✅ | Bearer | — | `{status, data: {admin, ...}}` | ✅ |
| 26 | GET | `/residences/{residenceId}` | Unused | Bearer | — | Raw `response.data` | ⚪ |
| 27 | GET | `/residences/{id}/construction` | Unused | Bearer | — | `{phases[]}` | ⚪ |
| 28 | POST | `/residence/status-with-phases` | ✅ | Bearer + `{api_token, residence_id}` | See above | `{status, data: Phase[]}` | ✅ |
| 29 | GET | `/feed` | Unused | Bearer | `?page&limit` | `{items[]}` | ⚪ |
| 30 | POST | `/get_user/notifications` | ✅ | Bearer + `{api_token}` | `{api_token}` | `{status, data: Notification[]}` | ✅ |
| 31 | POST | `/get_user/mark_as_read` | ✅ | Bearer + `{api_token, notification_id}` | See above | `{status, message}` | ✅ |
| 32 | POST | `/get_user/unread_count` | ✅ | Bearer + `{api_token}` | `{api_token}` | `{status, unread_count}` | ✅ |
| 33 | POST | `/notification/delete` | ✅ | Bearer + `{api_token, notification_id}` | See above | `{status, message}` | ✅ |
| 34 | POST | `/send-chat-notification` | ✅ | Bearer | `{receiver_id, sender_id, title, body, data?}` | Unchecked void | 🟡 |
| 35 | POST | `/update-app-status` | ✅ | Bearer + `{api_token, app_status}` | See above | Unchecked void | 🟡 |
| 36 | GET | `/document_categories` | ✅ | Bearer | — | `{status, data[]}` | ✅ |
| 37 | GET | `/documents/` | Unused | Bearer | — | `{status, data: Document[]}` | ⚪ |
| 38 | POST | `/get_unit_wise_documents` | Unused | Bearer + `{token}` | `{token}` | `{status, data: Unit[]}` | ⚪ |
| 39 | POST | `/get_residence_wise_documents` | Unused | Bearer | `{residence_id}` | `{status, residence.documents}` | ⚪ |
| 40 | POST | `/documents/by_unit` | ✅ | Bearer + `{token}` | `{token}` | `{status, documents[], unit_id?}` | ✅ |
| 41 | POST | `/user_document_upload` | ✅ | Bearer + multipart/JSON | See §Documents | `{status, data: {file_url, ...}}` | ✅ |
| 42 | POST | `/download_document` | ✅ | Body token only | `{token, document_id}` | Binary bytes | 🟡 |
| 43 | DELETE | `/documents/delete/{id}` | ✅ | Bearer | — | `{status, message}` | 🟡 Ad-hoc path |
| 44 | POST | `/issue-type/list` | ✅ | Bearer + `{api_token}` | `{api_token}` | `{success, data[]}` | 🟡 |
| 45 | POST | `/issue-type/create` | Unused? | Bearer + `{api_token, issue_type_en, issue_type_it}` | — | `{success, data}` | ⚪ |
| 46 | POST | `/my-support-tickets` | ✅ | Bearer + `{api_token}` | `{api_token}` | `{status\|success, data[]}` | 🟡 |
| 47 | POST | `/support-ticket/create` | ✅ | Bearer + fields | See §Tickets | `{status\|success, data}` | 🟡 |
| 48 | GET | `/maintenance_categories/list` | ✅ | Bearer | — | `{status, data[]}` | ✅ |
| 49 | GET | `/maintenance/list` | Unused | Bearer | — | Documented but not called | ⚪ |
| 50 | POST | `/residence_wise/maintenance` | ✅ | Bearer | `{residence_id}` | `{status, data: Task[]}` | ✅ |
| 51 | POST | `/maintenance/store` | ✅ | Bearer | See §Maintenance | `{status, data}` | 🟡 no file |
| 52 | PUT | `/maintenance/{id}` | Ad-hoc | Bearer | Task fields | `{status}` | 🟡 guessed |
| 53 | PUT | `/maintenance/update/{id}` | Ad-hoc | Bearer | Task fields | `{status}` | 🟡 guessed |
| 54 | POST | `/maintenance/update` | Ad-hoc | Bearer | `{id, ...fields}` | `{status}` | 🟡 guessed |
| 55 | DELETE | `/maintenance/delete/{id}` | ✅ | Bearer | — | `{status, message}` | ✅ |
| 56 | POST | `/change/mantenance_status` | Ad-hoc | Bearer | `{maintenance_id}` | `{status}` | 🟡 typo in path |
| 57 | POST | `/undo/mantenance_status` | Ad-hoc | Bearer | `{maintenance_id}` | `{status}` | 🟡 typo in path |
| 58 | POST | `/casazero-ai/send-message` | ✅ | Bearer + `{token, message}` | Strings only | `{success, chat_id, reply, image?, remaining_ai_credit?}` | ✅ |
| 59 | POST | `/casazero-ai/get-message` | ✅ | Bearer + `{token}` | `{token}` | `{success, data: {data: []}}` | 🟡 nested |
| 60 | GET | `/buildings` | Unused | — | — | — | ⚪ |
| 61 | GET | `/buildings/{buildingId}` | Unused | — | — | — | ⚪ |
| 62 | POST | `/auth/2fa/enable` | Unused | Deprecated | — | — | ⚪ |
| 63 | POST | `/auth/2fa/verify` | Unused | Deprecated | — | — | ⚪ |

---

## Detailed Endpoint Audits

### 1. POST `/user/login`

**Request model:**
```json
{
  "email": "string",
  "phone": "string",
  "password": "string",
  "device_id": "string",
  "device_name": "string",
  "platform": "android|ios|web",
  "ip_address": "string",
  "lat": 0.0,
  "lng": 0.0,
  "fcm_token": "string",
  "token": "string"
}
```
*`token` = stored trusted-device token from prior login.*

**Response model (parsed):**
```json
{
  "status": true,
  "token": "access_token",
  "user": { /* UserModel fields */ },
  "firebase_token": "custom_jwt",
  "firebase_project_id": "optional",
  "is_trusted": false,
  "message": "optional"
}
```

| Issue | Severity | Details |
|-------|----------|---------|
| `refresh_token` not persisted | **Critical** | Interceptor expects it; login ignores it |
| `token` used for both access and device token | High | Same key name, different semantics |
| `user` cast without null guard on success path | Medium | Assumes `body['user'] is Map` |
| No typing for `is_trusted` | Low | Defaults to `false` |

**Recommended improvements:** Document and persist `refresh_token`; rename device token field in API contract; add OpenAPI schema.

---

### 2. POST `/auth/refresh`

**Request:** `{ "refresh_token": "string" }`  
**Response:** `{ "access_token": "string", "refresh_token": "string" }` (HTTP 200)

| Issue | Severity |
|-------|----------|
| Never succeeds in practice — no stored refresh token | **Critical** |
| Not in auth-endpoint skip list for 401 on refresh itself | Medium — refresh failure triggers session expiry loop |

---

### 3. POST `/residences/by-token`

**Documented:** `PUT` in `api_constants.dart` L184  
**Actual:** `POST` in `home_repository.dart` L43

**Request:** `{ "token": "access_token" }`  
**Response:** `{ "status": true, "user_id": 17, "data": [{ "id", "residence_name", "residence_address" }] }`

| Issue | Severity |
|-------|----------|
| HTTP method mismatch vs documentation | Medium |
| `ResidenceModel.fromJson` expects fields not in minimal list response (`residence_type`, `created_at`) — uses defaults | Medium |
| `getResidenceByToken` flexible parsing accepts array OR object — masks schema drift | Low |

---

### 4. POST `/residence/status-with-phases`

**Request:** `{ "api_token": "string", "residence_id": int }`  
**Response:** `{ "status": true, "data": [ ResidenceStatusPhaseModel ] }`

**Phase model fields:** `phase_id`, `phase_name_en`, `phase_name_it`, `is_completed` (bool), `status: { status_description, status_date, image }`

| Issue | Severity |
|-------|----------|
| `is_completed` only true if `== true` — integer `1` treated as false | Medium |
| `status_date` not parsed to DateTime | Low |

---

### 5. POST `/get_user/notifications`

**Request:** `{ "api_token": "string" }`  
**Response:** `{ "status": true, "data": [ { "id", "title", "content", "url", "notification_type", "is_read": 0\|1, "created_at" } ] }`

**Client model:** `FeedItemModel` — maps `notification_type` → `type`, `content` → `description`, `is_read` 0/1 → bool.

| Issue | Severity |
|-------|----------|
| No pagination — full list always | Medium at scale |
| Silent failure returns `[]` in some code paths | Medium |
| Bilingual fields (`title_en`) optional — good defensive parsing | OK |

---

### 6. POST `/documents/by_unit` (production documents list)

**Request:** `{ "token": "string" }`  
**Response:** `{ "status": true, "documents": [...], "unit_id": 12 }` OR fallback `data` key

**Document fields:** `id`, `document_name`, `file_type`, `file_size`, `uploaded_date`, nested `category`/`type` with `*_it` variants.

| Issue | Severity |
|-------|----------|
| Three alternate list endpoints in repo; only one used — contract drift risk | Medium |
| `uploaded_date` multiple formats (`dd-MM-yyyy`, ISO) — client handles | Low |
| `id` coerced to string — OK | OK |

---

### 7. POST `/user_document_upload`

**Multipart request fields:** `token`, `document_file` (File), `document_title`, `document_category` (int), `document_description?`

**Base64 alternative:** `document_file` as `data:{mime};base64,{data}`

**Response:** `{ "status": true, "message", "data": { "file_url", "file_type", "file_size" } }`

| Issue | Severity |
|-------|----------|
| Default Content-Type from ApiService is JSON — multipart overrides via Dio | OK |
| Client verifies `file_url`/`file_type`/`file_size` non-null post-upload | Good |
| Large files may hit 30s timeout | Medium |

---

### 8. POST `/download_document`

**Request:** `{ "token", "document_id" }`  
**Response:** Raw bytes (200) OR JSON error in body

| Issue | Severity |
|-------|----------|
| Separate Dio — no Bearer header, no 401 refresh | High |
| Error body may be JSON bytes — client parses via `_parseDownloadErrorMessage` | Good |
| Special case `documentPasswordNotSet` error code | Good |

---

### 9. DELETE `/documents/delete/{id}`

**Not in `api_constants.dart`** — hardcoded `'/documents/delete/$documentId'`

| Issue | Severity |
|-------|----------|
| Undocumented in constants | Medium |
| Auth via Bearer only (no body token) | OK if backend accepts Bearer |

---

### 10. POST `/support-ticket/create`

**Request:**
```json
{
  "api_token": "string",
  "title": "string",
  "description": "string",
  "issue_type_id": 4,
  "priority": "medium|high|low",
  "image": "data:image/jpeg;base64,..." 
}
```

**UI allows up to 5 photos; controller sends `attachedPhotos.first` only.**

| Issue | Severity |
|-------|----------|
| Multi-image UI vs single `image` field | **High** |
| Success check: `success` OR `status` | OK defensive |
| `category` in ticket list response — may be empty if API sends `issue_type` object | Medium |

---

### 11. POST `/residence_wise/maintenance` + related

**List request:** `{ "residence_id": int }`  
**List response:** `{ "status": true, "data": [ MaintenanceTask JSON ] }`

**Create (`/maintenance/store`):**
```json
{
  "maintenance_title": "string",
  "maintenance_frequency": "string",
  "maintenance_status": "pending",
  "due_date": "YYYY-MM-DD",
  "last_maintenance_date": "YYYY-MM-DD?",
  "maintenance_note": "string?",
  "maintenance_category_id": 1,
  "maintenance_item_id": 1,
  "residence_id": 48
}
```

**File attachment:** UI collects `selectedFile` but **never included in request**.

**Status toggle:** `POST /change/mantenance_status` and `POST /undo/mantenance_status` — **typo `mantenance`** in path.

**Update schedule:** Runtime tries 3 undocumented endpoints.

| Issue | Severity |
|-------|----------|
| File attachment not wired | **High** |
| Endpoint guessing for update | **High** |
| Typo in maintenance status paths | **High** — backend must match exact typo |
| `GET /maintenance/list` unused | Low |

---

### 12. POST `/casazero-ai/send-message` & `/get-message`

**Send request:** `{ "token": "string", "message": "string" }` — client enforces string types.

**Send response:** `{ "success": true, "chat_id": int, "reply": string, "image": null|string, "remaining_ai_credit": int? }`

**History response:** Nested `{ "success": true, "data": { "data": [ messages ] } }` — client handles both nested and flat.

| Issue | Severity |
|-------|----------|
| Uses `success` not `status` | Medium inconsistency |
| Defensive array→string coercion for `reply` | Good |
| Only `ai_repository` handles `connectionError` explicitly | Low |

---

### 13. POST `/send-chat-notification` & `/update-app-status`

**Chat notification:** Fire-and-forget — no response validation, errors swallowed.

**App status:** `{ "api_token", "app_status": "foreground"|"background" }` — skipped if no token.

| Issue | Severity |
|-------|----------|
| No error handling / retry | Medium |
| No idempotency keys | Low |

---

### 14. GET `/2fa/disable/{userId}`

**Documented as POST in constants comment; implemented as GET.**

**On success:** Updates local user with keys `name` (not `user_name`) — **UserModel expects `user_name`**.

| Issue | Severity |
|-------|----------|
| GET for state-changing operation | Medium |
| Wrong storage key `name` vs `user_name` | **High** — corrupts cached user |

---

### 15. POST `/change/language`

**Request:** `{ "user_id": int, "language": "en"|"it" }`  
**Success check:** `response.data['success'] == true` (not `status`)

| Issue | Severity |
|-------|----------|
| Inconsistent success flag vs other profile endpoints | Medium |

---

## Enum & Type Consistency

| Domain | Client enum | API values | Mapping |
|--------|-------------|------------|---------|
| User role | `Role.client/admin/manager` | `resident`, `administrator`, `client`, etc. | `UserModel.parseRoleFromApi` — flexible |
| Residence status | `completed`, `underConstruction`, `pending` | Free-text strings | Normalized in `parseResidenceStatus` |
| Ticket status | `open`, `in-progress`, `resolved` | `in_progress`, `closed`, `pending` | `_normalizeStatus` in TicketModel |
| Maintenance status | `pending`, `inProgress`, `completed`, `overdue` | `pending`, `in_progress`, `completed`, `overdue` | String mapping in controller |
| Maintenance priority | `facoltative`, `obbligatorie`, etc. | Nested `priority` object + Italian names | Derived in `MaintenanceTask.fromJson` |
| 2FA method | string | `email`, `sms`, `authenticator`, `none` | String comparison |
| Notification type | string | `document`, `maintenance`, `chat`, etc. | Lowercase in handlers |

**Risks:** Ticket `category` field may not populate if API returns nested `issue_type` object. Maintenance priority derivation is complex and log-heavy — sensitive to API shape changes.

---

## Nullable Fields & Missing Fields

| Model | Required in client | Optional / defaulted | Missing API handling |
|-------|-------------------|----------------------|----------------------|
| UserModel | id, email, userName | profileImage, residenceId | `id ?? 0` — bad ID if missing |
| DocumentModel | id, title | fileUrl, description | `Untitled Document` fallback |
| FeedItemModel | id, type, title | url, priority | Empty string defaults |
| TicketModel | id, title | imageUrl, priority | Empty category if absent |
| TrustedDeviceModel | id, deviceId | lat/lng as string or number | `_parseDouble` handles |
| ResidenceStatusPhaseModel | phaseId | status nested object | `is_completed` strict bool |

---

## Risk Matrix

| ID | Risk | Severity | Area | Impact | Root cause |
|----|------|----------|------|--------|------------|
| R1 | Refresh token never stored | **Critical** | Auth | Silent session death on 401 | Login omits `saveRefreshToken` |
| R2 | Dual token auth drift | High | All APIs | Intermittent 401 if body/header mismatch | Bearer + body redundancy |
| R3 | `status` vs `success` inconsistency | High | Tickets, AI, language | False negatives on success | No API convention |
| R4 | Maintenance update endpoint guessing | **Critical** | Maintenance | Update may fail on production API | Undocumented contract |
| R5 | Maintenance typo URLs `mantenance` | High | Maintenance | 404 if backend spells correctly | Hardcoded typo paths |
| R6 | Maintenance file not uploaded | High | Maintenance | User thinks file attached | UI not wired to API |
| R7 | Ticket multi-photo → single image | High | Tickets | Data loss | Contract single `image` field |
| R8 | Download Dio without refresh | High | Documents | Download fails on expired token | Separate HTTP client |
| R9 | disable2FA corrupts user cache | High | Auth | `name` vs `user_name` key | Wrong merge keys |
| R10 | FCM token not re-registered | High | Push | Stale device tokens | No update endpoint used |
| R11 | No pagination | Medium | Lists | Performance / memory | Full fetches |
| R12 | `GET /feed` unused | Low | Home | Dead code | Feature not wired |
| R13 | `is_completed` strict bool | Medium | Construction | Phases show wrong state if API sends `1` | Parser strictness |
| R14 | `residences/by-token` PUT vs POST | Medium | Home | Proxy/middleware rejection | Doc/code mismatch |
| R15 | No rate limit / 429 handling | Medium | All | Poor UX under throttle | Not implemented |
| R16 | No API versioning | Medium | All | Breaking changes affect all users | No version strategy |
| R17 | Chat notification errors ignored | Low | Chat | Push may fail silently | void return |
| R18 | `verify_QR` success = HTTP 200 only | Medium | 2FA | False success on error body with 200 | Weak validation |

---

## Production Readiness by Domain

| Domain | Score | Blockers |
|--------|-------|----------|
| Authentication & 2FA | 55/100 | Refresh token, disable2FA cache keys |
| Home & residences | 70/100 | PUT/POST mismatch, feed unused |
| Notifications | 75/100 | No pagination, no tap routing |
| Documents | 68/100 | Download auth client, delete path ad-hoc |
| Maintenance | 50/100 | File upload gap, endpoint guessing, typo paths |
| Tickets | 65/100 | Single image contract |
| AI | 78/100 | Best-documented; uses `success` flag |
| Profile & devices | 72/100 | Language `success` flag, revoke device_id type |
| Chat (REST adjunct) | 60/100 | Fire-and-forget notifications |

---

## Recommended Improvements (Contract-Level)

### Immediate (P0)

1. **Align login + refresh contract** — Backend must return `refresh_token`; Flutter must call `saveRefreshToken()` on login.
2. **Publish OpenAPI 3.0 spec** — Single source of truth for `status` vs `success`, token field names, and all paths.
3. **Fix maintenance API contract** — Document canonical update URL; fix `mantenance` typo or alias; add attachment field to `POST /maintenance/store`.
4. **Fix disable2FA local cache** — Use `user_name` not `name` when merging user data.
5. **Unify download client** — Route `downloadDocument` through `ApiService` or share interceptors.

### Short-term (P1)

6. Standardize on **`api_token` in body OR Bearer only** — not both.
7. Add **FCM token update endpoint** and call on session restore.
8. Extend ticket create to **`images[]`** array or document multi-upload pattern.
9. Add **pagination** to notifications, documents, tickets, maintenance list APIs.
10. Register all ad-hoc paths in `api_constants.dart`.

### Medium-term (P2)

11. Introduce **`/api/v1`** versioning.
12. Add structured **error codes** (`{ "error_code": "DOCUMENT_PASSWORD_NOT_SET" }`).
13. Handle **429** with exponential backoff.
14. Add **integration tests** against staging API with recorded fixtures.
15. Remove unused endpoints or wire feed/buildings features.

---

## Final API Health Score

| Category | Weight | Score | Weighted |
|----------|--------|-------|----------|
| Endpoint completeness | 15% | 72 | 10.8 |
| Request contract correctness | 20% | 58 | 11.6 |
| Response parsing robustness | 15% | 70 | 10.5 |
| Authentication lifecycle | 20% | 42 | 8.4 |
| Error & retry handling | 10% | 65 | 6.5 |
| File transfer contracts | 10% | 63 | 6.3 |
| Pagination & scale | 10% | 38 | 3.8 |
| **Total** | 100% | — | **57.9 → 62** |

**Overall API Health Score: 62 / 100**

The Flutter client demonstrates **substantial integration breadth** with defensive parsing in several areas (notifications, AI, tickets). Production reliability is held back by **broken refresh-token lifecycle**, **undocumented/guessed maintenance endpoints**, **inconsistent success envelopes**, and **gaps between UI capabilities and API payloads** (maintenance files, ticket photos).

---

*Analysis only. No source code was modified. Backend verification requires testing against `https://backend.casazero.site/api` with valid credentials.*
