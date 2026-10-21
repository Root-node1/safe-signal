/// SafeSignal M.3 design tokens — Flutter edition.
///
/// These constants mirror the CSS custom properties defined in
/// `apps/frontend/src/index.css`. When a value changes, update both files.
///
/// Cross-platform correspondence:
///   CSS --space-N    ↔  kSpaceN   (same numeric value in px/dp)
///   CSS --radius-*   ↔  kRadius*  (same numeric value)
///   CSS --duration-* ↔  kDuration* (same milliseconds)
///   CSS --touch-min  ↔  kTouchMin  (44 px web → 48 dp Flutter; intentional
///                                   platform difference per Material guidance)
library;

// ─── Spacing Scale (4 dp base unit) ──────────────────────────────────────────
const double kSpace1  = 4.0;
const double kSpace2  = 8.0;
const double kSpace3  = 12.0;
const double kSpace4  = 16.0;
const double kSpace5  = 20.0;
const double kSpace6  = 24.0;
const double kSpace8  = 32.0;
const double kSpace10 = 40.0;
const double kSpace12 = 48.0;
const double kSpace16 = 64.0;

// ─── Border Radius Scale ──────────────────────────────────────────────────────
// sm: badges/chips  md: inputs/small-cards  lg: tiles/cards  xl: modals
const double kRadiusSm   = 8.0;
const double kRadiusMd   = 12.0;
const double kRadiusLg   = 16.0;
const double kRadiusXl   = 20.0;
const double kRadiusFull = 9999.0;

// ─── Touch Target ─────────────────────────────────────────────────────────────
// WCAG 2.5.5 / Material 3: minimum interactive target size.
// Flutter uses 48 dp (vs 44 px on web) per Android/Material guidance.
const double kTouchMin = 48.0;

// ─── Motion Tokens ────────────────────────────────────────────────────────────
// Only use these for background-color, border, opacity, and transform;
// never animate layout dimensions.
// kDurationSlow intentionally uses 280 ms (vs 350 ms CSS) — Flutter route
// transitions feel heavier at 350 ms; 280 ms matches the platform default cadence.
const Duration kDurationFast = Duration(milliseconds: 120);
const Duration kDurationBase = Duration(milliseconds: 200);
const Duration kDurationSlow = Duration(milliseconds: 280);
