import 'package:flutter/material.dart';

/// SafeSignal palette, matching the web app's design tokens.
class SafeSignalColors {
  static const oceanDark = Color(0xFF0B1D26);
  static const ocean = Color(0xFF102A36);
  static const teal = Color(0xFF12676C);
  static const tealSubtle = Color(0xFFE8F4F5);
  static const amber = Color(0xFFE7A75B);
  static const amberDark = Color(0xFF873800);
  static const amberSubtle = Color(0xFFFDF5EA);
  static const coral = Color(0xFFC24136);
  static const coralSubtle = Color(0xFFFCEBE9);
  static const canvas = Color(0xFFF5F7F6);
  static const textMuted = Color(0xFF3D515B);
  static const border = Color(0xFF6B7F8C);
  static const borderSubtle = Color(0xFFCBD5DC);
}

ThemeData buildSafeSignalTheme() {
  const scheme = ColorScheme.light(
    primary: SafeSignalColors.teal,
    onPrimary: Colors.white,
    secondary: SafeSignalColors.amber,
    onSecondary: SafeSignalColors.oceanDark,
    error: SafeSignalColors.coral,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: SafeSignalColors.ocean,
    outline: SafeSignalColors.border,
    outlineVariant: SafeSignalColors.borderSubtle,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SafeSignalColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: SafeSignalColors.ocean,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w900,
        height: 1.15,
        color: SafeSignalColors.oceanDark,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: SafeSignalColors.ocean,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: SafeSignalColors.teal,
      ),
      bodyLarge: TextStyle(height: 1.5, color: SafeSignalColors.textMuted),
      bodyMedium: TextStyle(height: 1.5, color: SafeSignalColors.textMuted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SafeSignalColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SafeSignalColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SafeSignalColors.teal, width: 2.5),
      ),
      labelStyle: const TextStyle(color: SafeSignalColors.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
