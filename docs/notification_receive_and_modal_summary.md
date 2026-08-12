# Notification Receive & Notification Modal — Implementation Summary

**Project:** CasaZero (Flutter / GetX)  
**Date:** 12 August 2026  
**Scope:** How push notifications are received on device, localized, and shown in the in-app Notification modal  
**Type:** Analysis only — no code was modified  

**Example push content analyzed:**

> Il ticket "Impianti idraulici e idrici" è stato aggiornato. Stato: In Corso.

---

## 1. Executive summary

Push notifications are **server-initiated via FCM** (tickets, documents, maintenance, admin chat) or **client-triggered** for resident chat (`POST /send-chat-notification`). On the device:

1. **System banner** — OS shows FCM `notification` payloads as-is (background/terminated), or `LocalNotificationService` shows a localized banner (foreground / data-only).
2. **In-app feed** — `NotificationManager` refreshes `HomeController.fetchNotifications()` from `POST /get_user/notifications`.
3. **Notification modal** — reads `HomeController.feedItems` and renders title/body via `FeedItemModel.localizedCenterTitle` / `localizedCenterSubtitle`.

For the Italian ticket example above, the **system tray often shows the backend string verbatim**. The **modal** rewrites ticket items to generic localized strings (`Ticket aggiornato` + `Il tuo ticket è stato aggiornato.`) because the client localizer only extracts status from an **English** pattern and does **not** preserve the ticket name (`Impianti idraulici e idrici`) or Italian `Stato: In Corso`.

---

## 2. Key files

| Role | File |
|------|------|
| FCM init, foreground receive | `lib/core/services/fcm_service.dart` |
| Background isolate handler | `lib/main.dart` (`_firebaseMessagingBackgroundHandler`) |
| Cold start / tray tap | `lib/core/services/push_launch_handler.dart` |
| Local banner + content resolve | `lib/helpers/local_notification_service.dart` |
| Title/body localization | `lib/core/utils/notification_content_localizer.dart` |
| Refresh feed + deep links | `lib/core/services/notification_manager.dart` |
| Push type helpers | `lib/core/constants/push_types.dart` |
| API list → models | `lib/data/repositories/home_repository.dart` |
| Feed model + modal display strings | `lib/data/models/feed_item_model.dart` |
| Fetch / unread / mark read | `lib/presentation/home/controllers/home_controller.dart` |
| Notification modal UI | `lib/core/widgets/notifications_modal.dart` |
| Bell entry (opens modal) | `lib/presentation/main/main_scaffold.dart` |
| FCM token sync | `lib/data/repositories/notification_repository.dart` |

---

## 3. End-to-end receive flow

```
Laravel / FCM
    │
    ├─ App FOREGROUND
    │     FirebaseMessaging.onMessage
    │       → FcmService.handlePushMessage
    │           ├─ LocalNotificationService.showNotification (Android always;
    │           │     iOS skips if message.notification != null — OS presents)
    │           │     → resolveContent() → NotificationContentLocalizer.localize()
    │           └─ NotificationManager.handlePushPayload()
    │                 → HomeController.fetchNotifications() + fetchUnreadCount()
    │
    ├─ App BACKGROUND / TERMINATED (data-only)
    │     _firebaseMessagingBackgroundHandler
    │       → LocalNotificationService.showNotification (localized)
    │
    ├─ App BACKGROUND / TERMINATED (notification payload)
    │     OS shows FCM title/body as sent by backend (no Flutter localizer)
    │
    └─ User taps banner
          PushLaunchHandler (FCM) or LocalNotificationService (local)
            → NotificationManager.handleNotificationNavigation()
              → tickets / docs / chat / maintenance by `type` + `reference_id`
```

### 3.1 Startup order (`main.dart`)

Critical path before `runApp`:

1. `Firebase.initializeApp`
2. `PushLaunchHandler.install()` — captures `getInitialMessage` early
3. `LocalNotificationService.initialize()` — channel + local launch details
4. `FcmService.init()` — permissions, token warm-up, `onMessage` listener

Background handler is registered with `FirebaseMessaging.onBackgroundMessage`.

### 3.2 Foreground (`FcmService`)

- Listens to `FirebaseMessaging.onMessage` once.
- Shows local notification via `LocalNotificationService` (except iOS when FCM already includes a `notification` block — avoids duplicate banners).
- Always dispatches payload to `NotificationManager.handlePushPayload` (refresh feed/unread; chat goes to `PrivateChatNotificationService`).

### 3.3 Background (`main.dart`)

- Runs in a separate isolate; must not use GetX controllers.
- If `message.notification == null` (data-only), shows a localized local notification.
- If FCM includes a `notification` block, the **OS renders the server text**; Flutter does not rewrite it.

### 3.4 Tap / deep link (`PushLaunchHandler` + `NotificationManager`)

- Normalizes nested `data` JSON, persists pending nav to storage.
- Navigates when `HOME` + session are ready; otherwise queues and flushes later.
- Ticket types → `AppScreen.tickets` with optional `pendingExpandTicketId` from `reference_id`.
- Push tap does **not** open the Notification modal.

---

## 4. How banner content is built

`LocalNotificationService.resolveContent(RemoteMessage)`:

1. Prefer `message.notification.title/body` if present.
2. Else pick from `data` using language preference (`title_it` / `content_it` vs `title_en` / `content_en`).
3. Pass through `NotificationContentLocalizer.localize(type, title, body)`.

### Ticket branch (`NotificationContentLocalizer`)

Detection:

- `PushTypes.isTicketOrSupport(type)`, **or**
- Heuristic `looksLikeTicket` — matches EN/IT phrases including `ticket aggiornato`.

When treated as ticket:

| Field | Result |
|-------|--------|
| Title | Always `'notification_ticket_updated'.tr` → IT: **Ticket aggiornato** / EN: **Ticket updated** |
| Body | If English regex finds status → `'notification_ticket_status_updated'` with localized status; else generic `'notification_ticket_description'` |

Status extraction regex (English only):

```text
ticket status has been updated to "pending"
```

`localizeTicketStatus` maps: `pending`/`open`, `in_progress`, `resolved`/`closed`.

---

## 5. Example: Italian ticket push

**Received content:**

```text
Il ticket "Impianti idraulici e idrici" è stato aggiornato. Stato: In Corso.
```

### 5.1 System banner

| App state | What user typically sees |
|-----------|---------------------------|
| Background / terminated + FCM `notification` block | **Exact backend Italian string** (OS path — no client rewrite) |
| Foreground (Android) or data-only | Localizer runs: title → **Ticket aggiornato**; body → **Il tuo ticket è stato aggiornato.** (status regex does not match Italian `Stato: In Corso`) |

So the rich sentence with ticket name + “In Corso” is **preserved on the OS banner** when the backend puts it in the FCM notification payload, but **stripped/genericized** when Flutter’s localizer rewrites it.

### 5.2 Gaps vs this payload

1. **Ticket name** (`Impianti idraulici e idrici`) is never parsed into display title/subtitle.
2. **Italian status** (`Stato: In Corso`) is not extracted — only the English “updated to …” pattern is.
3. Modal/localizer therefore show a **generic** ticket update message instead of name + status.

---

## 6. Notification modal — how content is shown

### 6.1 Opening the modal

- Bell in app bar → `NotificationsModal.show(context)` (`main_scaffold.dart`).
- On open: `HomeController.fetchNotifications()` (fresh API pull).

### 6.2 Data source

```
HomeController.fetchNotifications()
  → HomeRepository.getUserNotifications()
      POST /get_user/notifications  { api_token }
  → List<FeedItemModel>
  → feedItems (reactive)
```

Typical API item fields: `id`, `title`, `content`, `notification_type`, `reference_id`, `is_read`, `created_at`, optional `url`, bilingual `title_en` / `title_it` / `content_en` / `content_it`.

Push delivery and the modal list are **separate channels**: FCM wakes the app / shows a banner; the modal always shows **persisted API notifications**, refreshed after a push via `NotificationManager._refreshNotificationsAndUnread()`.

### 6.3 UI (`notifications_modal.dart`)

- Filter tabs: all | document | maintenance | chat | ticket (`PushTypes` + model getters).
- Each card:
  - **Title:** `notification.localizedCenterTitle`
  - **Subtitle:** `notification.localizedCenterSubtitle`
  - **Time:** `notification.timeAgo`
  - Unread dot if `!isRead`
- Tap → mark read → close modal → `NotificationManager.handleNotificationNavigation(item.toNavigationPayload())`.
- Delete → `HomeController.deleteNotification`.

### 6.4 Display strings for a ticket item (`FeedItemModel`)

| Getter | Ticket behavior |
|--------|-----------------|
| `localizedCenterTitle` | `NotificationContentLocalizer.localizedTicketTitle()` → **Ticket aggiornato** |
| `localizedCenterSubtitle` | `localizedTicketBody(rawBody: description)` — same English-status regex / generic fallback |
| Classification | `isTicketType` via `PushTypes` or `looksLikeTicket` on title/body |

For the example stored in API `content` as the Italian sentence:

- Modal **title:** Ticket aggiornato  
- Modal **subtitle:** Il tuo ticket è stato aggiornato.  
- Ticket name and “In Corso” are **not** shown in the modal under current logic.

---

## 7. Architecture diagram (receive → modal)

```
┌──────────────────┐     FCM      ┌─────────────────────┐
│ Laravel backend  │ ───────────► │ Device (FCM SDK)    │
└──────────────────┘              └──────────┬──────────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    ▼                        ▼                        ▼
             Foreground                Background               Tray tap
             FcmService                BG handler            PushLaunchHandler
                    │                        │                        │
                    ▼                        ▼                        ▼
         LocalNotificationService   (OS or local show)    NotificationManager
         + ContentLocalizer                                      │
                    │                                            ├── refresh feed
                    │                                            └── deep link
                    ▼
         NotificationManager.handlePushPayload
                    │
                    ▼
         HomeController.feedItems  ◄── POST /get_user/notifications
                    │
                    ▼
         NotificationsModal (localizedCenterTitle / Subtitle)
```

---

## 8. Related side paths

| Path | Behavior |
|------|----------|
| Unread badge | `HomeController.fetchUnreadCount()` after fetch / push |
| Mark all read | Modal loops `markNotificationAsRead` |
| Chat push send | Flutter POSTs title/body via `NotificationRepository.sendChatNotification` |
| FCM token | Cached in `FcmService`; synced with `POST /update-fcm-token` after auth |
| App resume | May refresh notifications via `AppLifecycleRefreshWrapper` |

---

## 9. Takeaways for the example payload

1. **Backend composes** the Italian sentence with ticket title + status; FCM delivers it.
2. **OS banner (notification payload)** can show that full Italian text.
3. **Flutter localizer** (foreground local banner + Notification modal) treats it as a ticket but **replaces** it with generic translations and **does not** parse `"…"` name or `Stato: In Corso`.
4. Modal content always comes from the **notifications API**, not directly from the FCM payload text.
5. Improving fidelity for this format would mean extending `NotificationContentLocalizer` (Italian status regex, optional ticket-name capture) and/or using structured FCM/API fields (`status`, `ticket_subject`) instead of free-text only.

---

## 10. Related docs

- `docs/push_notification_bilingual_audit.md` — bilingual / chat push title audit (7 August 2026)
