import 'package:flutter/material.dart';

/// Una combinazione di colori dell'app, scelta dalle impostazioni.
///
/// Nei widget si legge con `context.palette`: così cambiando palette tutto
/// si ridisegna da solo.
@immutable
class LeviathanPalette extends ThemeExtension<LeviathanPalette> {
  const LeviathanPalette({
    required this.id,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.accent,
    required this.onAccent,
    required this.link,
    required this.text,
    required this.muted,
  });

  /// Chiave salvata nelle preferenze: non cambiarla. Il nome mostrato è
  /// nelle traduzioni (vedi `paletteName`).
  final String id;
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
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF161616),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    link: Color(0xFF7A7A7A),
    text: Color(0xFFE8E8E8),
    muted: Color(0xFF8C8C8C),
  );

  /// Inchiostro seppia: nero caldo appena sopra lo zero (niente scie OLED
  /// scorrendo) e accento color carta vecchia.
  static const seppia = LeviathanPalette(
    id: 'seppia',
    brightness: Brightness.dark,
    background: Color(0xFF0B0907),
    surface: Color(0xFF1A1612),
    accent: Color(0xFFF0E4D0),
    onAccent: Color(0xFF0B0907),
    link: Color(0xFF8A7A66),
    text: Color(0xFFE9E1D6),
    muted: Color(0xFF948779),
  );

  /// Inchiostro su lavagna: nero freddo, appena bluastro, e accento grigio
  /// ghiaccio.
  static const lavagna = LeviathanPalette(
    id: 'lavagna',
    brightness: Brightness.dark,
    background: Color(0xFF06080B),
    surface: Color(0xFF12161C),
    accent: Color(0xFFDCE5F0),
    onAccent: Color(0xFF06080B),
    link: Color(0xFF66768A),
    text: Color(0xFFE1E6EC),
    muted: Color(0xFF8590A0),
  );

  static const carta = LeviathanPalette(
    id: 'carta',
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
    inchiostro,
    seppia,
    lavagna,
    grafite,
    abisso,
    brace,
    muschio,
    ametista,
    carta,
  ];

  /// Un gradino sopra [surface]: chip, campi dentro i pannelli, menu.
  Color get surfaceHigh =>
      Color.alphaBlend(text.withValues(alpha: 0.06), surface);

  /// Bordi sottili e separatori: si vedono appena sul fondo.
  Color get outline => text.withValues(alpha: 0.10);

  /// [accent] molto diluito sul fondo: selezioni, segmenti attivi.
  Color get accentSoft =>
      Color.alphaBlend(accent.withValues(alpha: 0.16), background);

  /// La palette con questo [id], o quella predefinita se non esiste più.
  static LeviathanPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => inchiostro);

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
      Theme.of(this).extension<LeviathanPalette>() ??
      LeviathanPalette.inchiostro;
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
  static const xxxl = 48.0;
}

/// Misure di contenitori.
class LeviathanSizes {
  /// Larghezza dei dialoghi con un campo di testo.
  static const dialogWidth = 360.0;

  /// Larghezza massima dei moduli a schermo intero (primo avvio).
  static const formWidth = 420.0;

  /// Altezza massima dei fogli dal basso, in frazione dello schermo.
  static const sheetHeight = 0.7;

  /// Spessore dei bordi sottili (es. il giorno di oggi nel calendario).
  static const outline = 1.5;

  /// Altezza della fascia in alto dell'icona del calendario con il giorno.
  static const calendarIconBand = 5.0;

  /// Bordo di un elemento scelto (es. la palette attiva).
  static const selectedOutline = 2.0;

  /// Larghezza/altezza di una casella-giorno del calendario: più alta che
  /// larga, per farci stare qualche tag.
  static const calendarDayAspect = 0.6;

  /// Larghezza/altezza di una casella-mese del calendario.
  static const calendarMonthAspect = 0.85;

  /// Larghezza/altezza di un riquadro tag o fonte nella schermata Task e
  /// note.
  static const groupTileAspect = 0.95;

  /// Larghezza/altezza di una scheda palette nelle impostazioni.
  static const paletteTileAspect = 0.82;

  /// Larghezza della barretta colorata del primo tag accanto a una nota.
  static const tagBar = 3.0;

  /// Altezza della barretta nella lista compatta e in quella espansa.
  static const tagBarCompact = 28.0;
  static const tagBarExpanded = 40.0;

  /// Altezza della barra di ricerca della home e dei pulsanti principali.
  static const searchBar = 44.0;
  static const button = 48.0;

  /// La colonna delle recenti: frazione della larghezza e limiti.
  static const listFraction = 0.32;
  static const listMin = 112.0;
  static const listMax = 220.0;

  /// Raggio dei pallini dei tag nei chip normali e compatti.
  static const tagDot = 5.0;
  static const tagDotDense = 4.0;

  /// Diametro di un colore nel foglio per scegliere il colore di un tag.
  static const tagSwatch = 40.0;

  /// Altezza minima delle due schede da confrontare nel task manager.
  static const compareCard = 120.0;

  /// Larghezza massima del titolo di un nodo del grafo.
  static const graphLabelWidth = 140.0;

  /// Larghezza massima della scheda del tour guidato.
  static const tourCardWidth = 400.0;

  /// Lo spazio minimo, sopra o sotto l'elemento illuminato, perché la scheda
  /// del tour ci stia accanto invece di coprirlo.
  static const tourCardRoom = 220.0;

  /// Ombra della scheda del tour sopra il velo.
  static const tourCardElevation = 8.0;
}

/// Durate delle animazioni.
class LeviathanDurations {
  /// Il riquadro illuminato del tour che passa da un elemento all'altro.
  static const tourMove = Duration(milliseconds: 320);

  /// Apertura e chiusura della lista delle note.
  static const panel = Duration(milliseconds: 220);

  /// Bagliore della voce appena salvata: si accende, resta e sfuma.
  static const saveFlash = Duration(milliseconds: 1400);

  /// Attesa dopo l'ultima battuta prima di salvare la bozza.
  static const draftSave = Duration(milliseconds: 600);

  /// Cambi di stato piccoli (segmenti, chip, colori).
  static const quick = Duration(milliseconds: 160);

  /// Tempo massimo per cui resta l'avviso con "Annulla" dopo un'eliminazione.
  static const undoSnackBar = Duration(seconds: 8);
}

/// Opacità dei colori usati come velo sopra il fondo.
class LeviathanOpacity {
  /// Picco del bagliore della voce appena salvata, nel colore della nota.
  static const saveFlash = 0.35;

  /// Il velo scuro del tour guidato attorno all'elemento illuminato.
  static const tourScrim = 0.72;

  /// Barretta delle note senza tag.
  static const untagged = 0.4;

  /// Velo del colore del tag sui riquadri della schermata Task e note.
  static const groupTint = 0.08;

  /// Testo selezionato, nel colore d'accento.
  static const selection = 0.35;

  /// Nel grafo: collegamenti attenuati, normali ed evidenziati.
  static const edgeDim = 0.07;
  static const edge = 0.45;
  static const edgeHighlight = 0.85;

  /// Nel grafo: nodi fuori dal filtro e task fatti.
  static const nodeDim = 0.12;
  static const nodeDone = 0.35;

  /// Titoli dei nodi del grafo.
  static const graphLabel = 0.87;
}

class LeviathanRadii {
  static const sm = 2.0;

  /// Caselle piccole, come i giorni del calendario.
  static const cell = 6.0;
  static const md = 12.0;

  /// Pannelli grandi: l'editor, i fogli in basso, i dialoghi.
  static const lg = 20.0;
}

/// Dimensioni delle icone.
class LeviathanIconSize {
  /// Icone minime, come la puntina di una nota fissata.
  static const xs = 12.0;

  /// Icone dentro i chip e nelle righe dense.
  static const sm = 16.0;

  /// Icone nelle righe di elenco e nelle barre (frecce, ricerca).
  static const md = 20.0;

  /// Icone da toccare spesso, come le caselle dei task.
  static const lg = 28.0;

  /// Icone illustrative delle schermate vuote o di benvenuto.
  static const xl = 48.0;
}

/// Stili di testo ricorrenti, ricavati dalle dimensioni già in uso. Non hanno
/// colore: quello viene dalla palette (es. `copyWith(color: palette.muted)`).
class LeviathanText {
  /// Il nome dell'app nel primo avvio.
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.1,
  );

  /// Il titolo di una nota aperta in lettura.
  static const heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Il nome del workspace in cima alla home.
  static const workspace = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  /// Il titolo nel riquadro dell'editor.
  static const editorTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Titolo di una riga di elenco (nome della nota, voce di menu).
  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  /// Testo di lettura delle note: più arioso del resto.
  static const reading = TextStyle(fontSize: 16, height: 1.6);

  /// Testo secondario: anteprime, descrizioni.
  static const body = TextStyle(fontSize: 13, height: 1.25);

  /// Metadati: date, conteggi, fonti. Di solito in `palette.muted`.
  static const meta = TextStyle(fontSize: 12);

  /// Intestazioni di sezione in maiuscolo spaziato.
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );

  /// Etichette minime: chip compatti, nodi del grafo.
  static const tiny = TextStyle(fontSize: 11);

  /// Il numero del giorno dentro l'icona del calendario.
  static const calendarDigit = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1,
  );
}

ThemeData buildTheme(LeviathanPalette palette) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.link,
        brightness: palette.brightness,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.onAccent,
        primaryContainer: palette.accentSoft,
        onPrimaryContainer: palette.accent,
        secondary: palette.link,
        secondaryContainer: palette.accentSoft,
        onSecondaryContainer: palette.accent,
        surface: palette.background,
        onSurface: palette.text,
        onSurfaceVariant: palette.muted,
        surfaceContainerLowest: palette.background,
        surfaceContainerLow: palette.surface,
        surfaceContainer: palette.surface,
        surfaceContainerHigh: palette.surfaceHigh,
        surfaceContainerHighest: palette.surfaceHigh,
        outline: palette.muted,
        outlineVariant: palette.outline,
        surfaceTint: Colors.transparent,
      );
  final base = ThemeData(colorScheme: scheme);
  final text = base.textTheme.apply(
    bodyColor: palette.text,
    displayColor: palette.text,
  );
  const pillShape = StadiumBorder();
  final noBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(LeviathanRadii.md),
    borderSide: BorderSide.none,
  );
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    extensions: [palette],
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.merge(LeviathanText.heading),
      titleLarge: text.titleLarge?.merge(LeviathanText.editorTitle),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleTextStyle: LeviathanText.title.copyWith(color: palette.text),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: palette.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        minimumSize: const Size(0, LeviathanSizes.button),
        shape: pillShape,
        textStyle: LeviathanText.title,
        padding: const EdgeInsets.symmetric(horizontal: LeviathanSpacing.xl),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        shape: pillShape,
        textStyle: LeviathanText.title,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: palette.outline)),
        textStyle: WidgetStatePropertyAll(
          LeviathanText.meta.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accentSoft
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.muted,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.muted,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.accentSoft,
      side: BorderSide(color: palette.outline),
      shape: pillShape,
      labelStyle: LeviathanText.body.copyWith(color: palette.text),
      iconTheme: IconThemeData(color: palette.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.muted),
      prefixIconColor: palette.muted,
      border: noBorder,
      enabledBorder: noBorder,
      focusedBorder: noBorder,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(
        alpha: LeviathanOpacity.selection,
      ),
      selectionHandleColor: palette.accent,
    ),
    dividerTheme: DividerThemeData(color: palette.outline, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: palette.muted,
      textColor: palette.text,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: palette.muted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LeviathanRadii.lg),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeviathanRadii.lg),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      // Si toglie trascinandola di lato.
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: palette.surfaceHigh,
      contentTextStyle: LeviathanText.body.copyWith(color: palette.text),
      actionTextColor: palette.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: palette.surfaceHigh,
        borderRadius: BorderRadius.circular(LeviathanRadii.cell),
      ),
      textStyle: LeviathanText.meta.copyWith(color: palette.text),
    ),
  );
}
