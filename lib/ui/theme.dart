import 'package:flutter/material.dart';

/// Tema scuro ispirato al grafo: fondo grafite, accento giallo, linee teal.
class LeviathanColors {
  static const background = Color(0xFF2B2C31);
  static const surface = Color(0xFF35363C);
  static const accent = Color(0xFFF2E94E);
  static const link = Color(0xFF3A9C9F);
  static const muted = Color(0xFF9A9BA3);
}

/// Scala delle spaziature (multipli di 4): usarla per padding e SizedBox
/// invece di numeri sparsi.
class LeviathanSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class LeviathanRadii {
  static const sm = 2.0;
  static const md = 12.0;
}

/// Stili di testo ricorrenti, ricavati dalle dimensioni già in uso.
class LeviathanText {
  /// Titolo di una riga di elenco (nome della nota, voce di menu).
  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  /// Testo secondario: anteprime, descrizioni.
  static const body = TextStyle(fontSize: 13, height: 1.25);

  /// Metadati attenuati: date, conteggi, fonti.
  static const meta = TextStyle(fontSize: 12, color: LeviathanColors.muted);

  /// Etichette minime: chip compatti, nodi del grafo.
  static const tiny = TextStyle(fontSize: 11);
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
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
