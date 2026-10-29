import 'package:flutter/material.dart';

/// Палитра повторяет тёмную тему веб-клиента (styles.css).
abstract final class Palette {
  static const bg = Color(0xFF0F1115);
  static const panel = Color(0xFF171A21);
  static const panel2 = Color(0xFF1E222B);
  static const line = Color(0xFF2A2F3A);
  static const text = Color(0xFFE7E9EE);
  static const muted = Color(0xFF8B93A5);
  static const accent = Color(0xFF5B8CFF);
  static const ok = Color(0xFF3ECF8E);
  static const bad = Color(0xFFFF6B6B);
}

ThemeData buildTheme() {
  const radius = BorderRadius.all(Radius.circular(12));
  final scheme = const ColorScheme.dark(
    surface: Palette.bg,
    onSurface: Palette.text,
    primary: Palette.accent,
    onPrimary: Colors.white,
    secondary: Palette.accent,
    error: Palette.bad,
    surfaceContainerLowest: Palette.bg,
    surfaceContainerLow: Palette.panel,
    surfaceContainer: Palette.panel,
    surfaceContainerHigh: Palette.panel2,
    surfaceContainerHighest: Palette.panel2,
    outline: Palette.line,
    outlineVariant: Palette.line,
    onSurfaceVariant: Palette.muted,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.bg,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.text),
    ),
    cardTheme: const CardThemeData(
      color: Palette.panel,
      margin: EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Palette.line),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Palette.panel2,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Palette.accent),
      ),
      labelStyle: TextStyle(color: Palette.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Palette.line),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Palette.text,
      unselectedLabelColor: Palette.muted,
      indicatorColor: Palette.accent,
      dividerColor: Palette.line,
    ),
    dividerColor: Palette.line,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
