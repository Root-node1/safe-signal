# SafeSignal v1.0 — Independent Design and UX Review

**Date:** 23 October 2026
**Scope:** React web app (`apps/frontend`) and Flutter Android app (`apps/mobile`)
**Reviewer:** Independent UI/UX reviewer (design-audit worktree)
**Standards applied:** WCAG 2.2 AA, Web Interface Guidelines (Vercel Labs), mobile platform conventions

---

## Executive Summary

SafeSignal presents a strong foundation: a tokenized design system shared across React and Flutter, rigorous accessibility scaffolding, and unusually honest privacy messaging for a prototype. The reporting journey is calm and consistent, with Quick Exit prominent and data handling transparent.

The most significant gaps are: incomplete web font wiring (Inter weight 900 missing), no navigation-guard for the in-memory web form, AdminScreen isolation from the shared token system, and Android safety omissions (backup disabled, screenshot blocking, status-bar icons). These are fixable without changing the reporting logic.

---

## 1. Current Strengths

### 1.1 Tokenized, Cross-Platform Design System

`apps/frontend/src/index.css` defines a complete token set — colors (light + dark), spacing (4 px base), border-radius, typography scale, and motion durations — all as CSS custom properties. `apps/mobile/lib/design_tokens.dart` mirrors these as Dart constants with documented correspondence. `apps/mobile/lib/theme.dart` maps tokens to a Material 3 `ColorScheme` and shared `TextTheme`.

- Both platforms resolve colors through the token system, not raw hex.
- Dark mode is fully specified on both platforms with matching palettes.
- The typography scale is deliberately set: `--text-xs` (11 px) through `--text-5xl` (46 px), with line-height pairings.

### 1.2 Accessibility Foundation

WCAG 2.2 AA is baked into the component layer:

- **Focus management:** Every interactive element uses `focus-visible:ring-4 ring-[var(--color-focus)]` with offset (e.g. `Button.tsx:27`, `SelectionTile.tsx:60`). The app avoids `outline: none` without replacement.
- **Skip link:** `Shell.tsx:20` provides a visible-on-focus skip-to-content link.
- **Live regions:** `InlineBanner.tsx:42` uses `role="alert"` for errors/warnings and `role="status"` for info. `ConfirmationScreen.tsx:78` uses `aria-live="polite"` for copy feedback. Flutter equivalents use `Semantics(liveRegion: true)`.
- **Screen-reader summaries:** `ProgressRail.tsx:58` injects an `sr-only` "Step N of M" announcement.
- **Keyboard navigation:** `IncidentTypeScreen.tsx:152` and `NextStepScreen.tsx:109` implement arrow-key roving tabindex for radio groups.
- **Touch targets:** CSS `--touch-min: 44px`; Flutter `kTouchMin: 48.0 dp`. Buttons enforce `min-h-[44px]`.
- **Reduced motion:** Global `@media (prefers-reduced-motion: reduce)` in `index.css:169` zeroes all transitions/animations. Flutter checks `MediaQuery.disableAnimations`.

### 1.3 Privacy-First Messaging

`docs/PRIVACY.md` is a standout — 16 sections, versioned, explicitly marking what is and isn't implemented. In-app messaging reinforces this:

- **Transparency about limitations:** `LandingScreen.tsx:262` states "reports are stored temporarily and may be cleared." `ConfirmationScreen.tsx:109` repeats it.
- **No emergency-service confusion:** Emergency disclaimers appear on the landing page (`LandingScreen.tsx:266`), the incident screen (`NextStepScreen.tsx:218`), and the assistant modal (`AssistantModal.tsx:244`).
- **Honest about non-anonymity:** `PRIVACY.md:13` explains why a report can be identifying from its own contents (timestamp + route + plate).
- **Draft storage disclosure:** Web keeps drafts in memory only (`PRIVACY.md:88`); mobile asks for one permission only — internet (`PRIVACY.md:102`).

### 1.4 Calm, Consistent Reporting Journey

- The three-step flow (incident → details → support) uses a `ProgressRail` on web (`ProgressRail.tsx:24`) and a `StepHeader` on mobile (`step_header.dart:15`), both showing step position.
- All optional fields are explicitly labeled "(optional)" (`DetailsScreen.tsx:44-79`).
- Error recovery is handled per-state: timeout, offline, network, key conflict, rate limit — each with specific copy (`ReviewScreen` `_message()` in `review_screen.dart:244`).

### 1.5 Thoughtful Quick Exit

- Web: Escape key listener in `SafeHeader.tsx:27` + visible Exit button + footer reminder (`ConfirmationScreen.tsx:162`).
- Mobile: Floating Action-level prominent Exit button in AppBar (`quick_exit_button.dart:17`).
- `quickExit.ts:4` redirects to a neutral URL and renames the document title.

### 1.6 Reduced Motion and Performance

- `prefers-reduced-motion` is respected globally (`index.css:169`).
- Screen entry animation (`index.css:188`) uses only opacity + transform.
- No layout reads in render; lists are small (< 12 items).

---

## 2. Important Design Inconsistencies

### 2.1 AdminScreen Isolated from Token System

**File:** `apps/frontend/src/screens/AdminScreen.tsx:17,62,125-138,149-193`

`AdminScreen` uses a completely separate hardcoded palette (`#F7F5F2`, `#1B1F23`, `#0F5C5C`, `#4A5259`, `#0F5C5C`) with raw hex values throughout. It does not import or use any CSS custom properties from `index.css`. The kiro spec acknowledges this (`design.md:53-55`) but it remains unfixed. This screen also lacks the dark-mode toggle — it has no dark variant at all.

### 2.2 Web Font Not Fully Wired

**File:** `apps/frontend/index.html:9`, `apps/frontend/src/index.css:128-130`

`index.html` preloads Inter with weights `400,500,600,700` — but the design spec calls for weight 900 (`design.md:162`). The `body` font-family in `index.css:130` still uses `system-ui` with a comment saying Inter is "activated in Task 9." Headlines use `font-black` (900), which will render as faux-bold fallback until resolved. The font is loaded but never applied.

### 2.3 Platform Interaction Model Divergence

| Aspect | React Web | Flutter Mobile |
|---|---|---|
| Progress indicator | Horizontal bar + labels (`ProgressRail`) | Text label: "Step 1 of 3" (`StepHeader`) |
| Selection tiles | `button` + `role="radio"` + checkmark SVG | `RadioListTile`-style with `Radio` icons |
| Theme toggle | Present in header (`ThemeToggle.tsx:17`) | System-only (`app.dart:63`), no in-app toggle |
| Error display | `InlineBanner` with role | `SafeSignalBanner` with `liveRegion` |
| Submit loading | Text changes to "Submitting…" (`NextStepScreen.tsx:198`) | Button text + `CircularProgressIndicator` (`review_screen.dart:200-202`) |

The divergent patterns are a maintenance burden and create subtle UX differences users may notice if they use both platforms.

### 2.4 Theme Toggle Parity Gap

React exposes a manual light/dark toggle (`SafeHeader.tsx:53`). Flutter uses `ThemeMode.system` only (`app.dart:63`) with no way for a user to override. This is documented as intentional for this milestone (`design.md:244-245`) but is a user-facing inconsistency.

### 2.5 Font Size Mismatch at Screen Headings

React screen headings use `--text-2xl` (28 px) in `IncidentTypeScreen.tsx:131` and `DetailsScreen.tsx:27`. Flutter `headlineMedium` is 26 px (`theme.dart:66`). The mismatch is small but visible when comparing the two platforms side-by-side, especially since both label the same content ("What happened?", "Any details to add?").

### 2.6 Emoji Icons in Web UI

**Files:** `LandingScreen.tsx:250` (🛡), `IncidentTypeScreen.tsx`, `NextStepScreen.tsx:172` (⚠), `ConfirmationScreen.tsx:104,108` (✓, •)

The web UI uses Unicode emoji (🛡, ⚠, ✓, •) for status icons. Flutter uses proper Material icons. Emoji rendering varies by platform/browser and can appear pixelated or wrong-colored. This is a visual consistency issue.

### 2.7 Mobile Missing Clipboard Copy for Reference Code

**File:** `apps/mobile/lib/screens/confirmation_screen.dart:78`

Flutter's confirmation screen uses `SelectableText` (user must manually select) while React uses a Copy-to-clipboard button (`ConfirmationScreen.tsx:67-75`). PRIVACY.md section 12 explicitly discusses clipboard handling as a consideration — the web side addresses it with a deliberate copy button; the mobile side does not, creating a usability gap on the platform where manual selection is harder.

---

## 3. P0 / P1 Usability and Privacy Issues

### P0: Android Backup Not Disabled

**Files:** `apps/mobile/lib/main.dart`, `docs/PRIVACY.md:106-108`

`PRIVACY.md:106` explicitly states: "Android's automatic backup is **not** currently switched off for this app." While the app writes nothing to disk today, this is a latent safety vulnerability. As soon as the save-for-later feature (section 4.3) ships, incident details would be backed up to Google's servers. This must be addressed before any on-device persistence is introduced.

**Fix:** Set `android:allowBackup="false"` in `AndroidManifest.xml`.

### P0: No Navigation Guard for Unsaved Web Form State

**Files:** `apps/frontend/src/App.tsx:13,34,80,96`, `apps/frontend/src/screens/DetailsScreen.tsx`, `docs/PRIVACY.md:88-90`

The web app holds all form state in React memory (`App.tsx:13: "State only. Nothing is persisted in the browser."`). There is no `beforeunload` handler or router guard. If a user accidentally refreshes, closes the tab, or navigates away mid-flow, all report details are lost with no warning. PRIVACY.md documents this behavior but does not address the usability risk of silent data loss.

**Fix:** Add a `beforeunload` event listener that fires when the reporting flow has unsaved data (e.g., after incident type is selected, or any detail field is non-empty).

### P1: Admin Screen Accessible Without Authentication

**Files:** `apps/frontend/src/App.tsx:53-54`, `apps/frontend/src/lib/prototype.ts:5`

The admin dashboard is reachable via `/#admin` with no authentication. `prototype.ts:5` acknowledges: "this flag only shows the 'Prototype' badge and allows the mock-data admin screen. It is a build-time cosmetic setting, NOT an authorization mechanism." If this prototype ships with `PROTOTYPE=false`, the admin screen shows a "Not available" message — but with any misconfiguration, mock report data is exposed. The single shared admin key (`SAFESIGNAL_ADMIN_KEY`) is backend-only.

**Fix:** Move the admin gate to the backend or require an explicit admin auth check before rendering even the mock view.

### P1: Screenshots and Recents Not Blocked on Android

**Files:** `docs/PRIVACY.md:149-151, 373`

PRIVACY.md section 5 states Quick Exit "does not erase: The Android recent-apps thumbnail" and that screenshots "are possible today." Section 15 lists "Whether the Android app blocks screenshots" as an open item. For a safety reporting app where users may be under observation, this is a real privacy risk.

**Fix:** Set `android:secure="true"` on the root activity in `AndroidManifest.xml` (also prevents screen recording and recent-apps thumbnails).

### P1: Status Bar Icons Not Theme-Aware on Android

**File:** `apps/mobile/lib/theme.dart` (no system UI overlay configuration)

`theme.dart` defines `appBarFg: Colors.white` for light theme (`theme.dart:127`), but there is no `SystemChrome.setSystemUIOverlayStyle` configuration. On Android with light theme, the status bar icons would be white-on-white (invisible), or the system defaults may not match. Flutter's `AppBar` handles this automatically via `foregroundColor`, but the Scaffold background and status bar area need explicit handling.

**Fix:** Add `SystemChrome.setSystemUIOverlayStyle` in `app.dart` to match `ThemeMode`.

### P1: Web Reporting Flow State Not Addressable

**File:** `apps/frontend/src/App.tsx:14-19`

The reporting flow uses React state only — no URL sync for step, timing, incident, or selected support option. Users cannot bookmark, share, or use browser back/forward to navigate the flow. The hash is used only for `/#admin`. This contradicts Web Interface Guidelines: "URL reflects state."

The `NextStepScreen` acknowledges this with `RELOAD_CAVEAT` (`NextStepScreen.tsx:13`), but it is a workaround, not a fix.

**Fix:** Sync reporting flow state to URL hash/query params (e.g., `#/report?step=details&timing=after&incident=harassment`).

### P1: Missing `name` Attributes on Form Inputs

**File:** `apps/frontend/src/components/ui/Input.tsx:45-60`

The `Input` component does not forward a `name` attribute to the underlying `<input>`. While `htmlFor`/`id` pairing exists (`Input.tsx:30-31`), the lack of `name` means form serialization and autocomplete context are weakened. Web Interface Guidelines: "Inputs need `autocomplete` and meaningful `name`."

**Fix:** Allow `name` to be passed through `...props` and set meaningful defaults.

### P1: Web Heading Wrapping Can Produce Widows

**Files:** `LandingScreen.tsx:64`, `IncidentTypeScreen.tsx:131`

Headings like "Report incidents." + "Travel with more awareness." use `<br>` for line breaks. At certain viewport widths, a single word can wrap to its own line (widow), creating visual awkwardness. Web Interface Guidelines recommend `text-wrap: balance` or `text-pretty` on headings.

**Fix:** Apply `text-wrap: balance` to `h1` and `h2` elements.

### P0: `prefers-reduced-motion` Does Not Respect `color-scheme` for Form Controls

**File:** `apps/frontend/src/index.css` (no `color-scheme` declaration)

Web Interface Guidelines: "`color-scheme: dark` on `<html>` for dark themes (fixes scrollbar, inputs)." The app supports dark mode via `data-theme="dark"` but does not declare `color-scheme` on the root. This means browser-native form controls (e.g., if a `<select>` is ever added) will not render correctly in dark mode, and scrollbars may not theme properly.

**Fix:** Add `color-scheme: light dark;` to `:root`.

### P1: Assistant Modal Has No Escape Confirmation

**File:** `apps/frontend/src/assistant/AssistantModal.tsx:68-98`

The `AssistantModal` intercepts `Tab` for focus trapping (`AssistantModal.tsx:74`) but explicitly does NOT intercept Escape — this is correct per the comment ("DO NOT intercept Escape. Let Escape bubble up to document/window so SafeHeader's quickExit() triggers!"). However, this means pressing Escape inside the assistant closes the assistant AND triggers Quick Exit (redirects to Google). A user who just wants to close the modal instead gets yanked to a neutral page, losing their place entirely. This is surprising behavior masked as a shortcut.

**Fix:** Consider intercepting Escape when the modal is open to close the modal first, then let a second Escape trigger Quick Exit. Or add an explicit "Close" affordance with clear labeling.

---

## 4. P2 Improvements

### 4.1 Missing `<meta name="theme-color">`

**File:** `apps/frontend/index.html:6`

No `<meta name="theme-color">` matching the page background. On mobile browsers (Safari PWA, Android Chrome), this means the browser UI (address bar, tab switcher) won't match the app's canvas color. Should use a `data-theme` attribute selector or a script that sets it dynamically.

### 4.2 Missing Touch Interaction Optimizations

**File:** `apps/frontend/src/index.css:124-133`

- No `touch-action: manipulation` on interactive elements (prevents double-tap zoom delay).
- No `-webkit-tap-highlight-color` set intentionally (defaults to browser blue highlight).
- No `overscroll-behavior: contain` on the assistant modal (`AssistantModal.tsx:188`) or other overlay surfaces.

### 4.3 Flutter: No Text-Scale Clamping

**Files:** Flutter screens (`report_screen.dart`, `review_screen.dart`, etc.)

Flutter respects system font scaling by default, but very large text scales can break the layout of tightly packed screens (e.g., the review summary rows, the step counter label). Consider capping `MediaQuery.textScaleFactor` at 1.5x or using `AnimatedDefaultTextStyle` with `overflow: clip`.

### 4.4 Web Font Fallback Strategy

**File:** `apps/frontend/src/index.css:128-130`

The `font-family` stack uses `system-ui` as the first fallback. Since Inter is loaded via CDN (bunny.net), a network failure means users get system-ui until retry. A `font-display: swap` descriptor would provide FOIT/FOUT fallback behavior, but the current preload link uses `&display=swap` which is URL-based, not descriptor-based. Consider adding a local `@font-face` with `font-display: swap` as a fallback.

### 4.5 No Locale Switching on Web

**File:** `apps/frontend/src/App.tsx`

The web app has no locale selector. The Flutter app supports English and Kiswahili (`app.dart:65-66`). The web app is English-only. PRIVACY.md and the kiro spec mention future web localization, but there's no scaffolding for it. If the web app is intended to serve Kenyan commuters, Swahili support is a meaningful gap.

### 4.6 Admin Dashboard Lacks Design System Integration

Beyond the hardcoded palette (`AdminScreen.tsx:17`), the admin screen uses raw Tailwind class strings (`AdminScreen.tsx:62: "min-h-screen bg-[#F7F5F2]"`) instead of the token variable classes used elsewhere. It also lacks the screen-entry animation, focus management patterns, and skip links used in the public-facing Shell.

### 4.7 Emoji Icon Replacement

Beyond the inconsistency noted in section 2.6, the ⚠ emoji in `InlineBanner` contexts (`IncidentTypeScreen.tsx` not directly, but `NextStepScreen.tsx:172`) should use a proper SVG icon component for visual sharpness and color control. The 🛡 emoji (`LandingScreen.tsx:250`) renders differently across platforms and cannot be styled with the color system.

### 4.8 Flutter: AppBar Title Doesn't Use Design Tokens

**File:** `apps/mobile/lib/screens/report_screen.dart:78`

Every Flutter screen hardcodes `const Text('SafeSignal')` as the AppBar title (`report_screen.dart:78`, `review_screen.dart:107`, `support_screen.dart:45`, `confirmation_screen.dart:36`). The AppBar background uses `appBarBg: SafeSignalColors.ocean` (`theme.dart:126`), but the title text size and weight aren't customized — they rely on Material defaults, creating a subtle inconsistency with the web header's 16 px / `font-bold` / `tracking-tight` treatment.

### 4.9 No `aria-current` or `aria-describedby` for Active Progress Steps

**File:** `apps/frontend/src/components/ui/ProgressRail.tsx`

The `ProgressRail` visually highlights the current step (`ProgressRail.tsx:46`) but does not set `aria-current="step"` on the active label. Screen reader users hear the sr-only "Step N of M" summary, but the individual step labels lack current-step semantics.

### 4.10 Flutter: Discard Confirmation Action Order

**File:** `apps/mobile/lib/widgets/discard_confirmation.dart:27-42`

The discard confirmation dialog places the destructive "Discard" action last (rightmost) and "Cancel" first (leftmost). On Android, the rightmost button is typically the default/affirmative action. This layout is correct for the pattern (destructive is last), but the "Restore" action in the restore dialog (`welcome_screen.dart:224`) is also last, creating a slightly inconsistent mental model: sometimes last = affirmative, sometimes last = destructive.

---

## 5. Specific Recommendations for React (Web)

### Priority 1 — Must Fix

1. **Apply Inter font and add weight 900** — Update `index.html:9` to include `900` in the weight list. Update `index.css:128` to set `font-family: 'Inter', system-ui, ...`.
2. **Add `beforeunload` guard** — In `App.tsx`, register a `beforeunload` listener when `screen.name` is not `'landing'` and `submission.current` is being built. This protects the in-memory form state.
3. **Add `color-scheme: light dark`** to `:root` in `index.css:4`.
4. **Add `name` attribute pass-through** to the `Input` component (`Input.tsx:4`). Provide meaningful `name` values in `DetailsScreen.tsx` (e.g., `name="route"`, `name="vehicle"`).
5. **Add `text-wrap: balance`** to `h1` and `h2` selectors in `index.css` or via a utility class.

### Priority 2 — Should Fix

6. **Add `<meta name="theme-color">`** to `index.html` with a script that updates it on theme change.
7. **Add `aria-current="step"`** to the active `ProgressRail` step label (`ProgressRail.tsx:50`).
8. **Refactor `AdminScreen`** to use CSS token variables instead of hardcoded hex colors, or clearly isolate it as a separate design system for internal tools.
9. **Replace emoji icons** with SVG components in `LandingScreen` (shield), `NextStepScreen`/`IncidentTypeScreen` (warning), and `ConfirmationScreen` (checkmark/bullet).
10. **Add `touch-action: manipulation`** to body-level interactive elements.
11. **Consider Escape-key refinement for AssistantModal** — intercept first Escape to close the modal, let second Escape trigger Quick Exit.

### Priority 3 — Nice to Have

12. **Sync reporting flow state to URL** so back/forward/bookmark works mid-flow.
13. **Add `-webkit-tap-highlight-color: transparent`** to body or interactive elements.
14. **Consider `@supports (text-wrap: balance)`** for progressive enhancement of heading wrapping.

---

## 6. Specific Recommendations for Flutter (Mobile)

### Priority 1 — Must Fix

1. **Set `android:allowBackup="false"`** in `AndroidManifest.xml` — critical for the planned save-for-later feature.
2. **Set `android:secure="true"`** on the root activity — blocks screenshots and recent-apps thumbnails.
3. **Add `SystemChrome.setSystemUIOverlayStyle`** in `app.dart` for theme-aware status bar icons (light icons on dark AppBar, dark on light).

### Priority 2 — Should Fix

4. **Add in-app theme toggle** — Mirror the web app's ThemeToggle for user control over light/dark mode. Use `setState` in `_SafeSignalAppState` to update `themeMode`.
5. **Add a Copy button for the reference code** in `confirmation_screen.dart` — parity with web. Use `Clipboard.setData` + visual feedback.
6. **Cap text-scale factor** — Wrap screens in a `Builder` that clamps `MediaQuery.textScaleFactor` at 1.5 to prevent layout breakage on very large fonts.
7. **Add `aria-current` equivalent** — The Flutter equivalent of current step indication uses `StepHeader` text; consider adding a visual dot/indicator to match the web `ProgressRail`'s active segment styling.

### Priority 3 — Nice to Have

8. **Replace hardcoded AppBar titles** — Extract `'SafeSignal'` to use the app's typography tokens consistently across all screens.
9. **Review discard dialog action order** — Ensure consistent "affirmative on right, destructive on left" mental model across restore and discard dialogs.
10. **Add `semanticsLabel` to the AppBar** for consistent screen-reader announcement of the app name across navigations.

---

## 7. Compliance Checklist Summary

| Guideline | Status | Notes |
|---|---|---|
| WCAG 2.2 AA contrast | Pass | Documented in `design.md:599-608` |
| Keyboard navigation | Pass | Arrow-key roving tabindex on radio groups |
| Focus visible | Pass | `focus-visible:ring-4` on all interactive elements |
| `prefers-reduced-motion` | Pass | Global CSS + Flutter `disableAnimations` check |
| Skip link | Pass | `Shell.tsx:20` |
| Live regions for async | Pass | `InlineBanner` role, `Semantics(liveRegion)` |
| Semantic HTML headings | Pass | `h1` → `h2` → `h3` hierarchy |
| `autocomplete` on inputs | Partial | Uses `autoComplete="off"` but no `name` attributes |
| `beforeunload` guard | Fail | No navigation guard for unsaved form state |
| `color-scheme` declaration | Fail | Not set on `:root` |
| URL reflects state | Fail | Reporting flow state not in URL |
| `meta theme-color` | Fail | Not set |
| `touch-action: manipulation` | Fail | Not set on interactive elements |
| Text-wrap balance on headings | Fail | Not applied |
| Dark mode form controls | Partial | Theme works but no `color-scheme` declaration |
| Android screenshots blocked | Fail | Not set in manifest |
| Android backup disabled | Fail | Not set in manifest |

---

*End of review. This document was produced by an independent reviewer working in an isolated Agent Manager worktree. No application source code was modified.*
