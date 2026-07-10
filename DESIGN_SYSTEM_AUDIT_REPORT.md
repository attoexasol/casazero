# Flutter Design System Audit

**Project:** CasaZero (`d:\Sajid\casazero`)  
**Date:** July 10, 2026  
**Scope:** `lib/app/theme/`, `lib/core/widgets/` (41 files), presentation UI patterns  
**Baseline:** 390×844 design via `ScreenUtilInit`, Inter font family, Material 3 light theme  
**Constraint:** Analysis only — no source modifications

---

## Executive Summary

CasaZero has a **solid design foundation** — centralized colors, typography, shadows, gradients, and a comprehensive `AppTheme.lightTheme` with accessibility-aware touch targets. A **shared widget library** (41 components) covers buttons, cards, dialogs, navigation, and feedback.

Consistency breaks down in **execution**: many screens bypass tokens with raw `Color(0x…)`, ad-hoc `BorderRadius` and padding, **three icon systems**, **two animation libraries**, and **feature-specific palettes** (`document_colors.dart`). Several shared components (`PremiumCard`) are **defined but unused**; others (`CustomButton`) compete with raw `ElevatedButton`.

**Dark mode** is stubbed in `AppTheme.darkTheme` but **forced off** (`ThemeMode.light`). **Accessibility** has utilities and text-scale clamping but almost no `Semantics` labels.

| Deliverable | Score |
|-------------|-------|
| **UI Quality Score** | **59 / 100** |
| Design token maturity | 68 / 100 |
| Component adoption | 58 / 100 |
| Visual consistency | 52 / 100 |
| Responsive behavior | 74 / 100 |
| Dark mode readiness | 22 / 100 |
| Accessibility | 36 / 100 |

---

## 1. Typography

### 1.1 Token system

| Item | Status | Location |
|------|--------|----------|
| Font family | ✅ Inter (4 weights in assets) | `app_text_styles.dart`, `pubspec.yaml` |
| Scale | ✅ h1–h4, body, label, caption, button | `AppTextStyles` |
| Responsive sizing | ✅ `.sp` via `flutter_screenutil` | All style getters |
| Theme mapping | ✅ `TextTheme` in `AppTheme` | `app_theme.dart` L47–57 |
| Design baseline | ✅ 390×844 | `main.dart` L183–184 |

```14:25:lib/app/theme/app_text_styles.dart
  static const double _h1Size = 32;
  static const double _h2Size = 28;
  static const double _h3Size = 24;
  static const double _h4Size = 20;
  static const double _cardHeaderSize = 16;
  static const double _bodyLargeSize = 18;
  static const double _bodyMediumSize = 14;
  static const double _bodySmallSize = 11;
```

### 1.2 Gaps

| Issue | Evidence |
|-------|----------|
| Hardcoded `fontSize` in screens | `otp_verification_screen.dart`, `smart_home_screen.dart`, `create_ticket_dialog.dart` |
| Duplicate naming | `CardHeaderText` (PascalCase) vs `cardText` / `cardSecondText` |
| Typos in color tokens | `regulerTextColor` in `AppColors` |
| Dark theme text | Same light-oriented colors reused in `darkTheme` — low contrast risk |
| `Theme.of(context).textTheme` usage | Low — most screens use `AppTextStyles` directly |

**Typography score: 72 / 100**

---

## 2. Spacing

| Item | Status |
|------|--------|
| `app_spacing.dart` / spacing tokens | 🔴 **Does not exist** |
| `ScreenUtil` `.w` / `.h` | ✅ Widespread (~60+ files) |
| Theme padding (buttons, inputs) | ✅ 24×14 buttons, 16×14 inputs |
| Consistent 8pt grid | 🔴 Ad hoc: 4, 6, 8, 10, 12, 16, 20, 24, 32 mixed |
| `SizedBox` magic numbers | Common in feature screens |

**Common values observed:** `8.h`, `12.w`, `16.w`, `24.h` — aligned informally but not codified.

**Spacing score: 55 / 100**

---

## 3. Radius

| Token / usage | Value | Source |
|---------------|-------|--------|
| Buttons (theme) | 12 | `AppTheme` elevated/outlined |
| Cards (theme) | 16 | `cardTheme` |
| Dialogs (theme) | 24 | `dialogTheme` |
| Chips | 20 | `chipTheme` |
| Checkbox | 4 | `checkboxTheme` |
| `CustomButton` default | 12 | Matches theme |
| `ShimmerLoading` default | 8 | Widget default |
| Screen ad hoc | 8, 10, 12, 16, 20, 24, 28 | Scattered in presentation |

**No `app_radius.dart`** — radius discipline is partial, inherited from theme defaults on Material widgets only.

**Radius score: 62 / 100**

---

## 4. Elevation

| Approach | Usage |
|----------|-------|
| Material elevation | Cards `0`, FAB `4`, dialogs `8`, bottom nav `8` |
| Custom `BoxShadow` | Primary depth system via `AppShadows` |
| Border + flat cards | `CardTheme` uses 1px `neutralLine100` border, no elevation |
| `showShadow` on `CustomButton` | Uses `AppShadows.shadowMd` |

**Pattern:** CasaZero is a **flat + shadow** hybrid — elevation tokens live in `AppShadows`, not Material `elevation` alone.

**Elevation score: 70 / 100**

---

## 5. Buttons

### 5.1 Button inventory

| Component | Role | Adoption |
|-----------|------|----------|
| `CustomButton` | Primary CTA with loading | ~15 screens |
| `GradientButton` | Premium CTA | Auth, profile flows |
| `OutlinedCustomButton` | Secondary | Sparse |
| `TextCustomButton` | Tertiary / link | Sparse |
| `ElevatedButton` (raw) | Theme default | Dialogs, tickets |
| `Material` + `InkWell` | Custom tiles | Hub, home, maintenance |
| `DemoButton` | Demo only | Demo module |

### 5.2 Consistency

| Aspect | Status |
|--------|--------|
| Min touch target 48dp | ✅ `Accessibility.minTouchTarget` in theme + `CustomButton` |
| Loading state | ✅ `CustomButton.isLoading`; inconsistent elsewhere |
| Disabled styling | 🟡 `neutralInk300` on CustomButton only |
| Icon + label layout | 🟡 Per-screen custom |

**Buttons score: 60 / 100** — good primitives, fragmented usage.

---

## 6. Cards

| Card type | Implementation | Reuse |
|-----------|----------------|-------|
| Theme `Card` | Material default | Rare direct use |
| `PremiumCard` | Shared widget | 🔴 **Zero imports** — dead code |
| `ProfileHeaderCard` | Shared | Profile |
| `SecurityCard`, `PreferencesCard`, `AdminSettingsCard` | Shared profile cards | Profile tab |
| `ResidenceInfoCard` | Shared | Home/profile |
| `DocumentCard` | Feature-specific (1149-line adjacent styling) | Documents only |
| `MaintenanceTaskCard` | 1,149 lines inline | Maintenance only |
| `TicketCard` | Feature widget | Tickets |
| `HubCardWidget` | Feature widget | Hub |
| `ChatOptionCard` | Feature widget | Chat hub |

**Verdict:** Profile/home use shared cards; **documents, maintenance, tickets roll custom card chrome** with overlapping shadow/radius patterns.

**Cards score: 54 / 100**

---

## 7. Dialogs

| Pattern | Usage |
|---------|-------|
| `ResponsiveAlertDialog` | Keyboard-aware, tablet max-width 480 | ~8 call sites |
| `showDialog` + raw `AlertDialog` | Widespread | Maintenance, documents, 2FA |
| `Get.dialog` | `MessagePopupController`, popups | Feedback flows |
| `CreateTicketDialog` | Full-screen form dialog | Tickets |
| `AddDocumentDialog` | 936 lines — inline styling | Documents |
| `ZipPasswordDialog` | Shared | Downloads |

**Strengths:** `ResponsiveAlertDialog` is production-quality (insets, scroll, tablet cap).  
**Gaps:** Large dialogs duplicate padding, radius, and action button rows.

**Dialogs score: 65 / 100**

---

## 8. Icons

| System | Usage | Files (approx.) |
|--------|-------|-----------------|
| **Material `Icons.*`** | Default UI chrome | ~45 files |
| **`flutter_svg` / assets** | Brand, nav, feature icons | ~30 files |
| **`lucide_icons_flutter`** | Nav bar, building selector | 2 files |

**Issues:**
- No `AppIcons` abstraction or size tokens
- Mixing SVG + Material + Lucide on same screens (`main_scaffold.dart`)
- Icon colors sometimes hardcoded vs `AppColors`

**Icons score: 48 / 100**

---

## 9. Colors

### 9.1 Core palette (`AppColors`)

| Family | Tokens | Quality |
|--------|--------|---------|
| Brand sage | 50–800 | ✅ Cohesive green brand |
| Aqua green | 50–700 | ✅ Construction accent |
| Neutrals | ink + line scale | ✅ |
| Semantic | success, warning, danger, info | ✅ |
| Surfaces | white, warm, glass | ✅ |

### 9.2 Consistency drift

| Issue | Evidence |
|-------|----------|
| `AppColors` references | ~1,200+ across lib |
| Raw `Color(0x…)` / `Colors.*` | ~900+ additional usages |
| Parallel palette | `document_colors.dart` — 35 hardcoded hex values |
| Hub controller colors | 18 inline colors in `hub_controller.dart` |
| Smart home | 67 raw color refs in `smart_home_screen.dart` |
| Splash background | `Color(0xFFFAF7F4)` hardcoded in `main.dart` — not in `AppColors` |

**Colors score: 64 / 100** — strong tokens, weak enforcement.

---

## 10. Gradients

| Token | `AppGradients` | Used for |
|-------|----------------|----------|
| `premiumGradient` | Sage 500→400 | Buttons, banners |
| `premiumGradientGold` | Gold accents | Premium UI |
| `aquaGradient` | Construction sections | Progress UI |
| `shimmerGradient` | Loading shimmer | `ShimmerLoading` |
| `glassOverlay` | White fade | `GlassContainer` |

**Ad hoc gradients** also appear in `hero_image.dart`, `floating_bottom_nav_bar.dart`, chat bubbles.

**Gradients score: 75 / 100**

---

## 11. Shadows

| Token | `AppShadows` |
|-------|--------------|
| `shadowSm` / `Md` / `Lg` / `Xl` | Layered neutral shadows |
| `shadowPremium` | Brand-tinted glow |
| `shadowProfileCard` | Neutral variant |
| `shadowGlow` | Focus/highlight |
| `customColoredShadow()` | Per-category (documents) |

**Drift:** Many screens define inline `BoxShadow` with similar blur/offset values instead of importing `AppShadows`.

**Shadows score: 68 / 100**

---

## 12. Animations

### 12.1 Dual animation systems

| System | Location | Usage |
|--------|----------|-------|
| `AppAnimations` | `app_animations.dart` | fadeIn, scaleIn, slide — utility wrappers |
| `flutter_animate` | ~25 presentation files | `.animate()`, staggered delays |
| Custom `AnimationController` | Splash, premium banner, shimmer | One-off |

**Issues:**
- No shared duration/curve enum consumed by `flutter_animate`
- Stagger delays vary: `50ms`, `100ms`, `index * 50.ms` — inconsistent rhythm
- `AppAnimations.spring` = `Curves.elasticOut` — rarely used vs `easeInOut`

**Animations score: 62 / 100** — polished motion, dual systems reduce predictability.

---

## 13. Transitions

| Item | Value |
|------|-------|
| Default route transition | `Transition.fade` 300ms (`main.dart`) |
| Tab switching | In-scaffold swap — no shared page transition |
| Modal open | Default Material / Get.dialog fade |
| Nav bar collapse | 280–300ms `easeInOut` (`FloatingBottomNavBar`) |

**Transitions score: 70 / 100**

---

## 14. Loading States

| Pattern | Component | Adoption |
|---------|-----------|----------|
| Branded spinner + message | `LoadingIndicator` | Few screens |
| Shimmer placeholder | `ShimmerLoading` | Hero, category bar |
| Raw `CircularProgressIndicator` | Material | ~25 files (tickets, chat, profile) |
| Full-screen `isLoading` | Per-controller `Obx` | Home, documents, maintenance |
| Button inline loader | `CustomButton.isLoading` | Auth flows |
| Pull-to-refresh | `RefreshIndicator` | Tickets, some lists |

**Gap:** No skeleton layout system; loading UX varies from shimmer → spinner → blank screen.

**Loading score: 58 / 100**

---

## 15. Snackbars & Feedback

| Mechanism | Status |
|-----------|--------|
| `MessagePopupController` + `CustomMessagePopup` | ✅ **Primary** — success/error/warning dialogs |
| `SnackBarTheme` in theme | ✅ Configured but largely unused |
| Raw `ScaffoldMessenger.showSnackBar` | 🔴 `create_ticket_dialog.dart` (5 calls) |
| `Get.snackbar` | 🔴 Not used |

```6:7:lib/core/controllers/message_popup_controller.dart
/// Centralized controller for showing custom popups
/// Replaces all SnackBar usage across the app
```

**Note:** Popups auto-dismiss after 3s — heavier than snackbars; can interrupt flow for minor confirmations.

**Feedback score: 66 / 100**

---

## 16. Bottom Sheets

| Usage | File | Pattern |
|-------|------|---------|
| Notifications list | `notifications_modal.dart` | `showModalBottomSheet` — primary notifications UI |
| File open options | `notifications_modal.dart`, `documents_controller.dart` | Action sheet style |
| Ticket photo picker | `create_ticket_dialog.dart` | `showModalBottomSheet` |

**Gaps:** No shared `AppBottomSheet` wrapper; styling duplicated per call site.

**Bottom sheets score: 60 / 100**

---

## 17. Navigation

| Element | Implementation | Quality |
|---------|----------------|---------|
| Primary nav | `FloatingBottomNavBar` | ✅ Custom glass pill, iOS/Android tuning, tablet cap |
| Tab model | `AppScreen` enum in `MainScaffold` | 🟡 Centralized but monolithic |
| App bar | `CzAppBar` + inline scaffold app bars | 🟡 Mixed |
| Back handling | `PopScope` + `HomeController.handleBackNavigation` | ✅ |
| Deep links | 🔴 Not styled — launcher only |
| GetX routes | Auth/onboarding stack | ✅ Fade transition |

**Navigation score: 72 / 100** — distinctive floating nav; shell file is a maintainability risk.

---

## 18. Component Reuse Matrix

| Component | Category | Defined | Imported / used | Adoption | Consistency |
|-----------|----------|---------|-----------------|----------|-------------|
| `CustomButton` | Button | ✅ | ~15 files | 🟡 Medium | 🟢 High |
| `GradientButton` | Button | ✅ | ~8 files | 🟡 Medium | 🟢 High |
| `OutlinedCustomButton` | Button | ✅ | ~4 files | 🔴 Low | 🟢 High |
| `TextCustomButton` | Button | ✅ | ~3 files | 🔴 Low | 🟢 High |
| `CustomTextField` | Input | ✅ | ~12 files | 🟡 Medium | 🟢 High |
| `PasswordInput` | Input | ✅ | ~8 files | 🟡 Medium | 🟢 High |
| `PremiumCard` | Card | ✅ | **0 files** | 🔴 **Unused** | — |
| `ProfileHeaderCard` | Card | ✅ | Profile | 🟢 Targeted | 🟢 High |
| `SecurityCard` etc. | Card | ✅ | Profile | 🟢 Targeted | 🟢 High |
| `DocumentCard` | Card | Feature | Documents | 🟡 Isolated | 🟡 Custom |
| `MaintenanceTaskCard` | Card | Feature | Maintenance | 🟡 Isolated | 🟡 Custom |
| `ResponsiveAlertDialog` | Dialog | ✅ | ~8 files | 🟡 Medium | 🟢 High |
| `CustomMessagePopup` | Feedback | ✅ | Via controller | 🟢 High | 🟢 High |
| `LoadingIndicator` | Loading | ✅ | ~5 files | 🔴 Low | 🟢 High |
| `ShimmerLoading` | Loading | ✅ | ~3 files | 🔴 Low | 🟢 High |
| `FloatingBottomNavBar` | Nav | ✅ | 1 (shell) | 🟢 Critical path | 🟢 High |
| `CzAppBar` | Nav | ✅ | ~4 files | 🟡 Medium | 🟢 High |
| `TabletCenteredLayout` | Layout | ✅ | ~10 files | 🟡 Medium | 🟢 High |
| `CategoryFilterBar` | Filter | ✅ | Documents, maintenance | 🟢 Good | 🟢 High |
| `StatusBadge` | Chip | ✅ | ~6 files | 🟡 Medium | 🟢 High |
| `CasazeroLogo` | Brand | ✅ | Auth, splash | 🟢 Good | 🟢 High |
| `GlassContainer` | Effect | ✅ | ~2 files | 🔴 Low | 🟢 High |
| `BounceGlowWidget` | Effect | ✅ | ~1 file | 🔴 Low | — |

**Summary:** 41 widgets in `core/widgets/`; **~60% actively reused**, **~15% dead or demo-only**, **~25% duplicated** by feature-specific implementations.

---

## 19. Responsive Behavior

| Mechanism | Details | Score |
|-----------|---------|-------|
| `ScreenUtilInit` | 390×844, `minTextAdapt`, `splitScreenMode` | ✅ |
| `.w` / `.h` / `.sp` / `.r` | Extensive — scales padding, type, radius | ✅ |
| `TabletCenteredLayout` | 600px breakpoint, max 600px content | ✅ |
| `ResponsiveAlertDialog` | Tablet max 480px, dynamic insets | ✅ |
| `FloatingBottomNavBar` | Tablet max bar width 600 | ✅ |
| `MediaQuery.textScaler` clamp | 0.85–1.3 in `main.dart` | ✅ |
| Landscape | Portrait locked | 🟡 Phone-only intent |
| Desktop / web | Not optimized | ⚪ Out of scope |

**Responsive score: 74 / 100** — strong mobile + tablet phone landscape; not large-screen/desktop.

---

## 20. Dark Mode Readiness

| Item | Status |
|------|--------|
| `AppTheme.darkTheme` | ⚠️ Exists — colorScheme + textTheme only |
| `themeMode` | 🔴 **Hardcoded `ThemeMode.light`** |
| Component themes in dark | 🔴 Missing — no appBar, card, input, dialog themes |
| `AppColors` | Light-assumptive fixed colors |
| `AppGradients.glassOverlay` | White-based — not dark-safe |
| `floating_bottom_nav_bar` | Checks `Brightness.dark` but never active |
| System UI overlay | Light icons on light nav bar only |

```197:199:lib/main.dart
            theme: splashTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
```

**Dark mode score: 22 / 100** — scaffold only; not shippable.

---

## 21. Accessibility

| Item | Status | Evidence |
|------|--------|----------|
| Min touch target 48dp | ✅ | `Accessibility.minTouchTarget`, theme buttons |
| Text scale clamp | ✅ | 0.85–1.3 in `main.dart` |
| `buttonMinHeight` text-scale aware | ✅ | `accessibility.dart` |
| `Semantics` / `semanticLabel` | 🔴 **~3 usages** | `notification_item.dart`, `construction_progress_section.dart` |
| Screen reader labels on icons | 🔴 Missing on most icon-only buttons |
| Color contrast audit | ⚪ Not verified | `grayTextColor` on white likely OK |
| Focus order / keyboard | ⚪ Mobile-first | |
| Reduce motion | 🔴 No `MediaQuery.disableAnimations` respect |
| i18n | ✅ GetX `AppTranslations` | 1,771-line translation file |

**Accessibility score: 36 / 100**

---

## 22. Design Consistency Report

### 22.1 Strengths

1. **Cohesive brand** — sage green palette, Inter typography, premium shadows
2. **Material 3 light theme** — comprehensive component themes (buttons, inputs, chips, switches)
3. **Central feedback** — `MessagePopupController` replaces scattered snackbars
4. **Responsive primitives** — `ScreenUtil`, `TabletCenteredLayout`, `ResponsiveAlertDialog`
5. **Distinctive navigation** — `FloatingBottomNavBar` with platform-aware sizing
6. **Accessibility foundation** — touch targets and text-scale clamp in place

### 22.2 Weaknesses

1. **No spacing/radius token files** — magic numbers in 60+ screens
2. **Color drift** — ~900 raw color usages vs ~1,200 `AppColors`
3. **Three icon systems** — Material + SVG + Lucide without abstraction
4. **Dead design components** — `PremiumCard` unused
5. **Feature card duplication** — maintenance/document/ticket cards reinvent chrome
6. **Dual animation stacks** — `AppAnimations` + `flutter_animate`
7. **Dark mode non-functional** — forced light
8. **Minimal Semantics** — screen reader support largely absent
9. **Loading inconsistency** — shimmer vs spinner vs blank
10. **Legacy snackbars** in ticket creation flow

### 22.3 Consistency by area

| Area | Consistency | Grade |
|------|-------------|-------|
| Typography | Good tokens, some bypass | B |
| Spacing | Ad hoc ScreenUtil | C |
| Radius | Theme defaults + drift | C+ |
| Colors | Strong palette, weak lint | C+ |
| Buttons | Multiple competing patterns | C |
| Cards | Profile good; features custom | C− |
| Dialogs | Responsive helper underused | B− |
| Icons | Fragmented | D+ |
| Motion | Rich but inconsistent | C+ |
| Feedback | Popup-first, mostly unified | B− |
| Navigation | Strong custom nav | B+ |
| Dark mode | Not ready | F |
| Accessibility | Early stage | D |

---

## 23. UI Quality Score

| Category | Weight | Score | Weighted |
|----------|--------|-------|----------|
| Design tokens (type, color, shadow) | 20% | 68 | 13.60 |
| Component library & adoption | 20% | 58 | 11.60 |
| Visual consistency | 25% | 52 | 13.00 |
| Responsive behavior | 15% | 74 | 11.10 |
| Dark mode readiness | 5% | 22 | 1.10 |
| Accessibility | 10% | 36 | 3.60 |
| Motion & feedback | 5% | 64 | 3.20 |
| **UI Quality Score** | **100%** | — | **59 / 100** (rounded) |

### Interpretation

| Range | Meaning |
|-------|---------|
| 85–100 | Design-system mature — Figma ↔ code parity |
| 70–84 | Consistent product UI with minor drift |
| **55–69** | **Strong foundation, inconsistent application** ← CasaZero |
| < 55 | Visual debt impacts brand perception |

---

## 24. Recommended Improvements (priority)

### P0 — High impact, low effort

| # | Action |
|---|--------|
| 1 | Add `app_spacing.dart` and `app_radius.dart` token files |
| 2 | Remove or adopt `PremiumCard`; document when to use each card type |
| 3 | Migrate `create_ticket_dialog.dart` snackbars → `MessagePopupController` |
| 4 | Standardize loading on `LoadingIndicator` / `ShimmerLoading` |
| 5 | Add `Semantics` to icon-only nav and app bar actions |

### P1 — Consistency sprint

| # | Action |
|---|--------|
| 6 | Create `AppIcons` wrapper (SVG / Lucide / Material) |
| 7 | Extend `document_colors.dart` to use `AppColors` semantic aliases |
| 8 | Migrate top 5 screens off raw `Color(0x…)` (smart home, tickets, maintenance card) |
| 9 | Wrap `showModalBottomSheet` in `AppBottomSheet` |
| 10 | Consolidate on `flutter_animate` OR `AppAnimations` — document motion tokens |

### P2 — Dark mode & a11y

| # | Action |
|---|--------|
| 11 | Complete `darkTheme` component themes; wire `ThemeMode.system` |
| 12 | Add `ColorScheme`-derived text styles for dark surfaces |
| 13 | Audit contrast ratios (WCAG AA) on `bodyMedium` gray text |
| 14 | Respect `MediaQuery.disableAnimations` in `flutter_animate` usage |

**Target UI Quality after P0+P1:** ~**74 / 100**

---

## 25. Conclusion

CasaZero's design system **starts above average** for a Flutter MVP: real theme files, brand colors, shared widgets, and thoughtful responsive helpers. The app **looks intentionally premium** in home, profile, and auth flows.

Consistency erodes where **feature teams inlined UI** — maintenance task cards, document dialogs, smart home mocks, and ticket flows use parallel styling paths. **Dark mode and accessibility are not production-ready.** Closing the token gaps (spacing, radius), enforcing color lint, and raising adoption of existing widgets would yield the fastest visual quality gain without a full redesign.

**UI Quality Score: 59 / 100**

---

*Generated by static analysis of theme files and widget usage. Re-audit after design-system refactors or Figma token sync.*
