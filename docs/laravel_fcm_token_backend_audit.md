# CasaZero — Laravel Backend FCM Token Audit

**Date:** 30 Jul 2026  
**Type:** Audit only — **no code was modified**  
**Backend host:** `https://backend.casazero.site` (Laravel **v11.46.1**, PHP **8.2.30**)  
**Scope:** FCM token registration / update suitability for Flutter Phase 1–2 follow-on  

### Evidence limitation (read first)

The Laravel application source is **not present** in the `casazero` Flutter repository (no `routes/api.php`, `AuthController.php`, `LoginRequest.php`, migrations, or Firebase service classes were found under `d:\Sajid` or this workspace).

This audit is therefore based on:

1. **Live HTTP probes** against `backend.casazero.site` (route existence + validation behavior).
2. The **Flutter API contract** (`lib/core/constants/api_constants.dart`, repositories, models).
3. Prior written audits in-repo (`API_CONTRACT_AUDIT_REPORT.md`, `FIREBASE_PRODUCTION_AUDIT_REPORT.md`, notification docs).

Where source filenames are recommended below, they follow **standard Laravel 11 layout** and error strings returned by the live API (e.g. `App\Models\User`). Exact paths may differ on the server.

---

## Verdict

| Question | Answer |
|----------|--------|
| Is there already an endpoint suitable for updating the user’s FCM token after login? | **No** |
| Does login accept / persist `fcm_token`? | **Yes** (optional; not required by validation) |
| Can profile update be reused safely for FCM? | **Not suitable** as designed today |
| Recommended path | Add minimal **`POST /api/update-fcm-token`** |

---

## 1. Current architecture (inferred)

```
Flutter app
  │
  ├─ POST /api/user/login { ..., fcm_token?, device_id, ... }
  │     → Laravel Auth / Login flow
  │     → Persist FCM token (likely users.fcm_token and/or device row)
  │
  ├─ POST /api/user/profile_data/update/{user_id}
  │     → Profile fields + notification preference flags only (client)
  │     → Does NOT send fcm_token today
  │
  ├─ POST /api/send-chat-notification
  │     → Intended to trigger FCM send (client exists; live route looks broken — see §2)
  │
  ├─ POST /api/update-app-status
  │     → Client calls; live API → 404 (route missing)
  │
  └─ (missing) POST /api/update-fcm-token
        → Needed for onTokenRefresh / late iOS token / session restore
```

**Push targeting model (from client + prior audits):** per-device / per-user FCM registration token stored by Laravel at login, then used when sending pushes (documents, tickets, chat, etc.). Flutter does **not** subscribe to FCM topics.

**Auth style:** Many endpoints accept a body field `token` / `api_token` (user API token), sometimes in addition to Bearer. Login returns `token` (access) + `user` + optional `firebase_token` (Firebase Auth custom JWT — unrelated to FCM).

---

## 2. Existing endpoints (FCM-relevant)

### Live probe results (30 Jul 2026)

| Method | Path | Live result | Interpretation |
|--------|------|-------------|----------------|
| POST | `/api/user/login` | Exists | Validation + business logic (`User not found` after validation) |
| POST | `/api/user/profile` | Exists | `401 Invalid or expired token` with bad token |
| POST | `/api/user/profile_data/update/{id}` | Exists | Hits `App\Models\User` (`No query results for model [App\Models\User] 1`) |
| POST | `/api/send-chat-notification` | **200 HTML** Laravel welcome page | Route **not** registered as a proper API JSON endpoint (or catches web fallback) |
| POST | `/api/update-app-status` | **404** Not Found | Route missing (matches Flutter runtime logs) |
| POST | `/api/update-fcm-token` | **404** | Missing |
| POST | `/api/update_fcm_token` | **404** | Missing |
| POST | `/api/user/update-fcm-token` | **404** | Missing |
| POST | `/api/user/fcm-token` | **404** | Missing |
| POST | `/api/fcm-token` | **404** | Missing |

### Endpoints known to the Flutter client (notification / user)

| Constant | Path | Role vs FCM token |
|----------|------|-------------------|
| `LOGIN` | `POST /user/login` | **Only write path for `fcm_token` today** |
| `LOGOUT` | `POST /user/logout` | Session end; client also deletes local FCM token |
| `GET_USER_PROFILE` | `POST /user/profile` | Read profile — `UserModel` has **no** `fcm_token` field |
| `UPDATE_USER_PROFILE` | `POST /user/profile_data/update/{user_id}` | Updates name/email/phone/language/notify flags — **no `fcm_token` in client body** |
| `SEND_CHAT_NOTIFICATION` | `POST /send-chat-notification` | Send push (outbound); not a token updater |
| `UPDATE_APP_STATUS` | `POST /update-app-status` | FG/BG gating; **404 on server**; not token updater |
| In-app feed | `/get_user/notifications`, unread, mark read, delete | Feed only |

**Conclusion:** Among existing routes, **only login** is a documented, live, working writer for `fcm_token`. No dedicated or reusable update endpoint exists on the live API.

---

## 3. Login endpoint & validation (`fcm_token`)

### Request shape (Flutter → Laravel)

```json
{
  "email": "string",
  "phone": "string",
  "password": "string",
  "device_id": "string",          // required (validated)
  "device_name": "string",
  "platform": "android|ios|web",
  "ip_address": "string",
  "lat": 0.0,
  "lng": 0.0,
  "token": "string",              // trusted-device token (optional / prior)
  "fcm_token": "string"           // OPTIONAL — omitted by Flutter when unavailable (Phase 1)
}
```

### Live validation behavior

| Payload | Result |
|---------|--------|
| `{}` | `422` Validation Error — `device_id` required (`"The device id field is required."`) |
| Full device fields, **no** `fcm_token` | Past validation → `404` `"User not found."` |
| Same + `"fcm_token": ""` | Same — **empty string accepted** (not rejected) |
| Same + `"fcm_token": "test-token"` | Same — **non-empty accepted** |

**Inferences about `LoginRequest` (or equivalent FormRequest):**

- `device_id` is **required**.
- `fcm_token` is **not required** (`nullable` / `sometimes` / absent from rules).
- Empty string is **not** blocked by validation today (so historical Flutter `fcm_token: ''` would not fail login — it may still overwrite a good DB token with blank depending on server code).

### AuthController / login handler (inferred responsibilities)

From Flutter success parsing and API contract docs, login likely:

1. Validates credentials + device metadata.
2. Issues / returns API `token`.
3. Upserts trusted device (`device_id`, name, platform, geo).
4. **Stores `fcm_token` when present** (user and/or device record).
5. Returns `user`, optional `firebase_token` (Firebase Auth custom token), `is_trusted`.

Exact method names (`login`, `userLogin`, etc.) cannot be confirmed without source.

---

## 4. User model & where `fcm_token` is stored

### Flutter `UserModel`

Does **not** include `fcm_token`. Profile responses are not used as the source of truth for the push token on the client.

Notification preference columns **are** modeled and updated via profile:

- `is_document_notify`
- `is_maintenance_notify`
- `is_chat_notify`
- `is_support_ticket_notify`

### Database (inferred — confirm on Laravel)

Live error references `App\Models\User`. Given login always sends `device_id` **and** `fcm_token`, storage is likely one of:

| Hypothesis | Likelihood | Notes |
|------------|------------|-------|
| A. `users.fcm_token` (single column) | High | Simple; last-login device wins; multi-device weak |
| B. `user_devices` / `trusted_devices` row with `fcm_token` keyed by `device_id` | High | Matches required `device_id` at login |
| C. Both A and B | Medium | User column = “primary”; devices table = multi-device |

**Prior audit language** (“per-device `fcm_token` on login”) favors **B or C**. The update endpoint should therefore accept **`fcm_token` + `device_id`** (and auth token), not only `fcm_token`, so multi-device users do not clobber each other.

---

## 5. Notification sending / Firebase service

### Client-side send hook

`NotificationRepository.sendChatNotification` → `POST /send-chat-notification` with:

```json
{
  "receiver_id": int,
  "sender_id": int,
  "title": "...",
  "body": "...",
  "data": { ... }
}
```

### Live status

POST returns **HTTP 200 with the default Laravel Blade welcome HTML**, not JSON. That strongly suggests the API route is **missing or mis-registered** (request falls through to the web stack). Treat outbound chat push via this path as **unreliable on production** until the Laravel team confirms the route.

### Other pushes

Document / ticket / maintenance / announcement pushes are almost certainly triggered **server-side** (admin dashboard / observers / jobs), not from the Flutter app. Those paths must read the stored FCM token(s). Without Laravel source, exact classes (`FirebaseService`, `FcmService`, `NotificationService`, Kreait, etc.) cannot be named with certainty.

---

## 6. Profile / user update endpoints — suitability for FCM

### `POST /user/profile_data/update/{user_id}`

**Exists** on the live server. Flutter sends:

- Auth: `token`
- Optional: `user_name`, `email`, `phone`, `language`, `profile_image`
- Notify flags: `is_*_notify`
- Optional residence fields

**Why it is not a suitable FCM updater today**

1. Client never sends `fcm_token` — no contract, no tests.
2. Semantics are “edit profile / preferences,” not “device push identity.”
3. Path is scoped by `{user_id}` in the URL — easy to misuse; FCM updates should bind to the **authenticated** user from `token` / `api_token`.
4. Unknown whether the FormRequest `$fillable` / update whitelist would ignore or mass-assign `fcm_token` if added ad hoc.
5. Missing `device_id` in the profile update body → cannot safely target the correct device row if tokens are per-device.

### `POST /user/profile`

Read-only from the client’s perspective (fetch). Not an updater.

### Other candidates

| Endpoint | Suitable for FCM update? |
|----------|---------------------------|
| `/change/language` | No |
| `/user/logout` | Clears session; not a register path |
| `/update-app-status` | Missing (404); different concern |
| `/send-chat-notification` | Send, not register; currently broken |

**Determination:** There is **no existing endpoint suitable** for mid-session FCM token updates. Do **not** overload profile update; add a dedicated route.

---

## 7. Database field (recommended confirmation checklist)

On the Laravel repo / DB, confirm:

```sql
-- Likely candidates (names may vary)
SHOW COLUMNS FROM users LIKE '%fcm%';
SHOW COLUMNS FROM user_devices LIKE '%fcm%';   -- or trusted_devices / devices
SHOW COLUMNS FROM users LIKE '%app_status%';  -- for future update-app-status
```

Also inspect login handler for:

```php
$user->fcm_token = $request->fcm_token;
// and/or
$device->fcm_token = $request->fcm_token;
```

Document the real table/column in the implementation PR.

---

## 8. Validation (current vs recommended)

### Current (login) — observed

| Field | Rule (observed) |
|-------|-----------------|
| `device_id` | required |
| `fcm_token` | optional; empty string allowed |

### Recommended for `POST /update-fcm-token`

| Field | Rule | Reason |
|-------|------|--------|
| `api_token` **or** `token` | required (match existing auth style) | Same as profile / app-status client |
| `fcm_token` | `required\|string\|min:10\|max:4096` | Never persist empty / omit |
| `device_id` | `required\|string` | Align with login; multi-device safety |
| `platform` | `nullable\|in:android,ios,web` | Optional diagnostics |

Reject empty string explicitly (`required` + min length). Do **not** use `nullable` here — the whole point of the endpoint is to set a real token.

Optional hardening:

- Clear the same device’s old token from other users if tokens must be globally unique (FCM tokens can move between accounts on shared devices).
- Rate-limit per user/device.

---

## 9. Best implementation plan (minimal)

### Goal

Allow Flutter to call, after auth, whenever a non-empty FCM token is available:

- late iOS APNs → FCM
- `onTokenRefresh`
- splash / OTP `registerAfterAuth`
- permission grant-after-deny

**without** requiring another password login.

### Recommended API

```http
POST /api/update-fcm-token
Content-Type: application/json

{
  "api_token": "<user access token>",
  "fcm_token": "<non-empty FCM registration token>",
  "device_id": "<same id sent at login>",
  "platform": "ios"   // optional
}
```

**Success (align with existing envelope):**

```json
{
  "status": true,
  "message": "FCM token updated successfully"
}
```

**Errors:** `401` invalid/expired token; `422` validation; `404` device not found (if you require an existing trusted device row).

### Server logic (minimal)

1. Resolve user from `api_token` / `token` (same helper as profile / logout).
2. Validate body (`UpdateFcmTokenRequest`).
3. Upsert FCM token:
   - Prefer: update **device** row matching `(user_id, device_id)`; create if login already created devices.
   - Also set `users.fcm_token` if that column is what senders read today (keep send path working with zero changes).
4. Return `{ status: true, ... }`.
5. Do **not** change notification payload builders in this task.

### Flutter follow-up (out of scope for this audit, but contract must match)

- Add `ApiConstants.UPDATE_FCM_TOKEN = '/update-fcm-token'`.
- Call from `onTokenRefresh`, successful `getDeviceToken` after auth, and permission-grant resume — **only** with non-empty tokens (Phase 1 already guarantees that on the client).

### Explicit non-goals

- Do not implement `/update-app-status` in this ticket (separate; also 404).
- Do not fix `/send-chat-notification` routing unless blocking testing (worth a separate bug).
- Do not change login’s optional `fcm_token` behavior (keep login registration).

---

## 10. Files that must change (Laravel)

Exact tree unknown; expected touch list:

| File / area | Change |
|-------------|--------|
| `routes/api.php` (or `routes/api/*.php`) | Register `POST /update-fcm-token` |
| New `app/Http/Requests/UpdateFcmTokenRequest.php` | Validation rules above |
| New or existing controller method e.g. `UserController@updateFcmToken` / `NotificationController@updateFcmToken` / `FcmTokenController@update` | Auth + persist |
| `app/Models/User.php` | Ensure `fcm_token` fillable / guarded correctly if column exists |
| Device model (e.g. `UserDevice`, `TrustedDevice`) | Persist per-`device_id` token if that is the real store |
| Migration (only if column missing) | `fcm_token` string nullable on users and/or devices |
| Firebase / notification sender service | **No change** if it already reads the same column(s) login writes |

Optional:

| File | Change |
|------|--------|
| Feature test | Login stores token; update endpoint rotates token; empty rejected |
| API docs / Postman | Document new route for mobile |

---

## 11. Risks if you skip this endpoint

| Risk | Impact |
|------|--------|
| iOS token arrives after login | Device never registered until next login |
| FCM token rotation | Silent push failure for long sessions |
| Flutter Phase 1 omits empty `fcm_token` at login | Correct for DB hygiene, but **increases** need for a post-login update API |
| Overloading profile update | Accidental mass-assignment / wrong device / weaker auth binding |

---

## 12. Summary

- **Login** is the only live, working writer for `fcm_token`; validation treats it as **optional** and allows empty strings.
- **`POST /user/profile_data/update/{id}`** exists but is a profile/preferences API — **not** a suitable FCM token updater.
- **`POST /update-fcm-token`** (and common aliases) **do not exist** (404).
- **`POST /update-app-status`** also 404; unrelated but shows client/server contract drift.
- **`POST /send-chat-notification`** appears miswired (HTML welcome page).
- **Recommendation:** implement minimal authenticated `POST /api/update-fcm-token` with required non-empty `fcm_token` + `device_id`, writing the same storage login already uses, without touching push payload logic.

*End of audit. No backend or Flutter code was modified.*
