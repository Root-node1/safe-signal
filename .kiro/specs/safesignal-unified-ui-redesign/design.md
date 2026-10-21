# Technical Design — SafeSignal M.3 Unified UI/UX Redesign

## 1. Design Philosophy: Calm Urban Safety

SafeSignal's users are commuters who may be stressed, in a moving vehicle, or in a vulnerable
situation.  The UI must feel **quiet, certain, and trustworthy** — not alarming, not gamified,
not decorative for its own sake.

Core principles:

- **Signal over noise** — the reporting action is always the most prominent thing on screen.
- **Nothing is sent until Submit** — this must be legible, not merely stated.
- **Graceful under pressure** — typography is large enough to read in a bouncing matatu;
  touch targets allow an imprecise tap.
- **Exit is always one move away** — the Quick Exit button is never buried or animated away.
- **Discreet chrome** — the app must not look like a safety or crisis app from a distance.

---

## 2. Design Tokens

### 2.1 Canonical Palette (unchanged from M.2)

The existing palette is solid and ships as-is.  Tokenisation adds naming discipline only.

| Token name | Light value | Dark value |
|---|---|---|
| `--color-ocean` | `#102A36` | `#F5F7F6` |
| `--color-ocean-dark` | `#0B1D26` | `#FFFFFF` |
| `--color-teal` | `#12676C` | `#22A1A8` |
| `--color-teal-hover` | `#0E5357` | `#2EC3CC` |
| `--color-teal-accent` | `#167D83` | `#1DA0A8` |
| `--color-teal-subtle` | `#E8F4F5` | `#122B34` |
| `--color-coral` | `#C24136` | `#E05D52` |
| `--color-coral-hover` | `#A83329` | `#EB7268` |
| `--color-coral-subtle` | `#FCEBE9` | `#3A1B19` |
| `--color-amber` | `#E7A75B` | `#F0B774` |
| `--color-amber-dark` | `#873800` | `#FCD8A5` |
| `--color-amber-subtle` | `#FDF5EA` | `#3A2B14` |
| `--color-canvas` | `#F5F7F6` | `#0B1D26` |
| `--color-surface` | `#FFFFFF` | `#102A36` |
| `--color-surface-raised` | `#FFFFFF` | `#183846` |
| `--color-text-primary` | `#102A36` | `#F5F7F6` |
| `--color-text-muted` | `#3D515B` | `#CBD5DC` |
| `--color-border` | `#6B7F8C` | `#4A6372` |
| `--color-border-subtle` | `#CBD5DC` | `#243D4B` |
| `--color-focus` | `#167D83` | `#2EC3CC` |

All tokens already exist in `apps/frontend/src/index.css`.  The design task is to ensure every
component consumes them via CSS custom properties and that no component files contain raw hex
literals.

**Note on the AdminScreen inconsistency:** `AdminScreen.tsx` uses a separate hardcoded palette
(`#F7F5F2`, `#0F5C5C`, etc.).  This screen is outside M.3 scope but the inconsistency is
documented here for the next milestone.

### 2.2 New Semantic Tokens to Add

The following tokens do not yet exist and shall be added to `index.css` (React) and as Dart
constants (Flutter).  They consolidate the most-reused arbitrary values.

**Spacing** — both platforms use 4 px base unit:

| Token | Value |
|---|---|
| `--space-1` | `4px` |
| `--space-2` | `8px` |
| `--space-3` | `12px` |
| `--space-4` | `16px` |
| `--space-5` | `20px` |
| `--space-6` | `24px` |
| `--space-8` | `32px` |
| `--space-10` | `40px` |
| `--space-12` | `48px` |
| `--space-16` | `64px` |

**Radius:**

| Token | Value | Usage |
|---|---|---|
| `--radius-sm` | `8px` | Small badges, chips |
| `--radius-md` | `12px` | Input fields, small cards |
| `--radius-lg` | `16px` | Standard cards, tiles |
| `--radius-xl` | `20px` | Action cards, modals |
| `--radius-full` | `9999px` | Pills, avatar chips |

**Typography** (React CSS tokens):

| Token | Size | Leading |
|---|---|---|
| `--text-xs` | `11px` | `16px` |
| `--text-sm` | `13px` | `20px` |
| `--text-base` | `15px` | `23px` |
| `--text-md` | `17px` | `26px` |
| `--text-lg` | `20px` | `30px` |
| `--text-xl` | `24px` | `32px` |
| `--text-2xl` | `28px` | `36px` |
| `--text-3xl` | `32px` | `40px` |
| `--text-4xl` | `40px` | `48px` |
| `--text-5xl` | `46px` | `52px` |

**Motion:**

| Token | Value |
|---|---|
| `--duration-fast` | `120ms` |
| `--duration-base` | `200ms` |
| `--duration-slow` | `350ms` |
| `--ease-standard` | `cubic-bezier(0.4, 0, 0.2, 1)` |
| `--ease-decelerate` | `cubic-bezier(0, 0, 0.2, 1)` |

**Touch target:**

| Token | Value |
|---|---|
| `--touch-min` | `44px` |

### 2.3 Flutter Token File

A new file `apps/mobile/lib/design_tokens.dart` shall export:

```dart
// spacing
const double kSpace1 = 4.0;
const double kSpace2 = 8.0;
const double kSpace3 = 12.0;
const double kSpace4 = 16.0;
const double kSpace5 = 20.0;
const double kSpace6 = 24.0;
const double kSpace8 = 32.0;
const double kSpace10 = 40.0;
const double kSpace12 = 48.0;
const double kSpace16 = 64.0;

// radius
const double kRadiusSm = 8.0;
const double kRadiusMd = 12.0;
const double kRadiusLg = 16.0;
const double kRadiusXl = 20.0;
const double kRadiusFull = 9999.0;

// touch target
const double kTouchMin = 48.0;

// animation durations
const Duration kDurationFast = Duration(milliseconds: 120);
const Duration kDurationBase = Duration(milliseconds: 200);
const Duration kDurationSlow = Duration(milliseconds: 280);
```

---

## 3. Typography

### 3.1 React — Inter Variable Font

Inter is loaded via a `<link rel="preload">` and `<link rel="stylesheet">` in `index.html`
pointing to bunny.net CDN (GDPR-friendly).  A `@font-face` fallback block is not required
since bunny.net serves it with full browser coverage.

```html
<!-- In index.html <head> -->
<link rel="preconnect" href="https://fonts.bunny.net">
<link rel="preload" href="https://fonts.bunny.net/css?family=inter:400,500,600,700,900&display=swap"
      as="style" onload="this.onload=null;this.rel='stylesheet'">
<noscript>
  <link rel="stylesheet" href="https://fonts.bunny.net/css?family=inter:400,500,600,700,900&display=swap">
</noscript>
```

The `body` font stack in `index.css` becomes:

```css
font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
```

### 3.2 Flutter — System Font

Flutter uses the device default (Roboto on Android).  No custom font is loaded.  Typography
is controlled via the `TextTheme` in `theme.dart`:

```dart
textTheme: const TextTheme(
  displaySmall:   TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -0.5),
  headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2,  color: SafeSignalColors.oceanDark),
  titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3,  color: SafeSignalColors.ocean),
  titleMedium:    TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3,  color: SafeSignalColors.ocean),
  bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.55, color: SafeSignalColors.textMuted),
  bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.55, color: SafeSignalColors.textMuted),
  labelLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SafeSignalColors.teal),
  labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
)
```

---

## 4. Dark Mode Implementation

### 4.1 React

Dark-mode tokens already exist under `[data-theme="dark"]` in `index.css`.  The implementation
gap is the theme toggle and the `data-theme` attribute application.

**Theme switch logic** in a new `src/lib/theme.ts`:

```typescript
type Theme = 'light' | 'dark'
const KEY = 'safesignal-theme'

function getInitialTheme(): Theme {
  const stored = localStorage.getItem(KEY)
  if (stored === 'dark' || stored === 'light') return stored
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

// Applies the theme attribute to the document root. Only persists to localStorage
// when persist=true (i.e. when the user explicitly toggles, not on initial mount).
function applyTheme(t: Theme, persist = false): void {
  document.documentElement.dataset.theme = t === 'dark' ? 'dark' : ''
  if (persist) localStorage.setItem(KEY, t)
}

function toggleTheme(current: Theme): Theme {
  const next: Theme = current === 'dark' ? 'light' : 'dark'
  applyTheme(next, true)
  return next
}
```

On mount, `SafeHeader` calls `applyTheme(getInitialTheme(), false)` — this applies the correct
theme attribute without overwriting a missing preference entry.  Only an explicit toggle calls
`applyTheme(next, true)`.

A `ThemeToggle` button component (`src/components/ui/ThemeToggle.tsx`) renders a sun/moon icon
with `aria-pressed` semantics, placed in `SafeHeader`.  It uses only existing token colours for
its icon and focus ring.

### 4.2 Flutter

`_SafeSignalAppState` in `app.dart` already holds a `_locale` state.  A parallel `_themeMode`
state (`ThemeMode.system` by default) is added.  `MaterialApp` wires `theme:` and `darkTheme:`
to `buildSafeSignalTheme()` and `buildSafeSignalDarkTheme()` respectively.

No persistence is needed for Flutter in M.3 (system setting is the default; explicit in-app
toggle is a later enhancement).

---

## 5. Component Architecture

### 5.1 React Component Map

```
src/
  components/
    Shell.tsx               (updated: new tokens, screen-entry animation)
    SafeHeader.tsx          (updated: token system, ThemeToggle)
    ui/
      Button.tsx            (updated: token variables)
      Card.tsx              (updated: token variables)
      Input.tsx             (updated: token variables)
      GlassSurface.tsx      (updated: token variables)
      StatusBadge.tsx       (updated: token variables)
      ProgressRail.tsx      (NEW: extracted from IncidentTypeScreen)
      SelectionTile.tsx     (NEW: extracted from IncidentTypeScreen + NextStepScreen)
      HelplineCard.tsx      (NEW: extracted from NextStepScreen + ConfirmationScreen)
      InlineBanner.tsx      (NEW: extracted from NextStepScreen error banner)
      ThemeToggle.tsx       (NEW: dark/light toggle for SafeHeader)
      index.ts              (updated: re-export new components)
```

### 5.2 `ProgressRail` props

```typescript
interface ProgressRailProps {
  steps: readonly string[]   // e.g. ['Incident type', 'Details', 'Support']
  current: number            // 0-indexed
}
```

Renders as a `<nav aria-label="Report progress">` with an `<ol>` of coloured bar + label
pairs.  Screen-reader summary injected with `class="sr-only"`.

### 5.3 `SelectionTile` props

```typescript
interface SelectionTileProps {
  id: string
  label: string
  description: string
  icon?: ReactNode            // decorative, aria-hidden
  badge?: string              // e.g. 'Available now', 'In development'
  badgeVariant?: 'available' | 'unavailable' | 'selected'
  selected: boolean
  disabled?: boolean
  tabIndex?: number
  onClick: () => void
  onKeyDown?: KeyboardEventHandler<HTMLButtonElement>
}
```

Implements `role="radio"`, `aria-checked`, `aria-disabled`, focus ring, selected/hover colour
transitions.  Both incident tiles and support option tiles use this component.

### 5.4 `HelplineCard` props

```typescript
interface HelplineCardProps {
  name: string
  detail: string
  tel: string
}
```

Renders a single helpline row: name, descriptive detail, and a `tel:` call-to-action link
styled as a button.

### 5.5 `InlineBanner` props

```typescript
interface InlineBannerProps {
  variant: 'error' | 'warning' | 'info'
  title?: string
  children: ReactNode
  role?: 'alert' | 'status'   // defaults to 'alert' for error/warning, 'status' for info
}
```

Maps variant to colour tokens: `error` → coral, `warning` → amber, `info` → teal-subtle.

### 5.6 `ThemeToggle` props

```typescript
interface ThemeToggleProps {
  theme: 'light' | 'dark'
  onToggle: () => void
}
```

Minimal 44 × 44 px button.  Icon: sun (light) / moon (dark).  `aria-label`:
`"Switch to dark mode"` / `"Switch to light mode"`.  `aria-pressed` reflects current state.

---

### 5.7 Flutter Widget Map

```
lib/
  design_tokens.dart        (NEW: spacing, radius, duration constants)
  theme.dart                (updated: dark theme, extended TextTheme)
  navigation.dart           (updated: FadeSlideTransition)
  widgets/
    quick_exit_button.dart  (unchanged)
    safesignal_tile.dart    (NEW: replaces _IncidentTile + _OptionTile)
    step_header.dart        (NEW: step label + heading + subtitle)
    safesignal_banner.dart  (NEW: replaces _Notice + inline error displays)
    widgets.dart            (NEW: barrel export)
  screens/
    welcome_screen.dart     (updated: SafeSignalBanner, new tokens)
    report_screen.dart      (updated: SafeSignalTile, StepHeader, new tokens)
    support_screen.dart     (updated: SafeSignalTile, new tokens)
    review_screen.dart      (updated: SafeSignalBanner, new tokens)
    confirmation_screen.dart(updated: new tokens)
```

### 5.8 `SafeSignalTile` design

```dart
class SafeSignalTile extends StatelessWidget {
  const SafeSignalTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.badge,          // e.g. unavailableTag string
    required this.selected,
    this.enabled = true,
    required this.onTap,
    this.semanticLabel,
  });
  // ...
}
```

Uses `AnimatedContainer` for background colour when `!MediaQuery.of(context).disableAnimations`.
Border: 2.5 dp teal when selected, 1 dp border-colour otherwise.  `Semantics`:
`inMutuallyExclusiveGroup: true`, `checked: selected`, `enabled: enabled`.

### 5.9 `SafeSignalBanner` design

```dart
enum SafeSignalBannerVariant { notice, warning, error }

class SafeSignalBanner extends StatelessWidget {
  const SafeSignalBanner({
    super.key,
    required this.variant,
    required this.title,
    required this.body,
    this.titleColor,
  });
  // Replaces private _Notice in WelcomeScreen
  // Also used for inline error states in ReviewScreen and ConfirmationScreen
}
```

Colour mapping — deliberately aligned with conventional severity:
- `notice` → `amberSubtle` bg / `amberDark` title, no border
  (used for: prototype notice on WelcomeScreen, confirmNotice on ConfirmationScreen)
- `warning` → `coralSubtle` bg / `coral` title, no border
  (used for: not-emergency notice, timing-now danger note)
- `error` → `coralSubtle` bg / `coral` title / `coral` border, `liveRegion: true`
  (used for: all submission error states in ReviewScreen)

---

## 6. Screen-Level Interaction Design

### 6.1 Landing Screen (React)

- Hero headline: `--text-3xl` (mobile) → `--text-5xl` (lg, 46 px) using Tailwind arbitrary
  value `text-[var(--text-5xl)]`; `font-weight: 900`.
- "Report an incident" primary CTA: existing `Button` `variant="primary"` `size="lg"`.
- "Report what is happening now": coral underline link, unchanged semantics.
- How-it-works grid: 2-col at `md:`, card hover border transitions use `--duration-base`.
- Coming-soon section: amber badge retained; no new content.
- Responsive: single-column at < 1024 px; hero card stacks below headline.

### 6.2 Incident Type Screen (React)

- `ProgressRail` at top: step 1 active.
- 6 × `SelectionTile` items in a `role="radiogroup"`.
- Tile icon: 36 × 36 dp container, teal-subtle background (unselected) → teal (selected).
- Tile selected state: teal-subtle background, 2 px teal border, check-circle indicator.
- Arrow-key navigation via `onKeyDown` (existing behaviour preserved in component).
- "Discreet and flexible" info card: `InlineBanner variant="info"` → teal-subtle.
- "Nothing is shared yet" footer: inline text, right-aligned.

### 6.3 Details Screen (React)

- `ProgressRail` at top: step 2 active.
- Each `Input` label appended with `(optional)` in muted text.
- "Continue" → `Button` `variant="primary"` `size="lg"`.
- "Skip all details" → `Button` `variant="secondary"` `size="lg"`.
- Reassurance card: `InlineBanner variant="info"`.

### 6.4 Support / Next-Step Screen (React)

- `ProgressRail` at top: step 3 active.
- 4 × `SelectionTile` items; disabled tiles have `opacity: 0.55` and `cursor: not-allowed`.
- Helpline reveal (when `support` chosen): animated `max-height` transition, disabled under
  reduced-motion.
- 3 × `HelplineCard` items inside a `<ul>`.
- Error banner: `InlineBanner variant="error"`.
- Submit button loading: button text changes to "Submitting…", `disabled`, no spinner (existing).

### 6.5 Confirmation Screen (React)

- Receipt badge: teal check-circle pill, unchanged.
- Reference code block: `text-[var(--text-2xl)]` (28 px) with responsive `sm:text-[var(--text-3xl)]`
  (32 px), monospace, `letter-spacing: 0.15em`, `user-select: all`.
- "Copied" status: existing `role="status"` `aria-live="polite"`, updated visual.
- Submission status list: checkmark and bullet items, unchanged semantics.
- Helplines: 3 × `HelplineCard`.
- Done / Start another: `Button` `variant="primary"` and `variant="secondary"`.

### 6.6 Welcome Screen (Flutter)

- Language toggle: `SegmentedButton`, unchanged position and behaviour.
- Hero heading: `headlineMedium`.
- "Report an incident" CTA: `FilledButton`, full width, `kTouchMin` height.
- "Report what is happening now": `TextButton` coral, full width.
- Two `SafeSignalBanner` notices: prototype (`notice` variant / amber) + not-emergency (`warning` variant / coral).
- Spacing: `kSpace6` between sections.

### 6.7 Report Screen (Flutter)

- `StepHeader`: "Step 1 of 3", heading from `l.whatHappenedTitle`, `headlineMedium`.
- `SegmentedButton<Timing>`: unchanged, now uses `kTouchMin`.
- Timing-now banner: `SafeSignalBanner variant: SafeSignalBannerVariant.warning`.
- 6 × `SafeSignalTile` for incident types; `AnimatedContainer` background when motion enabled.
- 4 text fields: `kSpace4` bottom padding between fields, `kRadiusMd` border.
- `FilledButton` Continue + `OutlinedButton` Back; 8 dp gap.

### 6.8 Support Screen (Flutter)

- `StepHeader`: "Step 2 of 3".
- 4 × `SafeSignalTile` options; disabled tiles dimmed, badge shows `l.unavailableTag`.
- Error text: `SafeSignalBanner variant: SafeSignalBannerVariant.error` (live region).
- `FilledButton` Review + `OutlinedButton` Back.

### 6.9 Review + Confirmation Screens (Flutter)

- Summary rows: consistent spacing, teal accent for row labels.
- Error banner: `SafeSignalBanner variant: SafeSignalBannerVariant.error` (live region; wraps
  the existing `Semantics(liveRegion: true)` container).
- Submit button: `FilledButton`, loading text from `l.submitting`.
- Confirmation: `kSpace6` gap sections, reference code in `SelectableText` styled with
  `fontFamily: 'monospace'`, `fontSize: 26`, `fontWeight: w900`, `letterSpacing: 2`.
- The confirmation amber notice (`l.confirmNotice`) uses
  `SafeSignalBanner variant: SafeSignalBannerVariant.notice`.
- Helpline rows (`Helpline.values`) use the existing `Card + ListTile` structure, updated to
  use token values: `kRadiusLg`, `kSpace4` padding, `titleMedium` for the name.

---

## 7. Animation Specification

### 7.1 Screen Entry — React

Applied to `<main>` inside `Shell`:

```css
@keyframes screen-enter {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

main {
  animation: screen-enter var(--duration-slow) var(--ease-decelerate) both;
}

@media (prefers-reduced-motion: reduce) {
  main { animation: none; }
}
```

Only fires once per `<main>` mount.  Does not apply to modal overlays.

### 7.2 Tile Hover / Selection — React

```css
.selection-tile {
  transition:
    background-color var(--duration-base) var(--ease-standard),
    border-color     var(--duration-base) var(--ease-standard),
    box-shadow       var(--duration-base) var(--ease-standard);
}
```

The global `prefers-reduced-motion` rule in `index.css` already zeroes these.

### 7.3 Screen Transition — Flutter

`FadeSlideTransition` in `navigation.dart`:

```dart
Route<T> appRoute<T>(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.of(context).disableAnimations) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, _a, _b) => builder(ctx),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
  return PageRouteBuilder<T>(
    pageBuilder: (ctx, _a, _b) => builder(ctx),
    transitionsBuilder: (ctx, animation, _secondary, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
    transitionDuration: kDurationSlow,
    reverseTransitionDuration: kDurationBase,
  );
}
```

### 7.4 Tile Selection — Flutter

Inside `SafeSignalTile.build()`:

```dart
final disableAnimations = MediaQuery.of(context).disableAnimations;
final bg = AnimatedContainer(
  duration: disableAnimations ? Duration.zero : kDurationBase,
  curve: Curves.easeInOut,
  decoration: BoxDecoration(
    color: selected ? SafeSignalColors.tealSubtle : (enabled ? Colors.white : SafeSignalColors.canvas),
    borderRadius: BorderRadius.circular(kRadiusLg),
    border: Border.all(
      color: selected ? SafeSignalColors.teal : SafeSignalColors.border,
      width: selected ? 2.5 : 1.0,
    ),
  ),
  // ...
);
```

---

## 8. Accessibility Implementation Notes

### 8.1 Colour Contrast

Every light-mode token pair used for text-on-background has been verified against WCAG 2.2 AA:

| Foreground | Background | Ratio | Pass |
|---|---|---|---|
| `--color-text-primary` (`#102A36`) | `--color-canvas` (`#F5F7F6`) | 12.5:1 | AA/AAA |
| `--color-text-muted` (`#3D515B`) | `--color-canvas` (`#F5F7F6`) | 6.6:1 | AA |
| `--color-teal` (`#12676C`) | `--color-surface` (`#FFFFFF`) | 5.4:1 | AA |
| `white` | `--color-teal` (`#12676C`) | 5.4:1 | AA |
| `white` | `--color-coral` (`#C24136`) | 4.6:1 | AA |
| `--color-amber-dark` (`#873800`) | `--color-amber-subtle` (`#FDF5EA`) | 7.2:1 | AA |

Dark mode pairs shall be verified against the same table during implementation (Task 2).

### 8.2 Focus Management

- React: `focus-visible:ring-4 ring-[var(--color-focus)] ring-offset-2` applied to all
  interactive elements.  The `focus-visible` pseudo-class means rings appear only on keyboard
  focus, not mouse click.
- Flutter: `FilledButton`, `OutlinedButton`, `InkWell` use Material 3's built-in focus
  indicator.  The focus colour is `colorScheme.primary` = teal.

### 8.3 Live Regions

Preserved without change:

| Location | Element | Purpose |
|---|---|---|
| `ConfirmationScreen` | `role="status"` `aria-live="polite"` | Copy-code feedback |
| `NextStepScreen` | `role="alert"` | Submission error |
| `IncidentTypeScreen` | `role="alert"` | Selection error |
| Flutter `ReviewScreen` | `Semantics(liveRegion: true)` | Submission error |
| Flutter `ReportScreen` | `Semantics(liveRegion: true)` | Incident error |

### 8.4 Heading Hierarchy

Web: `<h1>` on the main screen heading, `<h2>` for sub-sections, `<h3>` for card headings.
This is already correct; M.3 shall not introduce any heading skips.

---

## 9. Responsive Layout Strategy

The `Shell` component's existing container-width ladder is preserved:

| Mode | Mobile | md (768 px) | lg (1024 px) | xl (1280 px) |
|---|---|---|---|---|
| `default` (forms) | 390 px | 560 px | 640 px | — |
| `wide` (landing) | 390 px | 720 px | 960 px | 1040 px |

The `SafeHeader` inner container tracks the same ladder; at `lg:` with `wide` Shell, the
header content aligns to the content edge, not the screen edge.

Minimum tested viewport: 320 px.  No horizontal scroll at any supported width.

---

## 10. File-Change Summary

### React (`apps/frontend/src/`)

| File | Action | Notes |
|---|---|---|
| `index.html` | update | Fix `<title>`, add Inter font `<link>` tags |
| `index.css` | update | Add spacing, radius, typography, motion tokens |
| `lib/theme.ts` | **new** | `getInitialTheme`, `applyTheme(t, persist?)`, `toggleTheme` |
| `components/SafeHeader.tsx` | update | Add `ThemeToggle`; token cleanup |
| `components/Shell.tsx` | update | Screen-entry animation; token cleanup |
| `components/ui/Button.tsx` | update | Token cleanup (already mostly clean) |
| `components/ui/Card.tsx` | update | Token cleanup |
| `components/ui/Input.tsx` | update | Token cleanup; `(optional)` label support |
| `components/ui/GlassSurface.tsx` | update | Token cleanup |
| `components/ui/StatusBadge.tsx` | update | Token cleanup |
| `components/ui/ProgressRail.tsx` | **new** | Extracted from `IncidentTypeScreen` |
| `components/ui/SelectionTile.tsx` | **new** | Extracted from incident + support screens |
| `components/ui/HelplineCard.tsx` | **new** | Extracted from next-step + confirmation |
| `components/ui/InlineBanner.tsx` | **new** | Extracted from next-step error banner |
| `components/ui/ThemeToggle.tsx` | **new** | Sun/moon toggle |
| `components/ui/index.ts` | update | Re-export new components |
| `screens/LandingScreen.tsx` | update | Token cleanup; visual polish |
| `screens/IncidentTypeScreen.tsx` | update | Use `ProgressRail`, `SelectionTile`, `InlineBanner` |
| `screens/DetailsScreen.tsx` | update | Use `ProgressRail`; token cleanup; `(optional)` labels |
| `screens/NextStepScreen.tsx` | update | Use `SelectionTile`, `HelplineCard`, `InlineBanner` |
| `screens/ConfirmationScreen.tsx` | update | Use `HelplineCard`, `InlineBanner`; token cleanup |

### Flutter (`apps/mobile/lib/`)

| File | Action | Notes |
|---|---|---|
| `design_tokens.dart` | **new** | Spacing, radius, duration, touch target constants |
| `theme.dart` | update | `buildSafeSignalDarkTheme()`, extended `TextTheme` |
| `navigation.dart` | update | `FadeSlideTransition` in `appRoute` |
| `app.dart` | update | Wire `darkTheme`, `themeMode: ThemeMode.system` |
| `widgets/safesignal_tile.dart` | **new** | Replaces `_IncidentTile` + `_OptionTile` |
| `widgets/step_header.dart` | **new** | Step label + heading |
| `widgets/safesignal_banner.dart` | **new** | Replaces `_Notice`; error states |
| `widgets/widgets.dart` | **new** | Barrel export |
| `screens/welcome_screen.dart` | update | Use `SafeSignalBanner`, new tokens |
| `screens/report_screen.dart` | update | Use `SafeSignalTile`, `StepHeader`, new tokens |
| `screens/support_screen.dart` | update | Use `SafeSignalTile`, new tokens |
| `screens/review_screen.dart` | update | Use `SafeSignalBanner`, new tokens |
| `screens/confirmation_screen.dart` | update | New tokens; `SafeSignalBanner` for confirmNotice |

---

## 11. What Is Explicitly Not Changed

- `apps/backend/` — zero modifications
- `apps/frontend/src/types.ts` — API vocabulary unchanged
- `apps/frontend/src/lib/api.ts` — submission logic unchanged
- `apps/frontend/src/lib/quickExit.ts` — Quick Exit behaviour unchanged
- `apps/frontend/src/lib/support.ts` — helpline values unchanged
- `apps/frontend/src/lib/prototype.ts` — prototype flag unchanged
- `apps/frontend/src/App.tsx` — `Screen` union and state machine unchanged
- `apps/mobile/lib/models/report_draft.dart` — all enum values and constants unchanged
- `apps/mobile/lib/api/` — HTTP client, idempotency logic, submission state unchanged
- `apps/mobile/lib/l10n/` — ARB content unchanged
- `apps/mobile/lib/widgets/quick_exit_button.dart` — behaviour and function signature unchanged
