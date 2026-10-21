# Requirements — SafeSignal M.3 Unified UI/UX Redesign

## Overview

Milestone M.3 elevates the SafeSignal web (React/TypeScript) and Android (Flutter) applications to a
premium, modern, discreet, accessible, and cohesive visual experience across both platforms.  The
approved visual direction is **"Calm Urban Safety"**: a purposefully quiet aesthetic that centres the
commuter, reduces cognitive load, and earns trust without dramatic embellishment.

M.2A, M.2B, and M.2C are complete.  Reporting works on a physical Redmi A5.  Flutter ships offline
English/Kiswahili support.  This milestone is specification and visual layer only; it does not change
API contracts, reporting logic, incident categories, or support options.

---

## Scope Boundaries

**In scope**
- Shared design tokens (colours, typography, spacing, radius, shadows, motion)
- Light mode and dark mode support on both platforms
- Reusable UI component library (React) and widget set (Flutter)
- Reporting screen redesign across both platforms
- SafeHeader, Shell, and page-level layout on the React web app
- Welcome/home screen redesign on Flutter
- Purposeful, reduced-motion-aware micro-interactions
- WCAG 2.2 AA compliance across all visible UI
- English/Kiswahili bilingual layout support on Flutter
- Responsive React design (320 px → 1440 px)
- Quick Exit visual treatment and keyboard/gesture consistency
- Privacy-first UI posture (no identifying chrome, safe browser-history navigation)

**Out of scope**
- Any change to API endpoints, request/response schemas, field names, or enum values
- Any change to idempotency key logic, rate-limit handling, or retry semantics
- Any change to offline state model (Flutter has no local DB; this stays true)
- Adding new incident categories or support options
- Inventing emergency-response features or new helpline numbers
- Adding new npm or pub.dev production dependencies unless strictly necessary
- PostgreSQL integration, deployment, or CI/CD
- Admin screen redesign (prototype only; not part of public UX)
- Assistant UI redesign (separate concern; assistant is landing-screen-only)
- Committing or pushing any code

---

## Functional Requirements

### FR-1  Shared Design Token System

**FR-1.1** A single authoritative token file for the React app shall define all colour, shadow, spacing,
radius, and motion values as CSS custom properties, replacing any ad-hoc hex literals in component
files.

**FR-1.2** A matching Dart token file for the Flutter app shall declare all colour, spacing, radius,
and typography values as named constants, replacing magic numbers and inline hex literals scattered
across screen files.

**FR-1.3** Light-mode token values shall be identical to those already in `apps/frontend/src/index.css`
and `apps/mobile/lib/theme.dart`; no colour values shall change during tokenisation — only
naming and organisation change.

**FR-1.4** The token naming scheme shall be semantic (e.g. `--color-surface`, `--color-on-primary`,
`--space-4`, `--radius-card`) rather than purely descriptive of the raw value.

**FR-1.5** Both token files shall document which tokens correspond to each other, making cross-platform
drift visible at a glance.

---

### FR-2  Light and Dark Mode

**FR-2.1** The React web app shall fully implement a dark mode behind the existing `[data-theme="dark"]`
selector, which already carries complete dark-mode token values in `index.css`.  A theme toggle
shall be added (keyboard accessible, persisted to `localStorage`, respects `prefers-color-scheme`
as default).

**FR-2.2** All React components — including the header, shell, cards, inputs, buttons, badges, and
error banners — shall respond correctly to both themes using only the CSS custom properties
defined by the token system.

**FR-2.3** The Flutter app shall implement a `buildSafeSignalDarkTheme()` function in `theme.dart`
that mirrors the dark palette from the web tokens.  The `MaterialApp` shall expose a theme-mode
switch seeded from the system setting.

**FR-2.4** Dark mode text contrast ratios shall meet WCAG 2.2 AA minimums (4.5:1 for body text,
3:1 for large/bold text) on both platforms.

**FR-2.5** The dark-mode toggle state shall not affect any report draft, submission, or API call.

---

### FR-3  Typography and Spacing

**FR-3.1** The React app shall introduce a custom typeface from the Inter variable font family (self-
hosted from bunny.net or Google Fonts, loaded with `font-display: swap`, zero render-blocking).
If the font fails to load, the existing system-ui stack shall be the fallback.

**FR-3.2** A typographic scale shall be defined as tokens: `--text-xs` (11 px) through `--text-3xl`
(32 px), each with a matching `--leading-*` line-height.  Existing ad-hoc `text-[Npx]` Tailwind
literals in screen files shall be replaced with these scale tokens.

**FR-3.3** The Flutter app shall declare a complete `TextTheme` in `theme.dart` that maps
`displaySmall`, `headlineMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`,
`labelLarge`, and `labelSmall` to explicit `fontSize`, `fontWeight`, `height`, and `letterSpacing`
values consistent with the web typographic scale.

**FR-3.4** A spacing scale (`--space-1` = 4 px, `--space-2` = 8 px … `--space-16` = 64 px) shall
replace raw pixel padding values in component files.

**FR-3.5** Minimum touch-target size shall be enforced as a token (`--touch-min: 44px`) on the web
and as a constant (`kTouchMin = 48.0`) on Flutter.

---

### FR-4  Reusable Component Library — React

**FR-4.1** The existing `Button`, `Card`, `Input`, `GlassSurface`, and `StatusBadge` components shall
be updated to consume the new token system exclusively; their public props API shall not change.

**FR-4.2** A `ProgressRail` component shall be extracted from `IncidentTypeScreen` into
`src/components/ui/ProgressRail.tsx`.  It shall accept `steps: string[]` and `current: number`
props and be used by all three reporting step screens.

**FR-4.3** A `SelectionTile` component shall be extracted from `IncidentTypeScreen` and
`NextStepScreen` into `src/components/ui/SelectionTile.tsx`.  It shall handle the radio-tile
pattern (icon, label, description, check indicator, disabled state, hover/focus ring) for both
incident-type and support-option screens.

**FR-4.4** A `HelplineCard` component shall be extracted from `NextStepScreen` and
`ConfirmationScreen` into `src/components/ui/HelplineCard.tsx`, rendering a single helpline
row with accessible `tel:` link.

**FR-4.5** An `InlineBanner` component shall be extracted from error-display code in `NextStepScreen`
into `src/components/ui/InlineBanner.tsx`.  It shall accept `variant: 'error' | 'warning' | 'info'`
and `children`.

**FR-4.6** All components shall export their props interfaces.  Components shall not accept
`className` overrides that bypass token-defined colours or interactive states; however,
`className` may still be accepted for layout-only adjustments (margin, padding, width) as
is already the case in `Card.tsx`.

---

### FR-5  Reusable Widget Library — Flutter

**FR-5.1** A `SafeSignalTile` widget shall be extracted into `lib/widgets/safesignal_tile.dart`,
replacing the private `_IncidentTile` in `report_screen.dart` and `_OptionTile` in
`support_screen.dart`.  It shall accept `leading` (widget), `title`, `subtitle`, `badge`
(optional), `selected`, `enabled`, `onTap`, and expose correct `Semantics`.

**FR-5.2** A `StepHeader` widget shall be extracted into `lib/widgets/step_header.dart`,
encapsulating the step-counter label, heading text (`headlineMedium`), and optional sub-paragraph
that repeat across every screen.

**FR-5.3** A `SafeSignalBanner` widget shall be added to `lib/widgets/safesignal_banner.dart`,
replacing inline `_Notice` in `welcome_screen.dart`, the `confirmNotice` container in
`confirmation_screen.dart`, and the error display in `review_screen.dart`.
It shall accept `variant: SafeSignalBannerVariant` (`notice`, `warning`, `error`) with
the following colour semantics:
- `notice` → amber palette (prototype notice, confirm notice)
- `warning` → coral palette without border (not-emergency, timing-now danger note)
- `error` → coral palette with border, `liveRegion: true` (submission errors)

**FR-5.4** All extracted widgets shall live in `lib/widgets/` and be exported from a single
`lib/widgets/widgets.dart` barrel.

---

### FR-6  Reporting Screen Redesign — React

**FR-6.1** All three step screens (`IncidentTypeScreen`, `DetailsScreen`, `NextStepScreen`) shall
use the new `ProgressRail` component with the current step highlighted.

**FR-6.2** `IncidentTypeScreen` shall use the new `SelectionTile` component for all six incident
categories.  The tile layout, icon treatment, and selected-state colouring shall remain
semantically identical to the current behaviour; only the implementation moves into the
shared component.

**FR-6.3** `DetailsScreen` shall adopt the new spacing and typographic scale tokens throughout,
and the form's visual hierarchy shall be improved: the "optional" nature of every field shall
be reinforced by a visible label annotation rather than only the heading copy.

**FR-6.4** `NextStepScreen` shall use the new `SelectionTile` and `HelplineCard` components.
The inline error banner shall use `InlineBanner`.

**FR-6.5** `ConfirmationScreen` shall use `HelplineCard` and `InlineBanner`, and the reference
code block shall receive a dedicated visual treatment (monospace, letter-spacing, accessible
`aria-label` preserved).

**FR-6.6** The `LandingScreen` shall receive a focused visual polish pass: the hero section's
typographic scale shall use the new tokens; the process-step cards shall adopt the `Card`
component's new token-driven styles; and the "Corridor Safety Intelligence" section shall
retain its "Coming soon" state without adding new content.

**FR-6.7** `SafeHeader` shall be updated to use the token system.  The Quick Exit button shall
remain visually prominent, keyboard-accessible, and functionally identical.

---

### FR-7  Reporting Screen Redesign — Flutter

**FR-7.1** `WelcomeScreen` shall use the new `SafeSignalBanner` widget in place of the private
`_Notice` class, and shall adopt the new `SafeSignalColors` constants and `TextTheme`
throughout.

**FR-7.2** `ReportScreen` shall use the new `SafeSignalTile` and `StepHeader` widgets.
The incident-tile and timing-toggle layout shall remain semantically identical to the current
behaviour.

**FR-7.3** `SupportScreen` shall use the new `SafeSignalTile` widget.  Disabled options shall
retain their "Unavailable · In development" tag and dimmed treatment.

**FR-7.4** `ReviewScreen` and `ConfirmationScreen` shall adopt the new token system and
`SafeSignalBanner` for inline error states.  No change to submission logic, state machine,
or `SubmissionController`.

**FR-7.5** Every screen's `AppBar` shall apply the token-driven colours from `buildSafeSignalTheme`.
The `QuickExitButton` shall retain its coral treatment and semantics.

---

### FR-8  Purposeful Animations and Reduced-Motion Support

**FR-8.1** React: Transition durations shall be defined as tokens (`--duration-fast: 120ms`,
`--duration-base: 200ms`, `--duration-slow: 350ms`).  Only `background-color`, `border-color`,
`box-shadow`, `opacity`, and `transform` shall be transitioned; layout properties shall not.

**FR-8.2** React: A screen-entry animation (`opacity 0→1`, `translateY 8px→0`) shall be added
to the `<main>` element inside `Shell` using CSS.  Duration: `--duration-slow`.

**FR-8.3** React: The `prefers-reduced-motion` media query already zeroes all transitions globally
in `index.css`; this behaviour shall be preserved and verified for every new animation.

**FR-8.4** Flutter: `appRoute` in `navigation.dart` already respects `MediaQuery.disableAnimations`.
A new `FadeSlideTransition` helper shall be added to `navigation.dart` as the default
non-disabled route transition (fade + 8 dp upward slide, 280 ms).  When `disableAnimations`
is true, the existing zero-duration path is used unchanged.

**FR-8.5** Flutter: Tile selection feedback shall use a brief `AnimatedContainer` background
transition (200 ms) gated on `!MediaQuery.of(context).disableAnimations`.

**FR-8.6** Neither platform shall animate anything during or after report submission other than
the existing `LinearProgressIndicator` (Flutter) and button loading state (React).

---

### FR-9  WCAG 2.2 AA Accessibility

**FR-9.1** All interactive controls shall have a minimum touch/click target of 44 × 44 px (web)
or 48 × 48 dp (Flutter).  This is already implemented; it shall be verified and codified as a
test assertion or lint comment, not weakened.

**FR-9.2** All text and interactive elements shall meet contrast ratios: 4.5:1 for normal text,
3:1 for large text (≥ 18 px regular or ≥ 14 px bold).  Dark-mode values shall be separately
verified.

**FR-9.3** Focus rings shall be visible on all interactive elements on both platforms.  The
existing `focus-visible:ring-4 ring-[var(--color-focus)]` pattern shall be applied consistently
to any new or modified React component.  Flutter `InkWell`/`FilledButton` focus indicators
shall use a `FocusDecoration` consistent with the teal token.

**FR-9.4** Every image, icon, and decorative element shall have `aria-hidden="true"` / `focusable="false"`
on React and appropriate Flutter `Semantics(label: ...)` / `ExcludeSemantics` on Flutter.

**FR-9.5** All form fields shall maintain their existing `aria-describedby` wiring to hint and
error message elements; no change to label–input–description structure.

**FR-9.6** Every new component and widget shall include a comment noting its WCAG role (e.g.
`// Implements WCAG 1.4.3 contrast, 2.4.7 focus visible`).

**FR-9.7** Screen reader announcement regions (`role="alert"`, `role="status"`, `aria-live`) shall
be preserved exactly where they exist; none shall be removed or silenced.

**FR-9.8** The existing keyboard navigation order on the React app (skip link → header → main
heading → content) shall be preserved.

---

### FR-10  English/Kiswahili Layout Support

**FR-10.1** No new ARB keys shall be added in M.3.  Redesigned widgets shall consume the same
`AppLocalizations` keys already in `app_en.arb` and `app_sw.arb`.

**FR-10.2** All Flutter widgets must be tested visually at both locales for truncation, wrapping,
and overflow.  Kiswahili strings are generally longer; minimum tile height shall accommodate
the longest translated strings without ellipsis.

**FR-10.3** The language toggle (`SegmentedButton` in `WelcomeScreen`) shall remain in its
current position and behaviour; its visual style shall adopt the updated theme.

**FR-10.4** React web is English-only.  No i18n work is required for the web app in M.3.

---

### FR-11  Responsive React Design

**FR-11.1** The `Shell` component's existing breakpoint widths (390 px → 560 px → 640 px for
`default`; 390 px → 720 px → 960 px → 1040 px for `wide`) shall be preserved.

**FR-11.2** All reporting step screens shall be comfortable at 320 px (minimum) without horizontal
overflow, and legible at 1440 px.

**FR-11.3** The landing screen hero shall remain two-column (headline + action card) at `lg:`
breakpoint and single-column below, as currently implemented.

**FR-11.4** The `SafeHeader` max-width shall track the same responsive ladder as the `Shell`
content area to keep the Exit button always aligned with the content edge.

---

### FR-12  Quick Exit and Privacy Protections

**FR-12.1** The Quick Exit button in `SafeHeader` (React) shall remain visually prominent with
sufficient contrast in both light and dark mode.  Its `aria-label` text shall not change.

**FR-12.2** The `Escape` key handler registered in `SafeHeader` shall not be affected by any
animation or transition change.

**FR-12.3** The Flutter `QuickExitButton` widget shall remain in the `AppBar.actions` of every
screen, coral coloured, with its existing `quickExit()` semantics.

**FR-12.4** The dark-mode theme toggle shall not introduce any new browser storage beyond `localStorage`
for the theme preference key; no cookies, no session storage, no analytics.

**FR-12.5** No screen transition or animation shall delay or obscure the Quick Exit affordance.

---

### FR-13  Non-Functional / Preservation Constraints

**FR-13.1** Zero changes to `apps/backend/` in this milestone.

**FR-13.2** All API field names, enum literals, max-length constraints, and the idempotency-key
header contract shall be preserved verbatim.

**FR-13.3** The `ReportDraft`, `IncidentType`, `SupportOption`, `Timing`, `Helpline`, and field-
constant values in `report_draft.dart` shall not change.

**FR-13.4** The React `Screen` union type and state machine in `App.tsx` shall not change.

**FR-13.5** No new npm production dependencies shall be introduced beyond a web font (loaded via
`<link>` in `index.html`, not a package).  No new pub.dev production dependencies beyond what
is already in `pubspec.yaml`.

**FR-13.6** The Kiswahili translation content shall not be altered in M.3; translation review is
a separate work item tracked in `TRANSLATION.md`.

---

## Non-Functional Requirements

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-1 | Performance | Web: no new render-blocking resources; custom font loaded with `font-display: swap` and `preload` hint |
| NFR-2 | Performance | Web: total new CSS footprint ≤ 10 KB gzipped over current baseline |
| NFR-3 | Accessibility | WCAG 2.2 AA on all modified screens (automated axe pass + documented manual items) |
| NFR-4 | Reduced Motion | All new animations disabled when `prefers-reduced-motion: reduce` (web) or `disableAnimations` (Flutter) is true |
| NFR-5 | Privacy | Theme preference written to `localStorage` only when the user explicitly toggles; key name: `safesignal-theme`; value: `'dark'` or `'light'`.  First-load system-default resolution does not write to storage. |
| NFR-6 | Maintainability | No magic hex literals or pixel values outside the token files after M.3 |
| NFR-7 | Consistency | Visual equivalence between React and Flutter implementations of shared concepts (colours, radius, spacing) to within the constraints of each platform |
| NFR-8 | Safety | Quick Exit button reachable within one keyboard interaction (Escape or Tab-to-button + Enter) from any screen state |
