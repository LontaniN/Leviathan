import 'package:flutter/material.dart';

/// Tema scuro ispirato al grafo: fondo grafite, accento giallo, linee teal.
class LeviathanColors {
  static const background = Color(0xFF2B2C31);
  static const surface = Color(0xFF35363C);
  static const accent = Color(0xFFF2E94E);
  static const link = Color(0xFF3A9C9F);
  static const muted = Color(0xFF9A9BA3);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LeviathanColors.link,
    brightness: Brightness.dark,
  ).copyWith(
    primary: LeviathanColors.accent,
    onPrimary: Colors.black,
    secondary: LeviathanColors.link,
    surface: LeviathanColors.background,
    surfaceContainer: LeviathanColors.surface,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: LeviathanColors.background,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: LeviathanColors.surface,
      border: OutlineInputBorder(borderSide: BorderSide.none),
    ),
  );
}
