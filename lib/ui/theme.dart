import 'package:flutter/material.dart';

/// Una combinazione di colori dell'app, scelta dalle impostazioni.
///
/// Nei widget si legge con `context.palette`: così cambiando palette tutto
/// si ridisegna da solo.
@immutable
class LeviathanPalette extends ThemeExtension<LeviathanPalette> {
  const LeviathanPalette({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.accent,
    required this.onAccent,
    required this.link,
    required this.text,
    required this.muted,
  });

  /// Chiave salvata nelle preferenze: non cambiarla.
  final String id;
  final String name;
  final Brightness brightness;

  /// Fondo delle schermate.
  final Color background;

  /// Pannelli, campi di testo, fogli in basso.
  final Color surface;

  /// Colore d'azione: pulsanti principali, selezione, nome del workspace.
  final Color accent;

  /// Testo e icone sopra [accent].
  final Color onAccent;

  /// Collegamenti del grafo e colore secondario.
  final Color link;
  final Color text;

  /// Testo secondario: suggerimenti, metadati, icone inattive.
  final Color muted;

  static const grafite = LeviathanPalette(
    id: 'grafite',
    name: 'Grafite',
    brightness: Brightness.dark,
    background: Color(0xFF2B2C31),
    surface: Color(0xFF35363C),
    accent: Color(0xFFF2E94E),
    onAccent: Color(0xFF000000),
    link: Color(0xFF3A9C9F),
    text: Color(0xFFE6E6EA),
    muted: Color(0xFF9A9BA3),
  );

  static const abisso = LeviathanPalette(
    id: 'abisso',
    name: 'Abisso',
    brightness: Brightness.dark,
    background: Color(0xFF0F1A24),
    surface: Color(0xFF182736),
    accent: Color(0xFF5CE1E6),
    onAccent: Color(0xFF0F1A24),
    link: Color(0xFF3D6FB6),
    text: Color(0xFFE2EAF2),
    muted: Color(0xFF8A9BB0),
  );

  static const brace = LeviathanPalette(
    id: 'brace',
    name: 'Brace',
    brightness: Brightness.dark,
    background: Color(0xFF231C1A),
    surface: Color(0xFF302623),
    accent: Color(0xFFFF8A4C),
    onAccent: Color(0xFF231C1A),
    link: Color(0xFFB0574B),
    text: Color(0xFFF0E6E0),
    muted: Color(0xFFA39189),
  );

  static const muschio = LeviathanPalette(
    id: 'muschio',
    name: 'Muschio',
    brightness: Brightness.dark,
    background: Color(0xFF1E2420),
    surface: Color(0xFF29312B),
    accent: Color(0xFFC8D96F),
    onAccent: Color(0xFF1E2420),
    link: Color(0xFF5E9E7A),
    text: Color(0xFFE4EBE5),
    muted: Color(0xFF93A096),
  );

  static const ametista = LeviathanPalette(
    id: 'ametista',
    name: 'Ametista',
    brightness: Brightness.dark,
    background: Color(0xFF221D2B),
    surface: Color(0xFF2E2739),
    accent: Color(0xFFF28CD9),
    onAccent: Color(0xFF221D2B),
    link: Color(0xFF8C7BE0),
    text: Color(0xFFEDE6F2),
    muted: Color(0xFFA29BB0),
  );

  /// Nero e bianco come l'icona dell'app; il nero pieno spegne i pixel OLED.
  static const inchiostro = LeviathanPalette(
    id: 'inchiostro',
    name: 'Inchiostro',
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF161616),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    link: Color(0xFF7A7A7A),
    text: Color(0xFFE8E8E8),
    muted: Color(0xFF8C8C8C),
  );

  static const carta = LeviathanPalette(
    id: 'carta',
    name: 'Carta',
    brightness: Brightness.light,
    background: Color(0xFFF1ECE2),
    surface: Color(0xFFFFFDF8),
    accent: Color(0xFFC2410C),
    onAccent: Color(0xFFFFFFFF),
    link: Color(0xFF3A9C9F),
    text: Color(0xFF2A2824),
    muted: Color(0xFF6F6B63),
  );

  static const all = [
    grafite,
    abisso,
    brace,
    muschio,
    ametista,
    inchiostro,
    carta,
  ];

  /// La palette con questo [id], o quella predefinita se non esiste più.
  static LeviathanPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => grafite);

  @override
  LeviathanPalette copyWith({
    Color? background,
    Color? surface,
    Color? accent,
    Color? onAccent,
    Color? link,
    Color? text,
    Color? muted,
  }) => LeviathanPalette(
    id: id,
    name: name,
    brightness: brightness,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    link: link ?? this.link,
    text: text ?? this.text,
    muted: muted ?? this.muted,
  );

  @override
  LeviathanPalette lerp(LeviathanPalette? other, double t) {
    if (other == null) return this;
    final target = t < 0.5 ? this : other;
    return LeviathanPalette(
      id: target.id,
      name: target.name,
      brightness: target.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      link: Color.lerp(link, other.link, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension LeviathanPaletteContext on BuildContext {
  LeviathanPalette get palette =>
      Theme.of(this).extension<LeviathanPalette>() ?? LeviathanPalette.grafite;
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

/// Misure di contenitori.
class LeviathanSizes {
  /// Larghezza dei dialoghi con un campo di testo.
  static const dialogWidth = 360.0;

  /// Spessore dei bordi sottili (es. il giorno di oggi nel calendario).
  static const outline = 1.5;

  /// Larghezza/altezza di una casella-giorno del calendario: più alta che
  /// larga, per farci stare qualche tag.
  static const calendarDayAspect = 0.6;

  /// Larghezza/altezza di una casella-mese del calendario.
  static const calendarMonthAspect = 0.85;
}

class LeviathanRadii {
  static const sm = 2.0;

  /// Caselle piccole, come i giorni del calendario.
  static const cell = 6.0;
  static const md = 12.0;
}

/// Dimensioni delle icone.
class LeviathanIconSize {
  /// Icone dentro i chip e nelle righe dense.
  static const sm = 16.0;

  /// Icone nelle righe di elenco e nelle barre (frecce, ricerca).
  static const md = 20.0;

  /// Icone da toccare spesso, come le caselle dei task.
  static const lg = 28.0;
}

/// Stili di testo ricorrenti, ricavati dalle dimensioni già in uso. Non hanno
/// colore: quello viene dalla palette (es. `copyWith(color: palette.muted)`).
class LeviathanText {
  /// Titolo di una riga di elenco (nome della nota, voce di menu).
  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  /// Testo secondario: anteprime, descrizioni.
  static const body = TextStyle(fontSize: 13, height: 1.25);

  /// Metadati: date, conteggi, fonti. Di solito in `palette.muted`.
  static const meta = TextStyle(fontSize: 12);

  /// Etichette minime: chip compatti, nodi del grafo.
  static const tiny = TextStyle(fontSize: 11);
}

ThemeData buildTheme(LeviathanPalette palette) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.link,
        brightness: palette.brightness,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.onAccent,
        secondary: palette.link,
        surface: palette.background,
        onSurface: palette.text,
        onSurfaceVariant: palette.muted,
        surfaceContainer: palette.surface,
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    extensions: [palette],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      border: const OutlineInputBorder(borderSide: BorderSide.none),
    ),
  );
}
