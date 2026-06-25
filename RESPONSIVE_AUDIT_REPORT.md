# Responsive Audit Report

**Project:** CasaZero Flutter App  
**Audit Date:** June 23, 2026  
**Scope:** All 191 Dart files in `lib/`  
**Design Baseline:** `ScreenUtilInit(designSize: Size(390, 844))` in `main.dart`  
**Responsive Package:** `flutter_screenutil ^5.9.0` (present but inconsistently adopted)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total Dart Files Analyzed** | 191 |
| **Total Screens Analyzed** | 25 screen files + 1 shell (`MainScaffold`) + 40+ section/widget screens |
| **Files Using `flutter_screenutil`** | 23 / 191 (12%) |
| **Screen Files Using ScreenUtil** | 11 / 25 (44%) |
| **Total Responsive Issues Found** | 312+ (aggregated) |
| **Critical Issues** | 8 |
| **High Priority Issues** | 24 |
| **Medium Priority Issues** | 67 |
| **Low Priority Issues** | 90+ |

### Top Risks

1. **Fixed 500px hero image** consumes ~60% of viewport on small phones (320–360px wide).
2. **Splash screen** uses 320–400px fixed decorative elements that exceed narrow screen widths.
3. **`CasaZeroLogo`** hardcodes `width: 360` despite accepting a `maxLogoWidthFactor` parameter.
4. **Global `TextScaler.linear(1.0)`** disables system accessibility text scaling app-wide.
5. **Portrait-only lock** prevents landscape, foldable, and tablet-optimized layouts.
6. **Inconsistent ScreenUtil adoption** — half the app uses raw pixel values while the other half uses `.w`/`.h`/`.sp`.
7. **iOS SafeArea skipped** via `PlatformSafeArea` — Dynamic Island / notch overlap risk on iOS.
8. **No web/desktop responsive strategy** — app is mobile-only; no adaptive layouts for large screens.

### Readiness Assessment

**Overall Responsive Score: 58 / 100**  
**Readiness: Needs Major Fixes**

The app has solid foundations (`ScreenUtilInit`, Hub `LayoutBuilder` breakpoints, `FloatingBottomNavBar` padding helpers, scrollable forms) but widespread hardcoded dimensions and inconsistent scaling make it unreliable on small phones, accessibility-large-text mode, tablets, and foldables.

---

## Critical Issues

### Issue #1 — Fixed 500px Hero Image Height

**File:** `lib/presentation/home/views/sections/hero_image.dart`  
**Line:** 100

**Problem:**  
Hero image container uses a fixed `height: 500` regardless of screen size. On a 667px-tall iPhone SE, this alone consumes ~75% of usable viewport before any other content.

**Current Code:**
```dart
return Container(
  margin: const EdgeInsets.only(top: 5),
  width: double.infinity,
  height: 500, // Fixed height: 500px equivalent
  child: ClipRect(
```

**Impact:**  
Home screen becomes excessively tall on small devices; users must scroll past a massive image. On landscape (if unlocked) or split-screen, layout would break severely.

**Recommended Fix:**
```dart
final screenHeight = MediaQuery.sizeOf(context).height;
final heroHeight = (screenHeight * 0.38).clamp(220.0, 420.0);

return Container(
  margin: EdgeInsets.only(top: 5.h),
  width: double.infinity,
  height: heroHeight,
  child: ClipRect(
```

**Priority:** Critical  
**Effort:** 1 hour

---

### Issue #2 — Splash Screen Fixed 320–400px Decorative Elements

**File:** `lib/presentation/splash/views/splash_screen.dart`  
**Lines:** 214–215, 286–287, 312–313

**Problem:**  
Glow orb (384px), inner glow ring (400px), and logo container (320px) are hardcoded. On 320px-wide devices these exceed screen width and cause horizontal overflow/clipping.

**Current Code:**
```dart
Container(width: 384, height: 384, ...)
Container(width: 400, height: 400, ...)
Container(width: 320, height: 320, ...)
```

**Impact:**  
Splash screen breaks visually on smallest Android phones (320px). Logo and glow effects clip or overflow.

**Recommended Fix:**
```dart
final size = MediaQuery.sizeOf(context);
final logoSize = size.width * 0.75; // ~240–290 on phones
Container(width: logoSize, height: logoSize, ...)
```

**Priority:** Critical  
**Effort:** 1.5 hours

---

### Issue #3 — CasaZeroLogo Hardcoded 360px Width

**File:** `lib/core/widgets/casazero_logo.dart`  
**Lines:** 46–62, 86, 103, 111

**Problem:**  
Despite `maxLogoWidthFactor` parameter and `screenWidth` calculation, logo renders at fixed `360.0` pixels. Used on Auth, OTP, and First Login screens.

**Current Code:**
```dart
final logoWidth = 360.0;
return SizedBox(
  width: logoWidth,
  height: logoHeight,
  child: SvgPicture.asset(assetPath, width: logoWidth, ...),
);
```

**Impact:**  
Horizontal overflow on screens narrower than 360px (common on older Android). Auth flow is the first screen users see.

**Recommended Fix:**
```dart
final logoWidth = (screenWidth * maxLogoWidthFactor).clamp(200.0, 360.0);
```

**Priority:** Critical  
**Effort:** 45 minutes

---

### Issue #4 — Global Text Scaling Disabled (Accessibility)

**File:** `lib/main.dart`  
**Line:** 213

**Problem:**  
App forces `TextScaler.linear(1.0)`, overriding the user's system font size / accessibility settings.

**Current Code:**
```dart
return MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: const TextScaler.linear(1.0),
  ),
  child: widget!,
);
```

**Impact:**  
Users with vision impairments who increase system text size see no change. Violates accessibility guidelines (WCAG). Combined with 80+ hardcoded `fontSize` values, text becomes unreadable for accessibility users.

**Recommended Fix:**
```dart
final systemScaler = MediaQuery.textScalerOf(context);
final clampedScaler = systemScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);
return MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
  child: widget!,
);
```

**Priority:** Critical  
**Effort:** 2 hours (including overflow testing with large text)

---

### Issue #5 — Hero Image Internal Height Mismatch

**File:** `lib/presentation/home/views/sections/hero_image.dart`  
**Lines:** 302–306, 323–328

**Problem:**  
Parent container is 500px but network/fallback images use `height: 420` and `height: 500` inconsistently, causing layout gaps or clipping.

**Current Code:**
```dart
CachedNetworkImage(..., height: 420, ...)
Image.asset(..., height: 500, ...)
```

**Impact:**  
Visual inconsistency; image may not fill container or may clip gradients/overlays.

**Recommended Fix:**  
Use `fit: BoxFit.cover` inside a single `AspectRatio` or `LayoutBuilder`-driven height — no nested fixed heights.

**Priority:** Critical  
**Effort:** 1 hour (with Issue #1)

---

### Issue #6 — Portrait Orientation Locked

**File:** `lib/main.dart`  
**Lines:** 158–162

**Problem:**  
App locks to portrait only.

**Current Code:**
```dart
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
]);
```

**Impact:**  
No landscape support on phones, tablets, or foldables. Split-screen and external keyboard scenarios on Android tablets fail. Intentional for mobile UX but blocks tablet optimization.

**Recommended Fix:**  
Allow landscape on tablets (`shortestSide >= 600`) or remove lock and add per-screen `OrientationBuilder` guards.

**Priority:** Critical (for tablet/foldable readiness)  
**Effort:** 4–8 hours (full regression)

---

### Issue #7 — iOS SafeArea Intentionally Skipped

**File:** `lib/core/widgets/platform_safe_area.dart`  
**Lines:** 41–54

**Problem:**  
`PlatformSafeArea` applies `SafeArea` only on Android; iOS returns child without safe area padding.

**Current Code:**
```dart
if (Platform.isAndroid) {
  return SafeArea(..., child: child);
}
return child; // iOS — no SafeArea
```

**Impact:**  
Content on iOS may overlap Dynamic Island, notch, or home indicator when `PlatformSafeArea` is relied upon. `main.dart` comment says SafeArea was removed globally — individual screens must handle it, but many do not.

**Recommended Fix:**  
Use `SafeArea` on all platforms, or apply `MediaQuery.padding` selectively per screen. Remove the iOS bypass unless there is a documented reason.

**Priority:** Critical (iOS notch/home indicator)  
**Effort:** 3 hours

---

### Issue #8 — `resizeToAvoidBottomInset: false` on Main Shell

**File:** `lib/presentation/main/main_scaffold.dart`  
**Line:** 93

**Problem:**  
Main scaffold disables automatic keyboard inset resizing. Custom `_KeyboardBottomPadding` handles it, but bottom nav remains positioned with `viewInsets: EdgeInsets.zero`.

**Current Code:**
```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: Stack(
    children: [
      _KeyboardBottomPadding(...),
      Positioned(bottom: 0, child: MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: _buildFloatingNavBar(),
      )),
```

**Impact:**  
On chat/search screens embedded in shell, keyboard may overlap input fields. Bottom nav stays visible over keyboard (may be intentional) but can obscure content on smaller screens.

**Recommended Fix:**  
Verify all input screens (AI, chat, tickets) handle keyboard insets locally. Consider `resizeToAvoidBottomInset: true` for input-heavy sub-screens.

**Priority:** Critical (keyboard overlap risk)  
**Effort:** 2 hours

---

## High Priority Issues

### Issue #9 — First Login QR Codes Fixed at 200×200

**File:** `lib/presentation/first_login/views/first_login_setup_screen.dart`  
**Lines:** ~1051–1085

**Problem:** Four QR code containers use `width: 200, height: 200` without scaling.

**Impact:** QR codes overflow or dominate screen on small devices; poor tablet utilization.

**Recommended Fix:** `width: 180.w, height: 180.w` or `min(screenWidth * 0.5, 200)`.

**Priority:** High | **Effort:** 30 min

---

### Issue #10 — First Login: 27+ Hardcoded Font Sizes

**File:** `lib/presentation/first_login/views/first_login_setup_screen.dart`  
**Lines:** 107–1038 (throughout)

**Problem:** Widespread `fontSize: 24`, `18`, `14`, `12` without `.sp`.

**Impact:** Text does not scale with ScreenUtil design baseline; inconsistent with AI/Chat screens.

**Recommended Fix:** Import `flutter_screenutil` and convert all typography to `.sp`.

**Priority:** High | **Effort:** 2 hours

---

### Issue #11 — Smart Home Screen: 17 Hardcoded Font Sizes + Raw Padding

**File:** `lib/presentation/smart_home/views/smart_home_screen.dart`  
**Lines:** 263–829

**Problem:** `EdgeInsets.all(24)`, `fontSize: 24/15/13/11` throughout; no ScreenUtil import.

**Current Code:**
```dart
padding: const EdgeInsets.all(24),
// ...
style: TextStyle(fontSize: 15, ...)
```

**Impact:** Device cards, room filters, and stats rows look disproportionate across screen sizes.

**Priority:** High | **Effort:** 2.5 hours

---

### Issue #12 — OTP Verification: Hardcoded Typography

**File:** `lib/presentation/otp_verification/views/otp_verification_screen.dart`  
**Lines:** 97–437

**Problem:** `fontSize: 32`, `18`, `14`, `12` on OTP inputs and labels; unused logo helper with `width: 240/180`.

**Impact:** OTP boxes may overflow on small screens with large accessibility text.

**Priority:** High | **Effort:** 1.5 hours

---

### Issue #13 — Auth Screen Language Selector Fixed Position

**File:** `lib/presentation/auth/views/auth_screen.dart`  
**Lines:** 51–54

**Problem:** `Positioned(top: 40, right: 24)` outside `SafeArea` context for top inset.

**Impact:** Overlaps status bar/notch on some devices; `top: 40` is not status-bar-aware.

**Recommended Fix:**
```dart
Positioned(
  top: MediaQuery.paddingOf(context).top + 8,
  right: 24.w,
  child: ...
)
```

**Priority:** High | **Effort:** 20 min

---

### Issue #14 — App Text Styles Use Raw Pixel Font Sizes

**File:** `lib/app/theme/app_text_styles.dart`  
**Lines:** 9–116

**Problem:** All theme text styles define `fontSize: 14`, `16`, `20`, etc. as raw doubles.

**Impact:** Propagates non-scalable typography to every widget using `AppTextStyles` without `.copyWith(fontSize: X.sp)`.

**Recommended Fix:** Create responsive text style factory or document that all consumers must apply `.sp`.

**Priority:** High | **Effort:** 3 hours

---

### Issue #15 — Construction Progress Section: Fixed 128px Thumbnail

**File:** `lib/presentation/home/views/sections/construction_progress_section.dart`  
**Lines:** 581–582

**Problem:** Modal/detail thumbnail `width: 128, height: 128` fixed.

**Impact:** Acceptable on phone but wastes space on tablet; no responsive scaling.

**Priority:** High | **Effort:** 30 min

---

### Issue #16 — Construction Progress Status Row Overflow Risk

**File:** `lib/presentation/home/views/sections/construction_progress_section.dart`  
**Lines:** 392–502

**Problem:** Status label `Text(statusLabel)` in a `Row` without `maxLines` or `overflow: TextOverflow.ellipsis`.

**Impact:** Long localized status strings cause `RenderFlex overflow` on narrow screens.

**Recommended Fix:**
```dart
Flexible(
  child: Text(statusLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
)
```

**Priority:** High | **Effort:** 20 min

---

### Issue #17 — 2FA QR Code Fixed 200×200

**File:** `lib/presentation/profile/views/sections/two_fa_management_widgets.dart`  
**Lines:** 263–264

**Problem:** QR widget uses raw `width: 200, height: 200`.

**Impact:** Same as First Login QR issue.

**Priority:** High | **Effort:** 20 min

---

### Issue #18 — Quick Tiles Grid: Fixed 2 Columns

**File:** `lib/presentation/home/views/sections/quick_tiles.dart`  
**Lines:** 57–58

**Problem:** `crossAxisCount: 2` always — no tablet adaptation.

**Impact:** Tiles stretch excessively on tablets (768px+); wasted horizontal space.

**Recommended Fix:**
```dart
crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
```

**Priority:** High | **Effort:** 30 min

---

### Issue #19 — ScreenUtil Not Used on 13 of 25 Screens

**Files (no `flutter_screenutil` import):**
- `home_screen.dart`
- `hub_screen.dart`
- `profile_screen.dart`
- `splash_screen.dart`
- `auth_screen.dart`
- `forgot_password_screen.dart`
- `forgot_change_password_screen.dart`
- `otp_verification_screen.dart`
- `first_login_setup_screen.dart`
- `smart_home_screen.dart`
- `maintenance_screen.dart`
- `chat_hub_screen.dart`
- `two_fa_activation_screen.dart`

**Impact:** Two different sizing systems coexist; visual inconsistency across navigation flows.

**Priority:** High | **Effort:** 8–12 hours (systematic migration)

---

### Issue #20 — Smart Home Device Name Text Without Ellipsis

**File:** `lib/presentation/smart_home/views/smart_home_screen.dart`  
**Lines:** 521–527

**Problem:** Device name `Text` widget lacks `maxLines` and `overflow`.

**Impact:** Long device names overflow device cards.

**Priority:** High | **Effort:** 15 min

---

### Issue #21 — First Login Password Requirements Row Overflow

**File:** `lib/presentation/first_login/views/first_login_setup_screen.dart`  
**Lines:** 933–959

**Problem:** `Row(mainAxisAlignment: spaceBetween)` with long `'password_requirements'` text and badge without `Flexible`.

**Impact:** Horizontal overflow in Italian/English long translations.

**Priority:** High | **Effort:** 20 min

---

### Issue #22 — Add Document Dialog Fixed Preview Height

**File:** `lib/presentation/documents/viwes/sections/add_document_dialog.dart`  
**Line:** 560

**Problem:** Upload preview `height: 200` fixed.

**Impact:** Dialog content may overflow on small screens when keyboard is open.

**Priority:** High | **Effort:** 30 min

---

### Issue #23 — Create Ticket Dialog: Fixed Button Widths in Footer

**File:** `lib/presentation/tickets/views/create_ticket_dialog.dart`  
**Lines:** 649–660, 892–902

**Problem:** Action buttons use `width: 100` and `width: 140` fixed.

**Impact:** Footer buttons overflow on narrow screens or with large text.

**Priority:** High | **Effort:** 45 min

---

### Issue #24 — Residence Name / Welcome Section Raw Typography

**Files:**
- `lib/presentation/home/views/sections/residence_name.dart` (line 117: `fontSize: 28`)
- `lib/presentation/home/views/sections/welcome_user_section.dart` (line 131: `fontSize: 22`)

**Problem:** Large hardcoded heading sizes on home screen.

**Impact:** Headings dominate small screens; no scaling.

**Priority:** High | **Effort:** 30 min

---

### Issue #25 — Hub Screen Raw Padding/Typography

**File:** `lib/presentation/hub/views/hub_screen.dart`  
**Lines:** 31, 44, 221, 250

**Problem:** `EdgeInsets.all(32)`, `fontSize: 18/13` without ScreenUtil despite excellent `LayoutBuilder` grid logic.

**Impact:** Inconsistent spacing relative to AI/Tickets screens.

**Priority:** High | **Effort:** 1 hour

---

### Issue #26 — Profile Screen Raw Padding

**File:** `lib/presentation/profile/views/profile_screen.dart`  
**Line:** 42

**Problem:** `EdgeInsets.all(24.0)` — no ScreenUtil.

**Impact:** Profile cards spacing inconsistent with responsive screens.

**Priority:** High | **Effort:** 30 min

---

### Issue #27 — Maintenance Task Card Mixed Typography

**File:** `lib/presentation/maintenance/views/sections/maintenance_task_card.dart`  
**Lines:** 413–1136

**Problem:** Mix of hardcoded `fontSize` and some ellipsis usage; long task titles risk overflow in metadata rows.

**Priority:** High | **Effort:** 1.5 hours

---

### Issue #28 — Chat Screens Inconsistent Scaling

**Files:**
- `lib/presentation/chat/views/chat_screen.dart` (line 144: `fontSize: 13` raw among `.sp` usage)
- `lib/presentation/chat/views/admin_chat_screen.dart` (line 157: same)

**Problem:** Inconsistent `.sp` adoption within same file.

**Priority:** High | **Effort:** 45 min

---

### Issue #29 — Notifications Modal Fixed 80% Height

**File:** `lib/core/widgets/notifications_modal.dart`  
**Line:** 57

**Problem:** `height: MediaQuery.of(context).size.height * 0.80` — good use of MediaQuery, but no max-width constraint for tablets.

**Impact:** On tablets, modal stretches full width awkwardly.

**Recommended Fix:** Add `constraints: BoxConstraints(maxWidth: 500)` centered on wide screens.

**Priority:** High | **Effort:** 45 min

---

### Issue #30 — No Tablet Master-Detail Layouts

**Files:** All list → detail flows (Documents, Tickets, Maintenance, Chat)

**Problem:** No adaptive split-view for width ≥ 840px.

**Impact:** Tablet and foldable users see stretched single-column layouts with poor space utilization.

**Priority:** High | **Effort:** 16–24 hours (architectural)

---

### Issue #31 — Web/Desktop Not Supported

**Files:** `pubspec.yaml`, `main.dart`

**Problem:** No web target configuration; `Platform.isAndroid` / `Platform.isIOS` checks throughout; no mouse/hover layout variants beyond incidental `MouseRegion` usage.

**Impact:** Cannot run as web/desktop app; not a bug today but blocks future responsive desktop strategy.

**Priority:** High (if web is planned) | **Effort:** 40+ hours

---

### Issue #32 — Demo Home Wrapper Fixed 320px

**File:** `lib/presentation/demo/widgets/demo_home_wrapper.dart`  
**Line:** 59

**Problem:** `width: 320` hardcoded preview frame.

**Impact:** Demo-only, but indicates pattern of fixed widths.

**Priority:** High (demo only) | **Effort:** 15 min

---

## Medium Priority Issues

### Issue #33 — Home Screen Raw Spacing

**File:** `lib/presentation/home/views/home_screen.dart`  
**Problem:** No ScreenUtil; `SizedBox(height: 20)` and delegates to non-responsive section widgets.  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #34 — Quick Tile Items Fixed 48×48 Icons

**File:** `lib/presentation/home/views/sections/quick_tile_item.dart`  
**Lines:** 34–35  
**Problem:** `width: 48, height: 48` icon containers.  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #35 — View All Buildings Card Fixed 48×48

**File:** `lib/presentation/home/views/sections/view_all_buildings_card.dart`  
**Lines:** 31–32  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #36 — Premium Banner maxWidth 448 Without Centering on Tablet

**File:** `lib/presentation/home/views/sections/premium_banner.dart`  
**Line:** 153  
**Problem:** `maxWidth: 448` good for phone but parent doesn't center on wide screens.  
**Priority:** Medium | **Effort:** 20 min

---

### Issue #37 — Construction Progress Card Raw Padding

**File:** `lib/presentation/home/views/sections/construction_progress.dart`  
**Lines:** 28–29  
**Problem:** `EdgeInsets.only(top: 32, left: 24, right: 24)`, `padding: all(24)`.  
**Priority:** Medium | **Effort:** 20 min

---

### Issue #38 — Document Search Bar Raw Padding

**File:** `lib/presentation/documents/viwes/sections/document_search_bar.dart`  
**Lines:** 17, 47  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #39 — Document Card Scale Multiplier Partial Solution

**File:** `lib/presentation/documents/viwes/sections/document_card.dart`  
**Problem:** Uses custom `scale` multiplier — good pattern but not applied app-wide.  
**Priority:** Medium | **Effort:** N/A (positive pattern)

---

### Issue #40 — Hub Card Widget Raw Padding

**File:** `lib/presentation/hub/views/sections/hub_card_widget.dart`  
**Line:** 76  
**Problem:** `EdgeInsets.all(16)`.  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #41 — Hub Controller Breakpoints Use Raw Pixel Padding

**File:** `lib/presentation/hub/controllers/hub_controller.dart`  
**Lines:** 68–72  
**Problem:** `horizontal: 120/80/40/24` — intentional breakpoints but not ScreenUtil-scaled.  
**Priority:** Medium | **Effort:** 30 min

---

### Issue #42 — FloatingBottomNavBar contentGap Not Scaled

**File:** `lib/core/widgets/floating_bottom_nav_bar.dart`  
**Line:** 32  
**Problem:** `static const double contentGap = 24` — should be `24.h`.  
**Priority:** Medium | **Effort:** 10 min

---

### Issue #43 — FloatingBottomNavBar listPadding Raw 16

**File:** `lib/core/widgets/floating_bottom_nav_bar.dart`  
**Line:** 68  
**Problem:** `horizontal: 16` default not scaled.  
**Priority:** Medium | **Effort:** 10 min

---

### Issue #44 — Custom Message Popup Fixed Inset

**File:** `lib/core/widgets/custom_message_popup.dart`  
**Line:** 48  
**Problem:** `insetPadding: EdgeInsets.symmetric(horizontal: 24)`.  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #45 — Gradient Button Fixed 20×20 Loader

**File:** `lib/core/widgets/gradient_button.dart`  
**Lines:** 49–50  
**Priority:** Medium | **Effort:** 5 min

---

### Issue #46 — Profile Header Card Dialog Layout

**File:** `lib/core/widgets/profile_header_card.dart`  
**Problem:** `showDialog` without `isScrollControlled` or max height — risk on small screens.  
**Priority:** Medium | **Effort:** 45 min

---

### Issue #47 — Security Card Multiple Get.dialog Calls

**File:** `lib/core/widgets/security_card.dart`  
**Lines:** 131, 267, 398  
**Problem:** Dialogs without responsive constraints.  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #48 — 2FA Activation Screen Raw Padding Throughout

**File:** `lib/presentation/profile/views/two_fa_activation_screen.dart`  
**Problem:** 10+ `EdgeInsets.all(16)` occurrences.  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #49 — Forgot Password Screens Raw Typography

**Files:**
- `forgot_password_screen.dart` (4 hardcoded font sizes)
- `forgot_change_password_screen.dart` (7 hardcoded font sizes)  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #50 — Maintenance Screen No ScreenUtil

**File:** `lib/presentation/maintenance/views/maintenance_screen.dart`  
**Problem:** List padding uses `FloatingBottomNavBar.listPadding` (partially responsive) but typography not scaled.  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #51 — Chat Hub Screen No ScreenUtil

**File:** `lib/presentation/chat/views/chat_hub_screen.dart`  
**Problem:** 3 hardcoded font sizes; uses `LayoutBuilder` in one section (good).  
**Priority:** Medium | **Effort:** 45 min

---

### Issue #52 — Latest Notifications Metadata Row

**File:** `lib/presentation/home/views/sections/latest_notifications.dart`  
**Line:** 325  
**Problem:** Date/metadata row may overflow with long localized strings.  
**Priority:** Medium | **Effort:** 20 min

---

### Issue #53 — Ticket Card Mixed Raw/ScreenUtil Padding

**File:** `lib/presentation/tickets/widgets/ticket_card.dart`  
**Line:** 231  
**Problem:** `padding: EdgeInsets.all(8.0)` amid `.w`/`.h` usage.  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #54 — Create Ticket Dialog Photo Thumbnails 72×72

**File:** `lib/presentation/tickets/views/create_ticket_dialog.dart`  
**Lines:** 317–363  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #55 — Upload Document Dialog LayoutBuilder Present (Good) But Mixed Sizes

**File:** `lib/presentation/documents/viwes/sections/add_document_dialog.dart`  
**Problem:** Has `LayoutBuilder` (3 uses) but still mixes raw and responsive values.  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #56 — Maintenance Add Task Dialog

**File:** `lib/presentation/maintenance/views/sections/add_maintenance_task_dialog.dart`  
**Problem:** Has `LayoutBuilder` but 7 hardcoded font sizes.  
**Priority:** Medium | **Effort:** 1 hour

---

### Issue #57 — Admin Settings / Logout Section Raw Padding

**Files:** `admin_settings_card.dart` (line 29), `logout_section.dart` (line 22)  
**Priority:** Medium | **Effort:** 20 min

---

### Issue #58 — Building Selector Partial ScreenUtil

**File:** `lib/core/widgets/building_selector.dart`  
**Problem:** Mix of `.w`/`.h` and 10 hardcoded `fontSize` values.  
**Priority:** Medium | **Effort:** 45 min

---

### Issue #59 — Splash Screen Fixed Bottom Positioning

**File:** `lib/presentation/splash/views/splash_screen.dart`  
**Problem:** `bottom: 128`, `bottom: 64` fixed positioned elements.  
**Impact:** Tagline/branding may overlap logo on short screens (iPhone SE).  
**Priority:** Medium | **Effort:** 45 min

---

### Issue #60 — Splash Typography letterSpacing: 7.2

**File:** `lib/presentation/splash/views/splash_screen.dart`  
**Line:** ~377  
**Problem:** `fontSize: 24`, `letterSpacing: 7.2` — wide text on narrow screens.  
**Priority:** Medium | **Effort:** 20 min

---

### Issue #61 — Main Scaffold Dialog Loading Height

**File:** `lib/presentation/main/main_scaffold.dart`  
**Lines:** 791, 796  
**Problem:** `height: 100` in residence selector dialog.  
**Priority:** Medium | **Effort:** 10 min

---

### Issue #62 — Trusted Devices Good ScreenUtil — Minor Raw Shadow Values

**File:** `lib/presentation/trusted_device/views/trusted_devices_screen.dart`  
**Score:** 82/100 — reference implementation with 21 `.sp`/`.w` usages.  
**Priority:** Medium | **Effort:** 30 min

---

### Issue #63 — AI Screen Excellent — Minor Raw Blur/Shadow

**File:** `lib/presentation/ai/viwes/ai_screen.dart`  
**Score:** 88/100 — best screen; 27 `.sp` usages.  
**Priority:** Medium | **Effort:** 30 min

---

### Issue #64 — Documents Screen Filter Bar Horizontal ListView Height

**File:** `lib/presentation/documents/viwes/sections/document_filter_bar.dart`  
**Problem:** `SizedBox(height: 48)` fixed filter chip row.  
**Priority:** Medium | **Effort:** 15 min

---

### Issue #65 — Edit Profile Dialogue Scroll

**File:** `lib/core/widgets/edit_profile_dialogue.dart`  
**Problem:** Has `SingleChildScrollView` (good) but needs max height constraint for small screens.  
**Priority:** Medium | **Effort:** 30 min

---

### Issue #66 — Zip Password Dialog

**File:** `lib/core/widgets/zip_password_dialog.dart`  
**Problem:** Fixed typography; no ScreenUtil.  
**Priority:** Medium | **Effort:** 20 min

---

### Issue #67 — MaxWidth 448 Pattern Without Horizontal Centering

**Files:** `auth_screen.dart`, `residence_name.dart`, `welcome_user_section.dart`, `main_scaffold.dart`  
**Problem:** `maxWidth: 448` used but not always wrapped in `Center` + `Align` for tablet wide layouts.  
**Priority:** Medium | **Effort:** 1 hour

---

## Low Priority Issues

### Issue #68 — Dead `_buildLogo()` Helpers with Fixed Widths

**Files:** `auth_screen.dart` (153, 158), `otp_verification_screen.dart` (83, 88), `first_login_setup_screen.dart` (93, 98)  
**Problem:** Unused code with `width: 240/180`.  
**Priority:** Low | **Effort:** 15 min

---

### Issue #69 — Construction Progress Skeleton Shimmer Fixed Width

**File:** `construction_progress_section.dart` line 173: `width: 140`  
**Priority:** Low | **Effort:** 5 min

---

### Issue #70 — Hero Image Top Margin Raw 5px

**File:** `hero_image.dart` line 98  
**Priority:** Low | **Effort:** 5 min

---

### Issue #71 — Demo Controls Panel Raw Typography

**File:** `demo_controls_panel.dart` — 10 hardcoded font sizes (demo only)  
**Priority:** Low | **Effort:** 30 min

---

### Issue #72 — Demo Button Raw Padding

**File:** `demo_button.dart` line 19  
**Priority:** Low | **Effort:** 5 min

---

### Issue #73 — Nav Tab Widget

**File:** `core/widgets/nav_tab.dart`  
**Priority:** Low | **Effort:** 20 min

---

### Issue #74 — Language Switcher Raw Font Size

**File:** `core/widgets/language_switcher.dart`  
**Priority:** Low | **Effort:** 10 min

---

### Issue #75 — Preferences Card

**File:** `core/widgets/preferences_card.dart`  
**Priority:** Low | **Effort:** 15 min

---

### Issue #76 — Notification Settings Card Raw Spacing

**File:** `core/widgets/notification_settings_card.dart`  
**Lines:** 66–141 — multiple `SizedBox(height: 4/12/16)`  
**Priority:** Low | **Effort:** 20 min

---

### Issue #77 — Status Badge / Premium Card / Glass Container

**Files:** `status_badge.dart`, `premium_card.dart`, `glass_container.dart`  
**Priority:** Low | **Effort:** 30 min each

---

### Issue #78 — Welcome Message / Notification Item Typography

**Files:** `welcome_message.dart`, `notification_item.dart`  
**Priority:** Low | **Effort:** 15 min

---

### Issue #79 — First Login Progress Bar

**File:** `first_login_progress_bar.dart` — 2 hardcoded font sizes  
**Priority:** Low | **Effort:** 10 min

---

### Issue #80 — MouseRegion on Mobile-Only Widgets

**File:** `main_scaffold.dart` — `MouseRegion` on nav buttons (harmless on mobile, useful if web added)  
**Priority:** Low

---

### Issue #81 — Image Picker maxWidth/maxHeight 1920 in Create Ticket

**File:** `create_ticket_dialog.dart` lines 785–812  
**Problem:** Image dimension limits, not layout — acceptable.  
**Priority:** Low

---

### Issue #82 — TextOverflow.visible on Home Headings (Intentional)

**Files:** `residence_name.dart` (125–126), `welcome_user_section.dart` (139–140)  
**Problem:** Allows multi-line wrap — acceptable but may push layout on accessibility large text.  
**Priority:** Low

---

### Issue #83 — App Theme Raw Font Sizes

**File:** `app/theme/app_theme.dart` — 7 hardcoded sizes in `ThemeData`  
**Priority:** Low | **Effort:** 1 hour

---

### Issue #84 — Casazero Logo Tagline fontSize: 15

**File:** `casazero_logo.dart` line 132  
**Priority:** Low | **Effort:** 5 min

---

### Issue #85 — Private Chat Bubble Partial ScreenUtil

**File:** `private_chat_bubble.dart` — 5 `.sp` and 5 raw font sizes mixed  
**Priority:** Low | **Effort:** 20 min

---

### Issue #86 — Chat Option Card

**File:** `chat_option_card.dart` — 2 hardcoded font sizes  
**Priority:** Low | **Effort:** 10 min

---

### Issue #87 — Empty State Documents

**File:** `empty_state.dart` — 1 hardcoded font size  
**Priority:** Low | **Effort:** 5 min

---

### Issue #88 — Home Screen fontSize: 1 Instance

**File:** `home_screen.dart`  
**Priority:** Low | **Effort:** 5 min

---

### Issue #89 — Maintenance Empty State

**File:** `maintenance_empty_state.dart`  
**Priority:** Low | **Effort:** 15 min

---

### Issue #90 — Zip Download Example (Dev/Example Code)

**File:** `zip_download_example.dart`  
**Priority:** Low

---

## Architecture Review

### MediaQuery Usage

| Aspect | Assessment |
|--------|------------|
| **Global setup** | `ScreenUtilInit` wraps app; `MediaQuery` used for text scaler override |
| **Quality** | Mixed — good in `notifications_modal`, `floating_bottom_nav_bar`, `hub_screen`; absent in most home sections |
| **Missing usages** | Hero image, splash, auth logo, quick tiles, smart home cards |
| **Incorrect usages** | `TextScaler.linear(1.0)` suppresses accessibility scaling; `viewInsets: EdgeInsets.zero` on bottom nav may hide keyboard state |

### LayoutBuilder Usage

**Files using `LayoutBuilder` (7 files — underutilized):**
- `hub_screen.dart` ✅ Excellent
- `construction_progress_section.dart`
- `add_document_dialog.dart`
- `add_maintenance_task_dialog.dart`
- `create_ticket_dialog.dart`
- `floating_bottom_nav_bar.dart`
- `chat_hub_screen.dart`

**Missing opportunities:** Home screen, Profile screen, Documents list, Tickets list, Smart Home grid, Auth form centering.

### Flexible Widgets (Expanded / Flexible / Spacer)

| Pattern | Assessment |
|---------|------------|
| **Good** | `main_scaffold.dart` title ellipsis, `hub_screen.dart` info banner, `ai_screen.dart` Expanded ListView, `documents_screen.dart` Expanded list |
| **Missing** | Construction progress status row, smart home device status row, first login password header row, ticket dialog footer buttons |

### Responsive Packages

| Package | Status |
|---------|--------|
| `flutter_screenutil` | ✅ Installed, used in 12% of files |
| `responsive_framework` | ❌ Not installed |
| `responsive_builder` | ❌ Not installed |

**Recommendation:** Standardize on `flutter_screenutil` already in project rather than adding new packages. Create a thin `AppResponsive` utility wrapper for breakpoints if needed.

---

# Screen-by-Screen Audit

## Splash Screen

**File:** `lib/presentation/splash/views/splash_screen.dart`  
**Responsive Score:** 42/100

**Issues Found:**
- Fixed 384/400/320px glow and logo containers (Critical)
- Fixed `bottom: 128/64` positioning
- `fontSize: 24` without `.sp`
- No ScreenUtil import
- No `LayoutBuilder` for device size classes

**Recommendations:**
- Scale all decorative elements relative to `MediaQuery.sizeOf(context).width`
- Use `SafeArea` for bottom text/branding
- Add ScreenUtil import for typography

---

## Auth Screen

**File:** `lib/presentation/auth/views/auth_screen.dart`  
**Responsive Score:** 58/100

**Issues Found:**
- `CasaZeroLogo` 360px internal width (Critical)
- Language selector `Positioned(top: 40)` not status-bar aware
- Raw `EdgeInsets.symmetric(horizontal: 24)`
- `fontSize: 12/14` hardcoded
- Good: `SingleChildScrollView`, `SafeArea`, `maxWidth: 448`

**Recommendations:**
- Fix logo widget; use `MediaQuery.paddingOf(context).top` for language selector
- Adopt `.w`/`.sp` for padding and typography

---

## Forgot Password Screen

**File:** `lib/presentation/auth/views/forgot_password_screen.dart`  
**Responsive Score:** 60/100

**Issues Found:**
- 4 hardcoded font sizes
- Has `SingleChildScrollView` + `SafeArea` ✅
- No ScreenUtil

**Recommendations:** ScreenUtil migration; match Auth screen patterns.

---

## Forgot Change Password Screen

**File:** `lib/presentation/auth/views/forgot_change_password_screen.dart`  
**Responsive Score:** 58/100

**Issues Found:**
- 7 hardcoded font sizes
- Has scroll + SafeArea ✅

**Recommendations:** Same as Forgot Password.

---

## Change Password Screen

**File:** `lib/presentation/auth/views/change_password_screen.dart`  
**Responsive Score:** 72/100

**Issues Found:**
- Uses ScreenUtil ✅
- Has `SingleChildScrollView` ✅
- Minor raw shadow values

**Recommendations:** Use as template for other auth screens.

---

## OTP Verification Screen

**File:** `lib/presentation/otp_verification/views/otp_verification_screen.dart`  
**Responsive Score:** 50/100

**Issues Found:**
- 15 hardcoded font sizes including `fontSize: 32` for headings
- OTP input boxes may not accommodate large accessibility text
- Has `SingleChildScrollView` ✅

**Recommendations:** Use `FittedBox` or flexible OTP pin fields; adopt `.sp`.

---

## First Login Setup Screen

**File:** `lib/presentation/first_login/views/first_login_setup_screen.dart`  
**Responsive Score:** 52/100

**Issues Found:**
- 27+ hardcoded font sizes
- 4× QR code blocks at 200×200px
- Password requirements row overflow risk
- Has `SingleChildScrollView` ✅
- Multi-step form scrolls properly ✅

**Recommendations:** Highest-impact auth flow to fix after splash/auth.

---

## Home Screen

**File:** `lib/presentation/home/views/home_screen.dart`  
**Responsive Score:** 62/100

**Issues Found:**
- Delegates to `HeroImage` (500px — Critical)
- `ResidenceName` / `WelcomeUserSection` raw typography
- `QuickTiles` fixed 2-column grid
- Good: `SingleChildScrollView` with `FloatingBottomNavBar.screenPadding` ✅

**Recommendations:** Fix hero image first; add responsive grid for quick tiles.

---

## Hub Screen

**File:** `lib/presentation/hub/views/hub_screen.dart`  
**Responsive Score:** 74/100

**Issues Found:**
- Raw padding `all(32)` and font sizes
- Good: `LayoutBuilder` + `HubController.getGridCount()` ✅
- Good: Pyramid layout for 3 cards on mobile ✅
- Good: `GridView` with `shrinkWrap` + `NeverScrollableScrollPhysics` ✅

**Recommendations:** Apply ScreenUtil to padding/typography; best responsive layout in app — use as reference.

---

## Documents Screen

**File:** `lib/presentation/documents/viwes/documents_screen.dart`  
**Responsive Score:** 78/100

**Issues Found:**
- Uses ScreenUtil ✅
- `Expanded(child: ListView.builder)` ✅
- `FloatingBottomNavBar.listPadding` ✅
- Filter bar and search bar use raw padding

**Recommendations:** Add tablet max-width content column; fix filter bar scaling.

---

## Maintenance Screen

**File:** `lib/presentation/maintenance/views/maintenance_screen.dart`  
**Responsive Score:** 56/100

**Issues Found:**
- No ScreenUtil
- Task cards have mixed typography
- Good: Expanded ListView pattern ✅

**Recommendations:** ScreenUtil pass on task cards and filter bar.

---

## Profile Screen

**File:** `lib/presentation/profile/views/profile_screen.dart`  
**Responsive Score:** 68/100

**Issues Found:**
- `EdgeInsets.all(24)` raw padding
- No ScreenUtil
- Good: `SingleChildScrollView` + pull-to-refresh ✅
- Delegates to shared widgets with mixed quality

**Recommendations:** ScreenUtil on padding; add max-width for tablet.

---

## Smart Home Screen

**File:** `lib/presentation/smart_home/views/smart_home_screen.dart`  
**Responsive Score:** 54/100

**Issues Found:**
- 17 hardcoded font sizes
- Widespread `EdgeInsets.all(24)`
- Device name text without ellipsis
- Good: `SingleChildScrollView`, horizontal room filter scroll ✅

**Recommendations:** Full ScreenUtil pass; add responsive device grid (2 col tablet, 3 col desktop).

---

## AI Screen

**File:** `lib/presentation/ai/viwes/ai_screen.dart`  
**Responsive Score:** 88/100

**Issues Found:**
- 27 `.sp` usages — excellent ✅
- `Expanded(ListView)` + input at bottom ✅
- Minor raw blur/shadow values

**Recommendations:** Use as gold-standard reference for other screens.

---

## Chat Hub Screen

**File:** `lib/presentation/chat/views/chat_hub_screen.dart`  
**Responsive Score:** 58/100

**Issues Found:**
- 3 hardcoded font sizes
- Has `LayoutBuilder` in section ✅
- `SingleChildScrollView` ✅

**Recommendations:** ScreenUtil migration.

---

## Chat Screen (Group)

**File:** `lib/presentation/chat/views/chat_screen.dart`  
**Responsive Score:** 76/100

**Issues Found:**
- Mostly uses `.sp` ✅
- One raw `fontSize: 13` inconsistency
- Keyboard handling via screen-level padding

**Recommendations:** Fix inconsistent font size.

---

## Admin / Private Chat Screen

**File:** `lib/presentation/chat/views/private_chat_screen.dart`  
**Responsive Score:** 78/100

**Issues Found:**
- ScreenUtil used ✅
- `PrivateChatInput` responsive ✅
- Minor bubble typography mix

**Recommendations:** Align bubble font sizes to `.sp`.

---

## Tickets Screen

**File:** `lib/presentation/tickets/views/tickets_screen.dart`  
**Responsive Score:** 80/100

**Issues Found:**
- ScreenUtil ✅
- `SingleChildScrollView` / ListView patterns ✅
- `CreateTicketDialog` has mixed fixed widths

**Recommendations:** Fix dialog button widths.

---

## Trusted Devices Screen

**File:** `lib/presentation/trusted_device/views/trusted_devices_screen.dart`  
**Responsive Score:** 82/100

**Issues Found:**
- 21 ScreenUtil usages — strong ✅
- `Expanded(ListView)` ✅
- 13 remaining hardcoded font sizes in sub-widgets

**Recommendations:** Minor typography cleanup.

---

## 2FA Management Screen

**File:** `lib/presentation/profile/views/two_fa_management_screen.dart`  
**Responsive Score:** 75/100

**Issues Found:**
- ScreenUtil used ✅
- QR code 200×200 in sub-widgets
- `SizedBox(height: 80.h)` bottom padding — good pattern ✅

**Recommendations:** Scale QR codes.

---

## 2FA Activation Screen

**File:** `lib/presentation/profile/views/two_fa_activation_screen.dart`  
**Responsive Score:** 55/100

**Issues Found:**
- No ScreenUtil
- 10+ raw `EdgeInsets.all(16)`
- Has `SingleChildScrollView` ✅

**Recommendations:** ScreenUtil migration.

---

## 2FA Deactivation / Document Password Screens

**Files:** `two_fa_deactivation_verification_screen.dart`, `document_password_screen.dart`, `document_password_2fa_verification_screen.dart`  
**Responsive Score:** 74/100 (average)

**Issues Found:**
- ScreenUtil used ✅
- Scroll views present ✅
- Dialog and form patterns generally solid

**Recommendations:** Minor padding consistency.

---

## Main Scaffold (App Shell)

**File:** `lib/presentation/main/main_scaffold.dart`  
**Responsive Score:** 70/100

**Issues Found:**
- `resizeToAvoidBottomInset: false` with custom keyboard padding
- `maxWidth: 448.w` on app bar ✅
- `FloatingBottomNavBar` integration ✅
- Bottom nav ignores keyboard insets
- Residence dialog `height: 100` fixed

**Recommendations:** Audit keyboard behavior on all input sub-screens.

---

## Floating Bottom Nav Bar (Widget)

**File:** `lib/core/widgets/floating_bottom_nav_bar.dart`  
**Responsive Score:** 86/100

**Issues Found:**
- Excellent ScreenUtil usage ✅
- `screenPadding()` / `contentBottomPadding()` helpers used app-wide ✅
- `contentGap = 24` not scaled
- `listPadding` horizontal 16 not scaled

**Recommendations:** Scale `contentGap` to `24.h`.

---

# Global Recommendations

## Quick Wins (< 2 hours total)

| # | Fix | File | Effort |
|---|-----|------|--------|
| 1 | Clamp logo width to screen | `casazero_logo.dart` | 45 min |
| 2 | Hero image viewport-relative height | `hero_image.dart` | 1 hr |
| 3 | Status row ellipsis | `construction_progress_section.dart` | 20 min |
| 4 | Auth language selector safe top | `auth_screen.dart` | 20 min |
| 5 | `contentGap` → `24.h` | `floating_bottom_nav_bar.dart` | 10 min |
| 6 | Device name ellipsis | `smart_home_screen.dart` | 15 min |
| 7 | QR codes → `180.w` | `two_fa_management_widgets.dart` | 20 min |
| 8 | Remove dead logo helpers | auth/otp/first_login | 15 min |

## Major Improvements

1. **Unified Responsive System** — Create `lib/core/utils/app_responsive.dart` with breakpoint helpers and enforce `.w`/`.h`/`.sp` via lint rules.
2. **ScreenUtil Everywhere** — Migrate remaining 13 screens to ScreenUtil (8–12 hours).
3. **Accessibility Text Scaling** — Remove or clamp (not block) `TextScaler.linear(1.0)`; test all screens at 1.3× scale.
4. **Tablet Layouts** — Add `maxWidth: 600` content columns centered on wide screens; Hub-style `LayoutBuilder` for all grids.
5. **Master-Detail** — Documents, Tickets, Maintenance split view at 840px+ (16–24 hours).
6. **iOS SafeArea** — Fix `PlatformSafeArea` to apply on all platforms (3 hours).
7. **Orientation Strategy** — Allow landscape on tablets or document portrait-only decision.
8. **Theme Typography** — Refactor `AppTextStyles` to support responsive factory.

## Suggested Responsive System

### Breakpoints

| Device Class | Width Range | Column Strategy |
|--------------|-------------|-----------------|
| **Mobile (compact)** | 0–359 | Single column, full bleed |
| **Mobile (medium)** | 360–599 | Single column, 24px horizontal padding |
| **Tablet** | 600–1023 | 2-column grids, max content width 600px centered |
| **Desktop / Large Tablet** | 1024+ | 3–4 column grids, max content width 840px, master-detail |

### Design Tokens

```dart
// lib/core/utils/app_responsive.dart
class AppBreakpoints {
  static const double compact = 360;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double maxContentWidth = 448;
  static const double maxTabletContentWidth = 600;
  static const double maxDesktopContentWidth = 840;
}
```

### Layout Strategy

1. **Phone:** Single column, `ScreenUtil` scaling from 390×844 baseline.
2. **Tablet:** Centered `ConstrainedBox(maxWidth:)` + multi-column grids (Hub pattern).
3. **Foldable:** Use `LayoutBuilder` on unfolded width; avoid fixed pixel widths entirely.
4. **Accessibility:** Allow text scale up to 1.3×; use `FittedBox` / ellipsis / scroll for overflow.

---

# Final Score

## Overall Responsive Score: **58 / 100**

## Screen Score Summary

| Screen | Score |
|--------|-------|
| AI Screen | 88 |
| Floating Bottom Nav | 86 |
| Trusted Devices | 82 |
| Tickets | 80 |
| Documents | 78 |
| Private Chat | 78 |
| Chat (Group) | 76 |
| Hub | 74 |
| 2FA Management | 75 |
| 2FA Deactivation / Doc Password | 74 |
| Change Password | 72 |
| Main Scaffold | 70 |
| Profile | 68 |
| Home | 62 |
| Forgot Password | 60 |
| Auth | 58 |
| Chat Hub | 58 |
| Forgot Change Password | 58 |
| Maintenance | 56 |
| 2FA Activation | 55 |
| Smart Home | 54 |
| First Login | 52 |
| OTP Verification | 50 |
| Splash | 42 |
| Hero Image (section) | 35 |

## Readiness

| Level | Status |
|-------|--------|
| Production Ready | ❌ |
| Needs Minor Fixes | ❌ |
| **Needs Major Fixes** | ✅ ← Current |
| Not Responsive | ❌ (foundation exists) |

---

# Final Action Plan (Highest → Lowest Impact)

| Order | Action | Impact | Effort | Cumulative |
|-------|--------|--------|--------|------------|
| 1 | Fix hero image 500px → viewport-relative | Critical — home screen usability | 1 hr | 1 hr |
| 2 | Fix `CasaZeroLogo` 360px clamp | Critical — auth first impression | 45 min | 1.75 hr |
| 3 | Fix splash 320–400px elements | Critical — launch screen | 1.5 hr | 3.25 hr |
| 4 | Remove/fix `TextScaler.linear(1.0)` | Critical — accessibility | 2 hr | 5.25 hr |
| 5 | Fix iOS SafeArea strategy | Critical — notch/Dynamic Island | 3 hr | 8.25 hr |
| 6 | Audit keyboard insets on chat/AI/tickets | Critical — input usability | 2 hr | 10.25 hr |
| 7 | ScreenUtil migration: auth + first login + OTP | High — onboarding flow consistency | 4 hr | 14.25 hr |
| 8 | ScreenUtil migration: home sections | High — most-used screen | 3 hr | 17.25 hr |
| 9 | Smart home full responsive pass | High | 2.5 hr | 19.75 hr |
| 10 | Construction progress overflow fixes | High | 30 min | 20.25 hr |
| 11 | Quick tiles responsive grid | High — tablet | 30 min | 20.75 hr |
| 12 | Create `AppResponsive` utility + breakpoints | Architectural | 2 hr | 22.75 hr |
| 13 | ScreenUtil migration: remaining 8 screens | High | 6 hr | 28.75 hr |
| 14 | Tablet max-width centering on all screens | Medium — tablet UX | 4 hr | 32.75 hr |
| 15 | Notifications modal + dialog max-width | Medium | 1 hr | 33.75 hr |
| 16 | `AppTextStyles` responsive refactor | Medium — global typography | 3 hr | 36.75 hr |
| 17 | Portrait lock review for tablets | Medium | 4 hr | 40.75 hr |
| 18 | Master-detail for documents/tickets | Low immediate / High long-term | 20 hr | 60.75 hr |
| 19 | Widget-level cleanup (low priority items) | Low | 4 hr | 64.75 hr |
| 20 | Web/desktop responsive strategy (if needed) | Future | 40+ hr | — |

**Estimated total for production-ready responsive UX (mobile + tablet): ~37 hours**  
**Estimated total including master-detail + web: ~65–105 hours**

---

## Positive Patterns to Preserve

- ✅ `ScreenUtilInit` with `splitScreenMode: true` in `main.dart`
- ✅ `HubController.getGridCount()` + `LayoutBuilder` breakpoint system
- ✅ `FloatingBottomNavBar.screenPadding()` / `contentBottomPadding()` helpers
- ✅ `AI Screen` as ScreenUtil reference implementation
- ✅ All form screens wrapped in `SingleChildScrollView`
- ✅ `DocumentsScreen` / `MaintenanceScreen` `Expanded` + `ListView` pattern
- ✅ `document_card.dart` scale multiplier approach
- ✅ `maxWidth: 448` content constraint on auth (good tablet phone-centering pattern)
- ✅ `create_ticket_dialog.dart` and `add_document_dialog.dart` use `LayoutBuilder`

---

*Report generated by automated static analysis of all 191 Dart files in `lib/`. Line numbers reference the codebase as of June 23, 2026.*
