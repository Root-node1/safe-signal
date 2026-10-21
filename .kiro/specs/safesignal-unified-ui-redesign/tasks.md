# Implementation Tasks — SafeSignal M.3 Unified UI/UX Redesign

Each task is independently implementable and verifiable.  Complete them in order; later tasks
build on earlier ones.  No task touches the backend, API contracts, or reporting logic.  Do not
commit or push until approved.

---

## Task 1 — Extend CSS Design Tokens (React)

**Goal:** Add the new semantic token groups to `index.css` so all subsequent React tasks can
consume them.  No component behaviour changes.

**Files to change**
- `apps/frontend/src/index.css`

**Changes**
1. Under the `:root` block, after the existing glassmorphism tokens, add:
   - Spacing tokens `--space-1` through `--space-16` (4 px base)
   - Border-radius tokens `--radius-sm` through `--radius-full`
   - Typography tokens `--text-xs` through `--text-3xl` with matching `--leading-*` values
   - Motion tokens `--duration-fast`, `--duration-base`, `--duration-slow`, `--ease-standard`,
     `--ease-decelerate`
   - Touch target token `--touch-min: 44px`
2. Add all matching values under the `[data-theme="dark"]` block where they differ (most motion
   and spacing tokens are the same in both themes; they do not need to be duplicated).
3. Update the `body` font-family to prepend `'Inter'` ahead of the existing system-ui stack.
4. Add the `@keyframes screen-enter` rule and the `.screen-enter` utility class.

**Do not change**
- Any existing token names or hex values
- The `prefers-reduced-motion` global reset block
- The `.glass-panel` utility
- The `.skip-link` utility

**Verification**
- `npm run build` in `apps/frontend` exits 0 with no TypeScript errors.
- Open `index.css` and confirm every new token appears in `:root` and, where relevant,
  `[data-theme="dark"]`.

---

## Task 2 — Add Flutter Design Tokens and Dark Theme

**Goal:** Create the Flutter token file and add the dark-theme builder to `theme.dart`.

**Files to create**
- `apps/mobile/lib/design_tokens.dart`

**Files to change**
- `apps/mobile/lib/theme.dart`
- `apps/mobile/lib/app.dart`

**Changes**
1. Create `design_tokens.dart` with `kSpace*`, `kRadius*`, `kTouchMin`, `kDuration*` constants
   as specified in the design document §2.3.
2. In `theme.dart`:
   - Expand the `TextTheme` in `buildSafeSignalTheme()` to cover all eight roles listed in
     design §3.2.
   - Add `buildSafeSignalDarkTheme()` that uses a `ColorScheme.dark(...)` seeded from the
     dark-mode colour values listed in design §2.1.  All dark hex values already exist in the
     web `index.css`; use those exact values.
3. In `app.dart`, pass `darkTheme: buildSafeSignalDarkTheme()` and
   `themeMode: ThemeMode.system` to `MaterialApp`.

**Do not change**
- Any existing `SafeSignalColors` constant names or light-mode values
- Any screen, widget, or navigation file
- `pubspec.yaml`

**Verification**
- `flutter analyze` in `apps/mobile` exits 0 with no issues.
- With the emulator/device set to dark mode, the `WelcomeScreen` AppBar should show a dark
  background.  (Visual confirmation only; no automated test required.)

---

## Task 3 — Add Flutter Widget Barrel and New Base Widgets

**Goal:** Create the three new Flutter widgets (`SafeSignalTile`, `StepHeader`, `SafeSignalBanner`)
and the barrel export.  No screen files are changed yet.

**Files to create**
- `apps/mobile/lib/widgets/safesignal_tile.dart`
- `apps/mobile/lib/widgets/step_header.dart`
- `apps/mobile/lib/widgets/safesignal_banner.dart`
- `apps/mobile/lib/widgets/widgets.dart`

**Changes**
1. `safesignal_tile.dart` — implement `SafeSignalTile` as described in design §5.8.
   - Required props: `title`, `selected`, `onTap` (nullable).
   - Optional: `leading`, `subtitle`, `badge`, `enabled`, `semanticLabel`.
   - Use `AnimatedContainer` for background; gate animation on
     `MediaQuery.of(context).disableAnimations`.
   - Use `kRadiusLg` for border radius, `kTouchMin` for minimum height.
   - Apply `Semantics` with `inMutuallyExclusiveGroup`, `checked`, `enabled`.
2. `step_header.dart` — implement `StepHeader`.
   - Props: `stepLabel` (String, e.g. "Step 1 of 3"), `title` (String), `subtitle` (String?).
   - Uses `text.labelLarge` for step label, `text.headlineMedium` for title,
     `text.bodyLarge` for subtitle.
   - Include `Semantics(header: true)` on the title.
3. `safesignal_banner.dart` — implement `SafeSignalBanner`.
   - Props: `variant` (`SafeSignalBannerVariant` enum: `notice`, `warning`, `error`),
     `title`, `body`, optional `titleColor`.
   - Colour mapping as described in design §5.9.
   - Border radius `kRadiusLg`.
   - `error` variant wraps in `Semantics(liveRegion: true)`.
4. `widgets.dart` — re-export all four widget files (including the existing
   `quick_exit_button.dart` which already lives in `lib/widgets/`).

**Do not change**
- Any existing screen or widget file
- `quick_exit_button.dart`

**Verification**
- `flutter analyze` exits 0.
- `flutter build apk --debug` succeeds (or equivalent dry-run).

---

## Task 4 — Refactor Flutter Screens to Use New Widgets

**Goal:** Replace private widget classes in all Flutter screens with the new shared widgets,
and apply token-based spacing and radius throughout.

**Files to change**
- `apps/mobile/lib/screens/welcome_screen.dart`
- `apps/mobile/lib/screens/report_screen.dart`
- `apps/mobile/lib/screens/support_screen.dart`
- `apps/mobile/lib/screens/review_screen.dart`
- `apps/mobile/lib/screens/confirmation_screen.dart`

**Changes**
1. `welcome_screen.dart`:
   - Replace both `_Notice` usages with `SafeSignalBanner`.
   - Replace hardcoded padding with `kSpace6` / `kSpace4` constants.
   - Import from `'../widgets/widgets.dart'` and `'../design_tokens.dart'`.
   - Remove the private `_Notice` class (it is now in `safesignal_banner.dart`).
2. `report_screen.dart`:
   - Add `StepHeader(stepLabel: l.stepOf(1, 3), title: l.whatHappenedTitle)` at the top of
     the `ListView`.
   - Replace all `_IncidentTile` usages with `SafeSignalTile`.
   - Replace the timing-now `Text` with
     `SafeSignalBanner(variant: SafeSignalBannerVariant.warning, title: '', body: l.dangerNote)`.
   - Replace hardcoded padding and border-radius values with token constants.
   - Remove the private `_IncidentTile` class.
3. `support_screen.dart`:
   - Replace all `_OptionTile` usages with `SafeSignalTile`.
   - Replace the error `Text` with `SafeSignalBanner(variant: SafeSignalBannerVariant.error, ...)`.
   - Add `StepHeader`.
   - Replace hardcoded values with token constants.
   - Remove private `_OptionTile` class.
4. `review_screen.dart`:
   - Replace the inline error `Container` decoration with
     `SafeSignalBanner(variant: SafeSignalBannerVariant.error, ...)`.  Preserve the enclosing
     `Semantics(liveRegion: true)` — `SafeSignalBanner` with `error` variant adds this internally,
     so the outer `Semantics` wrapper can be removed.
   - Replace the hardcoded `const EdgeInsets.all(24)` ListView padding with `EdgeInsets.all(kSpace6)`.
   - Replace the `Card` border-radius literal `16` with `kRadiusLg`.
5. `confirmation_screen.dart`:
   - Replace the amber `confirmNotice` `Container` with
     `SafeSignalBanner(variant: SafeSignalBannerVariant.notice, title: '', body: l.confirmNotice)`.
   - Replace the teal-border reference-code `Container` with a styled `Card` using `kRadiusLg`
     radius, 2 dp teal border, and white fill — retaining the existing `SelectableText` for the code.
   - Replace `const EdgeInsets.all(24)` padding and `const EdgeInsets.all(16)` inner padding
     with token constants (`kSpace6`, `kSpace4`).
   - Replace `BorderRadius.circular(16)` literals with `kRadiusLg`.

**Do not change**
- Any submission logic, `SubmissionController` calls, or navigation pushes
- `QuickExitButton` usage or `quickExit()` call sites
- ARB key references (`l.someKey`)
- Enum values in `IncidentType`, `SupportOption`, `Timing`

**Verification**
- `flutter analyze` exits 0.
- Manual smoke test on device or emulator: complete the full reporting flow in both English and
  Kiswahili.  Every screen should display correctly in both locales.  Quick Exit should still
  work on every screen.

---

## Task 5 — Add Flutter Screen-Transition Animation

**Goal:** Replace the plain `MaterialPageRoute` in `navigation.dart` with a `FadeSlideTransition`
that respects `disableAnimations`.

**Files to change**
- `apps/mobile/lib/navigation.dart`

**Changes**
1. Import `design_tokens.dart`.
2. Replace the current `MaterialPageRoute` path with a `PageRouteBuilder` that runs a
   combined `FadeTransition` + `SlideTransition` (offset `0.0, 0.03` → `0.0, 0.0`) at
   `kDurationSlow`.  Reverse transition uses `kDurationBase`.
3. The zero-duration path for `disableAnimations` is unchanged.

**Exact implementation reference:** design §7.3.

**Do not change**
- Any screen file
- The function signature of `appRoute<T>`

**Verification**
- `flutter analyze` exits 0.
- On a device with animations enabled, pushing `ReportScreen` shows a subtle fade-up.
- On a device with "Remove animations" in Developer Options enabled, the transition is instant.

---

## Task 6 — Create React UI Components (ProgressRail, SelectionTile, HelplineCard, InlineBanner)

**Goal:** Build the four new React components.  No screen files are changed yet.

**Files to create**
- `apps/frontend/src/components/ui/ProgressRail.tsx`
- `apps/frontend/src/components/ui/SelectionTile.tsx`
- `apps/frontend/src/components/ui/HelplineCard.tsx`
- `apps/frontend/src/components/ui/InlineBanner.tsx`

**Files to change**
- `apps/frontend/src/components/ui/index.ts`

**Changes**
1. `ProgressRail.tsx` — implement as described in design §5.2.
   - `<nav aria-label="Report progress"><ol>` with `<li>` per step.
   - Coloured bar (teal for done/active, border-subtle for upcoming), `--duration-base` transition.
   - Label text below each bar.
   - `<p class="sr-only">Step N of M: Step Name</p>` for screen readers.
   - Respects `motion-reduce:transition-none`.
2. `SelectionTile.tsx` — implement as described in design §5.3.
   - `<button role="radio" aria-checked aria-disabled>` inside a list item.
   - Icon container, label, description, badge, selected check-circle.
   - Colour transitions using CSS custom property tokens.
   - `tabIndex` prop for roving focus.
   - `onKeyDown` prop for arrow-key navigation (callers supply the handler).
   - `focus-visible:ring-4 ring-[var(--color-focus)]` focus ring.
3. `HelplineCard.tsx` — implement as described in design §5.4.
   - Single `<li>` with name, detail text, and `<a href="tel:...">` call button.
   - Call button: `min-h-[44px]`, teal background, `aria-label="Call {name} at {tel}"`.
4. `InlineBanner.tsx` — implement as described in design §5.5.
   - `role` defaults to `"alert"` for error/warning, `"status"` for info.
   - Colour mapping: error → coral, warning → amber, info → teal-subtle.
   - Optional `title` in bold above `children`.
5. `index.ts` — add named exports for all four new components.

**Do not change**
- Existing `Button`, `Card`, `Input`, `GlassSurface`, `StatusBadge` components
- Any screen file

**Verification**
- `npm run build` in `apps/frontend` exits 0.
- TypeScript strict mode: zero `any` types in new components.

---

## Task 7 — Add Theme Toggle (React)

**Goal:** Implement the dark-mode toggle and wire it into `SafeHeader`.

**Files to create**
- `apps/frontend/src/lib/theme.ts`
- `apps/frontend/src/components/ui/ThemeToggle.tsx`

**Files to change**
- `apps/frontend/src/components/SafeHeader.tsx`
- `apps/frontend/src/components/ui/index.ts`

**Changes**
1. `theme.ts`:
   - Export `getInitialTheme(): 'light' | 'dark'` — reads `localStorage.getItem('safesignal-theme')`,
     falls back to `prefers-color-scheme`.
   - Export `applyTheme(t: 'light' | 'dark', persist?: boolean): void` — sets
     `document.documentElement.dataset.theme`; only writes to `localStorage` when `persist` is
     `true`.  This prevents an unintended storage write on first page load.
   - Export `toggleTheme(current: 'light' | 'dark'): 'light' | 'dark'` — flips and calls
     `applyTheme(next, true)`.
2. `ThemeToggle.tsx`:
   - Props: `theme: 'light' | 'dark'`, `onToggle: () => void`.
   - `<button>` with `aria-label` and `aria-pressed`.
   - Sun SVG icon (light mode) / Moon SVG icon (dark mode) — both inline, `aria-hidden`.
   - `min-h-[44px] min-w-[44px]`, `focus-visible:ring-4 ring-[var(--color-focus)]`.
   - `motion-reduce:transition-none`.
3. `SafeHeader.tsx`:
   - Add `useState` for `theme` (initialised from `getInitialTheme()`).
   - Call `applyTheme(theme, false)` in a `useEffect([])` on mount — applies the attribute
     without writing to storage.
   - Render `<ThemeToggle>` between the wordmark and the Exit button.
   - On toggle: call `toggleTheme(theme)`, update state.

**Do not change**
- `quickExit()` call sites or keyboard handler
- The Exit button's `aria-label`, styling, or position
- Any screen or reporting component

**Verification**
- `npm run build` exits 0.
- Clicking the toggle in a browser switches between light and dark visual themes.
- Refreshing the page preserves the selected theme.
- `prefers-color-scheme: dark` in DevTools is respected on first load.

---

## Task 8 — Refactor React Screens to Use New Components

**Goal:** Replace ad-hoc patterns in reporting screens with the new shared components and token
variables.  The only behavioural change is the addition of `ProgressRail` to step screens.

**Files to change**
- `apps/frontend/src/screens/IncidentTypeScreen.tsx`
- `apps/frontend/src/screens/DetailsScreen.tsx`
- `apps/frontend/src/screens/NextStepScreen.tsx`
- `apps/frontend/src/screens/ConfirmationScreen.tsx`

**Changes per screen**

`IncidentTypeScreen.tsx`:
1. Import and render `ProgressRail` at the top (`steps={STEPS}` where `STEPS` is the existing
   `as const` array, `current={0}`).
2. Replace the `StepIndicator` component (the `<nav>` with progress bars) with `ProgressRail`.
   The `StepIndicator` function can be deleted from this file.
3. Replace the six option buttons with `SelectionTile` components.  Arrow-key `onKeyDown`
   handler moves to the new component's prop.
4. Replace the error `<div role="alert">` with `<InlineBanner variant="error">`.
5. Replace the bottom info card with `<InlineBanner variant="info">`.
6. Replace all `text-[Npx]` Tailwind literals with the new CSS token equivalents
   (e.g. `text-[26px]` → `text-[var(--text-2xl)]`).

`DetailsScreen.tsx`:
1. Import and render `ProgressRail` at the top (`current={1}`).
2. Remove the `<div>Step 2 of 3</div>` text.
3. Annotate each `Input` label with `(optional)` in muted text using the `hint` prop
   (the hint text already exists; the visual label annotation is a small addition).
4. Replace `text-[Npx]` literals with token equivalents.

`NextStepScreen.tsx`:
1. Import and render `ProgressRail` at the top (`current={2}`).
2. Remove the existing `<div>Step 3 of 3</div>` text.
3. Replace the four `<button role="radio">` tiles with `SelectionTile` components.
4. Replace the helpline `<li>` items with `HelplineCard` components inside a `<ul>`.
5. Replace the `<div role="alert">` error block with `<InlineBanner variant="error">`.
6. Replace `text-[Npx]` literals with token equivalents.

`ConfirmationScreen.tsx`:
1. Replace the helpline `<li>` items with `HelplineCard` components.
2. Replace the submission status notice with `<InlineBanner variant="info">`.
3. Apply reference-code token styles: `font-mono text-[var(--text-2xl)] sm:text-[var(--text-3xl)] tracking-[0.15em]`.
4. Replace `text-[Npx]` literals with token equivalents.

**Do not change**
- `onSelect`, `onBack`, `onContinue`, `onSubmit`, `onRestart` callback signatures
- Any error state logic or submission logic
- `SUPPORT_RESOURCES` import or helpline values
- `STEPS` / `OPTIONS` data arrays (move them if necessary but keep the exact values)

**Verification**
- `npm run build` exits 0.
- Full manual flow in browser: Landing → Incident → Details → Support → Confirmation.
- Dark mode toggle works correctly on every screen.
- Keyboard navigation: Tab key reaches every interactive element; arrow keys work in
  radiogroups; Escape triggers Quick Exit from any screen.

---

## Task 9 — Polish LandingScreen and SafeHeader (React)

**Goal:** Apply token cleanup, Inter font, screen-entry animation, and the theme toggle to the
landing screen and header.

**Files to change**
- `apps/frontend/index.html`
- `apps/frontend/src/screens/LandingScreen.tsx`
- `apps/frontend/src/components/Shell.tsx`
- `apps/frontend/src/components/ui/Button.tsx`
- `apps/frontend/src/components/ui/Card.tsx`
- `apps/frontend/src/components/ui/Input.tsx`

**Changes**
1. `index.html`:
   - Fix the placeholder `<title>frontend</title>` → `<title>SafeSignal</title>`.
   - Add `<link rel="preconnect" href="https://fonts.bunny.net">`.
   - Add the Inter font `<link rel="preload">` tag with `onload` swap pattern as specified
     in design §3.1.
   - Add `<noscript>` fallback.
2. `LandingScreen.tsx`:
   - Replace `text-[Npx]` Tailwind literals with token equivalents throughout.
   - The hero section badge, headline, subheading, action card, process-step cards,
     coming-soon section, and privacy notice all receive token-based sizing.
   - No content or layout changes — only token substitution and minor spacing refinements.
3. `Shell.tsx`:
   - Add `screen-enter` CSS animation class to the `<main>` element.
   - Ensure `motion-reduce:` variant disables it.
4. `Button.tsx`, `Card.tsx`, `Input.tsx`:
   - Replace any remaining raw pixel values (e.g. `min-h-[52px]`) with token equivalents
     where CSS custom properties can be used.  Where Tailwind requires a pixel value
     (e.g. `min-h-[44px]`), add a comment referencing the `--touch-min` token.

**Do not change**
- `LandingScreen` component structure, props, or routing callbacks
- Any content strings (headlines, descriptions, button labels)
- `PROCESS_STEPS` data array

**Verification**
- `npm run build` exits 0.
- In a browser, the landing screen loads with Inter (check DevTools → Network → Fonts).
- The screen-entry fade-up plays on first load.
- With `prefers-reduced-motion: reduce` set in DevTools, the animation does not play.
- Dark mode toggle produces a visually correct dark landing screen.

---

## Task 10 — Accessibility Verification Pass

**Goal:** Confirm WCAG 2.2 AA compliance across all modified screens on both platforms, and
document the results.

**Files to change**
- `apps/frontend/src/components/ui/ProgressRail.tsx` (any a11y fixes found)
- `apps/frontend/src/components/ui/SelectionTile.tsx` (any a11y fixes found)
- Any screen file where issues are found

**Process**
1. **Automated — React:** Use the **axe DevTools browser extension** (Chrome/Firefox, no install
   required) against each of the five public screens (Landing, Incident, Details, Support,
   Confirmation) in both light and dark mode.  Alternatively, `npx axe-cli http://localhost:5173`
   can be used — note this downloads axe-cli on first run and requires the dev server to be
   running.  Fix all Critical and Serious violations either way.
2. **Manual — React keyboard:** Tab through every screen.  Verify:
   - Skip link appears on first Tab press.
   - Every button, link, and input is reachable in logical order.
   - Arrow keys navigate radiogroups.
   - Escape triggers Quick Exit.
   - Focus rings are visible on every focused element.
3. **Manual — React screen reader:** Use browser VoiceOver or NVDA.  Verify:
   - `role="alert"` regions announce on error.
   - `role="status"` announces copy-code result.
   - Progress rail announces "Step N of M: Step Name".
   - Incident tiles announce as radio buttons in a group.
4. **Manual — Flutter:** Use TalkBack on device.  Verify:
   - `SafeSignalTile` announces label, description, checked state, group.
   - `StepHeader` announces as heading.
   - `SafeSignalBanner` with `liveRegion: true` announces on error.
   - Quick Exit button announces its purpose.
5. **Document:** Create or update
   `apps/frontend/src/components/ui/ProgressRail.tsx` — add WCAG comment header.
   Optionally add a brief `docs/ACCESSIBILITY.md` noting what was tested and any remaining
   manual items.

**Verification**
- Zero Critical/Serious axe violations on all five public React screens.
- All keyboard-navigation checks pass.
- All Flutter TalkBack checks pass.

---

## Task Dependency Order

```
Task 1 (CSS tokens)
  └─ Task 6 (new React components)
       └─ Task 7 (theme toggle)
            └─ Task 8 (refactor screens)
                 └─ Task 9 (landing polish)
                      └─ Task 10 (a11y pass)

Task 2 (Flutter tokens + dark theme)
  └─ Task 3 (Flutter widgets)
       └─ Task 4 (refactor Flutter screens)
            └─ Task 5 (Flutter transitions)
                 └─ Task 10 (a11y pass)
```

Tasks 1–5 (Flutter track) and Tasks 6–9 (React track) can proceed in parallel.  Task 10
requires both tracks to be complete.
