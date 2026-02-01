# CasaZero

A Flutter multi-platform application for smart residential and condominium management. It provides documents, maintenance, AI chat, group chat, support tickets, and profile management with role-based access.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Architecture Overview](#architecture-overview)
- [Full Project Structure](#full-project-structure)
- [Layer Responsibilities](#layer-responsibilities)
- [Navigation & State](#navigation--state)
- [Design System](#design-system)
- [Getting Started](#getting-started)

---

## Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter (SDK ^3.9.2) |
| **State & Navigation** | GetX |
| **HTTP** | Dio |
| **Local Storage** | GetStorage |
| **Push & Notifications** | Firebase Core, Firebase Messaging, flutter_local_notifications |
| **UI** | Material, flutter_screenutil, flutter_animate, lucide_icons_flutter, flutter_svg, cached_network_image |
| **Utilities** | path_provider, open_filex, archive, intl, url_launcher, share_plus, permission_handler, geolocator, device_info_plus, file_picker, image_picker, qr_flutter |

**Platforms:** Android, iOS, Web, Windows, macOS, Linux.

---

## Architecture Overview

The app follows a **layered, feature-oriented** structure:

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION                             │
│  (Screens, Controllers, Feature-specific widgets)             │
│  main_scaffold → HomeController → AppScreen enum              │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                       CORE                                   │
│  (Services, Utils, Shared widgets, Localization)              │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                       DATA                                    │
│  (Models, Repositories → API / local)                         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                       APP                                     │
│  (Theme, Routes, Bindings)                                    │
└─────────────────────────────────────────────────────────────┘
```

- **App:** Theme, routes, and GetX initial bindings.
- **Presentation:** Feature modules; each has controllers (GetX) and views/sections.
- **Core:** Shared services, utils, constants, and reusable widgets.
- **Data:** Domain models and repositories that talk to APIs or local storage.

---

## Full Project Structure

```
casazero/
├── android/                    # Android platform
├── ios/                        # iOS platform
├── web/                        # Web platform
├── windows/                    # Windows platform
├── macos/                      # macOS platform
├── linux/                      # Linux platform
├── assets/
│   ├── fonts/
│   │   ├── Inter-Bold.ttf
│   │   ├── Inter-Medium.ttf
│   │   ├── Inter-Regular.ttf
│   │   └── Inter-SemiBold.ttf
│   └── images/                 # SVGs, PNGs (logos, icons, nav, hub)
├── lib/
│   ├── main.dart               # App entry, Firebase init, GetMaterialApp
│   ├── app/
│   │   ├── bindings/
│   │   │   └── initial_binding.dart
│   │   ├── routes/
│   │   │   └── app_routes.dart
│   │   └── theme/
│   │       ├── app_animations.dart
│   │       ├── app_colors.dart
│   │       ├── app_gradients.dart
│   │       ├── app_shadows.dart
│   │       ├── app_text_styles.dart
│   │       └── app_theme.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   ├── app_constants.dart
│   │   │   └── storage_keys.dart
│   │   ├── controllers/
│   │   │   └── message_popup_controller.dart
│   │   ├── localization/
│   │   │   ├── app_translations.dart
│   │   │   └── locale_controller.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── device_info_service.dart
│   │   │   ├── download_service.dart
│   │   │   ├── fcm_service.dart
│   │   │   ├── file_opener_service.dart
│   │   │   ├── geocoding_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── zip_download_service.dart
│   │   ├── utils/
│   │   │   ├── image_url_builder.dart
│   │   │   ├── notification_helper.dart
│   │   │   ├── permissions.dart
│   │   │   ├── time_formatter.dart
│   │   │   └── validators.dart
│   │   └── widgets/
│   │       ├── admin_settings_card.dart
│   │       ├── animated_gradient_container.dart
│   │       ├── bounce_glow_widget.dart
│   │       ├── building_selector_capsule.dart
│   │       ├── building_selector.dart
│   │       ├── casazero_logo.dart
│   │       ├── custom_button.dart
│   │       ├── custom_message_popup.dart
│   │       ├── custom_text_field.dart
│   │       ├── cz_app_bar.dart
│   │       ├── cz_notification_bell.dart
│   │       ├── edit_profile_dialogue.dart
│   │       ├── floating_action_widget.dart
│   │       ├── glass_container.dart
│   │       ├── gradient_button.dart
│   │       ├── language_switcher.dart
│   │       ├── loading_indicator.dart
│   │       ├── logout_section.dart
│   │       ├── nav_tab.dart
│   │       ├── notification_settings_card.dart
│   │       ├── notifications_modal.dart
│   │       ├── outlined_custom_button.dart
│   │       ├── password_input.dart
│   │       ├── platform_safe_area.dart
│   │       ├── preferences_card.dart
│   │       ├── premium_card.dart
│   │       ├── premium_icon_container.dart
│   │       ├── profile_header_card.dart
│   │       ├── pulse_dot.dart
│   │       ├── residence_info_card.dart
│   │       ├── security_card.dart
│   │       ├── shimmer_loading.dart
│   │       ├── status_badge.dart
│   │       ├── text_custom_button.dart
│   │       ├── zip_download_example.dart
│   │       └── zip_password_dialog.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── building_model.dart
│   │   │   ├── construction_phase_model.dart
│   │   │   ├── document_category_model.dart
│   │   │   ├── document_model.dart
│   │   │   ├── feed_item_model.dart
│   │   │   ├── hub_card_model.dart
│   │   │   ├── maintenance_task.dart
│   │   │   ├── residence_model.dart
│   │   │   ├── trusted_device_model.dart
│   │   │   ├── two_factor_method_model.dart
│   │   │   └── user_model.dart
│   │   └── repositories/
│   │       ├── ai_repository.dart
│   │       ├── auth_repository.dart
│   │       ├── document_repository.dart
│   │       ├── home_repository.dart
│   │       └── profile_repository.dart
│   ├── helpers/
│   │   └── local_notification_service.dart
│   └── presentation/
│       ├── main/
│       │   └── main_scaffold.dart          # Single scaffold, AppScreen switch, bottom nav
│       ├── splash/
│       │   ├── controllers/
│       │   │   └── splash_controller.dart
│       │   └── views/
│       │       └── splash_screen.dart
│       ├── auth/
│       │   ├── controllers/
│       │   │   ├── auth_controller.dart
│       │   │   ├── change_password_controller.dart
│       │   │   ├── forgot_change_password_controller.dart
│       │   │   └── forgot_password_controller.dart
│       │   └── views/
│       │       ├── auth_screen.dart
│       │       ├── change_password_screen.dart
│       │       ├── forgot_change_password_screen.dart
│       │       ├── forgot_password_screen.dart
│       │       └── forgot_password_screen.dart
│       ├── home/
│       │   ├── controllers/
│       │   │   └── home_controller.dart    # Current screen, nav, user, residences, notifications
│       │   └── views/
│       │       ├── home_screen.dart
│       │       └── sections/
│       │           ├── construction_phase_item.dart
│       │           ├── construction_progress.dart
│       │           ├── hero_image.dart
│       │           ├── latest_notifications.dart
│       │           ├── notification_item.dart
│       │           ├── premium_banner.dart
│       │           ├── quick_tile_item.dart
│       │           ├── quick_tiles.dart
│       │           ├── residence_name.dart
│       │           ├── view_all_buildings_card.dart
│       │           ├── welcome_message.dart
│       │           └── welcome_user_section.dart
│       ├── hub/
│       │   └── views/
│       │       ├── hub_screen.dart         # Ecosystem hub grid (AI, Chat, Assistenza)
│       │       └── sections/
│       │           └── hub_card_widget.dart
│       ├── ai/
│       │   ├── controllers/
│       │   │   └── ai_controller.dart
│       │   └── viwes/
│       │       └── ai_screen.dart
│       ├── chat/
│       │   └── views/
│       │       └── chat_screen.dart       # Group chat (from Hub "Chat Condominio")
│       ├── tickets/
│       │   └── views/
│       │       └── tickets_screen.dart    # Support tickets (from Hub "Assistenza")
│       ├── documents/
│       │   ├── controllers/
│       │   │   └── documents_controller.dart
│       │   ├── models/
│       │   │   └── upload_result.dart
│       │   └── viwes/
│       │       ├── documents_screen.dart
│       │       └── sections/
│       │           ├── add_document_dialog.dart
│       │           ├── document_card.dart
│       │           ├── document_colors.dart
│       │           ├── document_filter_bar.dart
│       │           ├── document_search_bar.dart
│       │           ├── empty_state.dart
│       │           └── upload_document_dialog.dart
│       ├── maintenance/
│       │   ├── controllers/
│       │   │   └── maintenance_controller.dart
│       │   ├── models/
│       │   │   ├── maintenance_category_model.dart
│       │   │   └── maintenance_task_model.dart
│       │   └── views/
│       │       ├── maintenance_screen.dart
│       │       └── sections/
│       │           ├── add_maintenance_task_dialog.dart
│       │           ├── maintenance_empty_state.dart
│       │           ├── maintenance_filter_bar.dart
│       │           └── maintenance_task_card.dart
│       ├── profile/
│       │   ├── controllers/
│       │   │   ├── document_password_controller.dart
│       │   │   ├── profile_controller.dart
│       │   │   └── two_fa_management_controller.dart
│       │   └── views/
│       │       ├── profile_screen.dart
│       │       ├── document_password_screen.dart
│       │       ├── document_password_2fa_verification_screen.dart
│       │       ├── two_fa_activation_screen.dart
│       │       ├── two_fa_deactivation_verification_screen.dart
│       │       ├── two_fa_management_screen.dart
│       │       └── sections/
│       │           └── two_fa_management_widgets.dart
│       ├── first_login/
│       │   ├── controllers/
│       │   │   └── first_login_controller.dart
│       │   └── views/
│       │       ├── first_login_setup_screen.dart
│       │       └── sections/
│       │           └── first_login_progress_bar.dart
│       ├── otp_verification/
│       │   ├── controllers/
│       │   │   └── otp_verification_controller.dart
│       │   └── views/
│       │       └── otp_verification_screen.dart
│       ├── smart_home/
│       │   └── views/
│       │       └── smart_home_screen.dart
│       ├── trusted_device/
│       │   ├── controllers/
│       │   │   └── trusted_devices_controller.dart
│       │   └── views/
│       │       └── trusted_devices_screen.dart
├── react code/                 # Reference React UI (Chat, Tickets)
│   ├── App.tsx
│   ├── ChatScreen.tsx
│   └── TicketsScreen.tsx
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

---

## Layer Responsibilities

| Layer | Path | Purpose |
|-------|------|---------|
| **App** | `lib/app/` | Global theme (colors, text styles, gradients, shadows, animations), route names, and GetX initial bindings. |
| **Core** | `lib/core/` | Shared services (API, storage, FCM, downloads, zip, file opener, geocoding, device info), constants, utils (permissions, validators, time, image URL), localization, and reusable UI widgets (buttons, inputs, cards, modals, app bar, etc.). |
| **Data** | `lib/data/` | Domain models (user, residence, document, maintenance, hub, feed, etc.) and repositories that perform API calls and map responses to models. |
| **Presentation** | `lib/presentation/` | Feature modules. Each typically has: **controllers/** (GetX state and logic), **views/** or **viwes/** (screens), and **sections/** or **models/** where needed. |
| **Helpers** | `lib/helpers/` | Cross-cutting helpers (e.g. local notification setup). |

---

## Navigation & State

- **Single scaffold:** `MainScaffold` holds one app bar, one body, and one bottom nav. The body is chosen by `HomeController.currentScreen` (`AppScreen` enum).
- **Screen enum:** `AppScreen` includes: `home`, `documents`, `hubScreen`, `maintenance`, `profile`, `smartHome`, `changePassword`, `ai`, `trustedDevices`, `chat`, `tickets`.
- **Navigation:**  
  - `HomeController.navigateToScreen(AppScreen)` and `navigateToScreenByString(String)` (e.g. `'chat'`, `'tickets'`, `'aichat'`) push a new “current” screen and update history.  
  - Hub cards call `onNavigate(screen)` with values like `'chat'`, `'tickets'`, `'aichat'`; these are handled in `navigateToScreenByString`.
- **Back:** `goBack()` / `handleBackNavigation()` use a history stack; sub-screens (e.g. chat, tickets) are not in the bottom nav and back returns to the previous screen.
- **Bottom nav:** Shown only for main tabs; hidden for `chat`, `tickets`, `smartHome`, `changePassword` (see `hideBottomNavScreens` in `main_scaffold.dart`).

---

## Design System

- **Colors:** `lib/app/theme/app_colors.dart` — brand sage palette, neutrals, surface, semantic (success, warning, danger, info).
- **Typography:** `lib/app/theme/app_text_styles.dart` — Inter font, h1–h4, body, caption, label, button.
- **Theme:** `lib/app/theme/app_theme.dart` — Material theme (colors, app bar, cards, buttons).
- **Extras:** `app_gradients.dart`, `app_shadows.dart`, `app_animations.dart`.
- **Assets:** `assets/fonts/` (Inter), `assets/images/` (logos, icons, nav, hub). Responsive layout uses `flutter_screenutil` (e.g. `.w`, `.h`, `.sp`, `.r`).

---

## Getting Started

1. **Clone and install**
   ```bash
   flutter pub get
   ```

2. **Run**
   ```bash
   flutter run
   ```
   Choose a device (Android, iOS, web, Windows, etc.) when prompted.

3. **Environment:** API base URL and related config live in `lib/core/constants/` (e.g. `api_constants.dart`). Firebase is initialized in `main.dart` (optional; app can run without it).

4. **Roles:** Access is driven by `Role` (client, admin, manager) and `Permissions` in `lib/core/utils/permissions.dart`; hub cards and features visibility depend on these.

---

## Summary

CasaZero is a **Flutter app** with **GetX** for state and navigation, a **single main scaffold** that switches body by `AppScreen`, and a **hub** that routes to **AI**, **Chat**, **Tickets**, **Documents**, **Maintenance**, and **Profile**. **Core** holds shared services and widgets, **data** holds models and repositories, and **app** holds theme and routes. The **react code/** folder contains reference React UIs for Chat and Tickets.
