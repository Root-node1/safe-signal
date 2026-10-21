import 'package:flutter/material.dart';

/// SafeSignal palette — light-mode constants, matching the web app's CSS tokens.
///
/// Dark-mode counterparts are embedded directly in the [ColorScheme] passed to
/// [buildSafeSignalDarkTheme]. Keeping them inline (rather than as a second
/// static class) avoids confusion about which set is "active".
///
/// Cross-platform hex reference: apps/frontend/src/index.css
class SafeSignalColors {
  // ── Light palette (unchanged from M.2) ──────────────────────────────────────
  static const oceanDark    = Color(0xFF0B1D26); // --color-ocean-dark  (light)
  static const ocean        = Color(0xFF102A36); // --color-ocean       (light)
  static const teal         = Color(0xFF12676C); // --color-teal        (light)
  static const tealSubtle   = Color(0xFFE8F4F5); // --color-teal-subtle (light)
  static const amber        = Color(0xFFE7A75B); // --color-amber       (light)
  static const amberDark    = Color(0xFF873800); // --color-amber-dark  (light)
  static const amberSubtle  = Color(0xFFFDF5EA); // --color-amber-subtle(light)
  static const coral        = Color(0xFFC24136); // --color-coral       (light)
  static const coralSubtle  = Color(0xFFFCEBE9); // --color-coral-subtle(light)
  static const canvas       = Color(0xFFF5F7F6); // --color-canvas      (light)
  static const textMuted    = Color(0xFF3D515B); // --color-text-muted  (light)
  static const border       = Color(0xFF6B7F8C); // --color-border      (light)
  static const borderSubtle = Color(0xFFCBD5DC); // --color-border-subtle(light)

  // ── Dark palette ─────────────────────────────────────────────────────────────
  // These match the [data-theme="dark"] block in index.css exactly.
  static const darkTeal         = Color(0xFF22A1A8); // --color-teal        (dark)
  static const darkTealSubtle   = Color(0xFF122B34); // --color-teal-subtle (dark)
  static const darkAmber        = Color(0xFFF0B774); // --color-amber       (dark)
  static const darkAmberDark    = Color(0xFFFCD8A5); // --color-amber-dark  (dark)
  static const darkAmberSubtle  = Color(0xFF3A2B14); // --color-amber-subtle(dark)
  static const darkCoral        = Color(0xFFE05D52); // --color-coral       (dark)
  static const darkCoralSubtle  = Color(0xFF3A1B19); // --color-coral-subtle(dark)
  static const darkCanvas       = Color(0xFF0B1D26); // --color-canvas      (dark)
  static const darkSurface      = Color(0xFF102A36); // --color-surface     (dark)
  static const darkSurfaceRaised= Color(0xFF183846); // --color-surface-raised (dark)
  static const darkTextPrimary  = Color(0xFFF5F7F6); // --color-text-primary(dark)
  static const darkTextMuted    = Color(0xFFCBD5DC); // --color-text-muted  (dark)
  static const darkBorder       = Color(0xFF4A6372); // --color-border      (dark)
  static const darkBorderSubtle = Color(0xFF243D4B); // --color-border-subtle(dark)
  static const darkFocus        = Color(0xFF2EC3CC); // --color-focus       (dark)
  static const darkOcean        = Color(0xFFF5F7F6); // --color-ocean       (dark) = darkTextPrimary
  static const darkOceanDark    = Color(0xFFFFFFFF); // --color-ocean-dark  (dark)
}

// ─── Shared TextTheme ─────────────────────────────────────────────────────────
// Used by both light and dark themes to keep the typographic scale consistent.
// Font sizes track the CSS --text-* scale; heights are the --leading-* values
// divided by the font size (Flutter uses a unitless multiplier).
//
// Colors are intentionally omitted here so that the ColorScheme drives them —
// Material 3 resolves onSurface, onPrimary, etc. automatically.  The legacy
// hard-coded colors on headlineMedium / titleMedium / bodyLarge are preserved
// for the light theme via colorScheme.onSurface defaults.
const TextTheme _kTextTheme = TextTheme(
  // displaySmall  — 32 px / 900 weight (large hero labels, not yet used)
  displaySmall: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.15,         // leading-3xl ÷ 32 ≈ 1.25; clamped to 1.15 for large display
    letterSpacing: -0.5,
  ),
  // headlineMedium — 26 px / 900 weight  (screen headings)
  headlineMedium: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.20,         // leading-2xl ÷ 28 ≈ 1.29; slightly tighter for headings
    letterSpacing: -0.3,
  ),
  // titleLarge — 20 px / 700 weight  (section headings)
  titleLarge: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.30,
  ),
  // titleMedium — 17 px / 700 weight  (tile labels, row labels)
  titleMedium: TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.30,
  ),
  // bodyLarge — 15 px / 400 weight  (intro paragraphs)
  bodyLarge: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,         // leading-base ÷ 15 ≈ 1.53
  ),
  // bodyMedium — 13 px / 400 weight  (hints, descriptions)
  bodyMedium: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.55,         // leading-sm ÷ 13 ≈ 1.54
  ),
  // labelLarge — 15 px / 700 weight  (step counter, button labels, row keys)
  labelLarge: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
  // labelSmall — 11 px / 600 weight  (badges, chips, status tags)
  labelSmall: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
);

// ─── Light Theme ──────────────────────────────────────────────────────────────
ThemeData buildSafeSignalTheme() {
  const scheme = ColorScheme.light(
    primary:        SafeSignalColors.teal,
    onPrimary:      Colors.white,
    secondary:      SafeSignalColors.amber,
    onSecondary:    SafeSignalColors.oceanDark,
    error:          SafeSignalColors.coral,
    onError:        Colors.white,
    surface:        Colors.white,
    onSurface:      SafeSignalColors.ocean,
    outline:        SafeSignalColors.border,
    outlineVariant: SafeSignalColors.borderSubtle,
  );

  return _buildTheme(
    scheme: scheme,
    scaffoldBg:    SafeSignalColors.canvas,
    appBarBg:      SafeSignalColors.ocean,
    appBarFg:      Colors.white,
    inputFill:     Colors.white,
    inputBorder:   SafeSignalColors.border,
    inputFocused:  SafeSignalColors.teal,
    inputLabel:    SafeSignalColors.textMuted,
    textTheme: _kTextTheme.copyWith(
      // Apply light-mode colors to the roles that need explicit overrides.
      headlineMedium: _kTextTheme.headlineMedium?.copyWith(
        color: SafeSignalColors.oceanDark,
      ),
      titleLarge: _kTextTheme.titleLarge?.copyWith(
        color: SafeSignalColors.ocean,
      ),
      titleMedium: _kTextTheme.titleMedium?.copyWith(
        color: SafeSignalColors.ocean,
      ),
      bodyLarge: _kTextTheme.bodyLarge?.copyWith(
        color: SafeSignalColors.textMuted,
      ),
      bodyMedium: _kTextTheme.bodyMedium?.copyWith(
        color: SafeSignalColors.textMuted,
      ),
      labelLarge: _kTextTheme.labelLarge?.copyWith(
        color: SafeSignalColors.teal,
      ),
    ),
  );
}

// ─── Dark Theme ───────────────────────────────────────────────────────────────
ThemeData buildSafeSignalDarkTheme() {
  const scheme = ColorScheme.dark(
    primary:        SafeSignalColors.darkTeal,
    onPrimary:      SafeSignalColors.darkCanvas,
    secondary:      SafeSignalColors.darkAmber,
    onSecondary:    SafeSignalColors.darkCanvas,
    error:          SafeSignalColors.darkCoral,
    onError:        SafeSignalColors.darkCanvas,
    surface:        SafeSignalColors.darkSurface,
    onSurface:      SafeSignalColors.darkTextPrimary,
    outline:        SafeSignalColors.darkBorder,
    outlineVariant: SafeSignalColors.darkBorderSubtle,
  );

  return _buildTheme(
    scheme: scheme,
    scaffoldBg:   SafeSignalColors.darkCanvas,
    appBarBg:     SafeSignalColors.darkSurface,
    appBarFg:     SafeSignalColors.darkTextPrimary,
    inputFill:    SafeSignalColors.darkSurfaceRaised,
    inputBorder:  SafeSignalColors.darkBorder,
    inputFocused: SafeSignalColors.darkTeal,
    inputLabel:   SafeSignalColors.darkTextMuted,
    textTheme: _kTextTheme.copyWith(
      headlineMedium: _kTextTheme.headlineMedium?.copyWith(
        color: SafeSignalColors.darkOceanDark,
      ),
      titleLarge: _kTextTheme.titleLarge?.copyWith(
        color: SafeSignalColors.darkOcean,
      ),
      titleMedium: _kTextTheme.titleMedium?.copyWith(
        color: SafeSignalColors.darkOcean,
      ),
      bodyLarge: _kTextTheme.bodyLarge?.copyWith(
        color: SafeSignalColors.darkTextMuted,
      ),
      bodyMedium: _kTextTheme.bodyMedium?.copyWith(
        color: SafeSignalColors.darkTextMuted,
      ),
      labelLarge: _kTextTheme.labelLarge?.copyWith(
        color: SafeSignalColors.darkTeal,
      ),
    ),
  );
}

// ─── Internal builder (shared between light and dark) ────────────────────────
ThemeData _buildTheme({
  required ColorScheme scheme,
  required Color scaffoldBg,
  required Color appBarBg,
  required Color appBarFg,
  required Color inputFill,
  required Color inputBorder,
  required Color inputFocused,
  required Color inputLabel,
  required TextTheme textTheme,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      foregroundColor: appBarFg,
      centerTitle: false,
    ),
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputFocused, width: 2.5),
      ),
      labelStyle: TextStyle(color: inputLabel),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}
