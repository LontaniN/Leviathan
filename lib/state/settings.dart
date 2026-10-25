import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/atomic_write.dart';
import '../model/home_buttons.dart';
import '../ui/theme.dart';

/// Preferenze dell'app: lingua dell'interfaccia, palette, ordine di tag e
/// fonti, pulsanti in alto nella home, tour già visto.
///
/// Stanno nella memoria privata dell'app, non nella cartella delle note:
/// così si leggono prima di avere il permesso di archiviazione e l'app parte
/// già con i colori giusti.
class Settings extends ChangeNotifier {
  /// Senza [file] le preferenze vivono solo in memoria (usato nei test).
  Settings({
    this.file,
    this.palette = LeviathanPalette.inchiostro,
    this.language,
    this.tourSeen = false,
    this.alphabeticalGroups = false,
    this.homeButtons = HomeButton.defaults,
  });

  final File? file;
  LeviathanPalette palette;

  /// Codice della lingua scelta ('en', 'it'); null finché non la si sceglie
  /// al primo avvio.
  String? language;

  /// Il tour guidato della home è già stato fatto (o saltato): non riparte
  /// da solo.
  bool tourSeen;

  /// Tag e fonti da sfogliare (ricerca, Task e note, filtro del task
  /// manager) in ordine alfabetico invece che dai più usati: restano sempre
  /// nello stesso posto, e la mano impara dove trovarli.
  bool alphabeticalGroups;

  /// I pulsanti visibili in alto nella home, in ordine; le impostazioni
  /// vengono sempre dopo.
  List<HomeButton> homeButtons;

  static Future<Settings> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'preferences.json'));
    String? paletteId;
    String? language;
    var tourSeen = false;
    var alphabetical = false;
    var homeButtons = HomeButton.defaults;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      paletteId = json['palette'] as String?;
      language = json['language'] as String?;
      tourSeen = json['tourSeen'] as bool? ?? false;
      alphabetical = json['groupOrder'] == 'alphabetical';
      homeButtons = HomeButton.parse(json['homeButtons']);
    } on Object {
      // Primo avvio o file illeggibile: valori predefiniti.
    }
    return Settings(
      file: file,
      palette: LeviathanPalette.byId(paletteId),
      language: language,
      tourSeen: tourSeen,
      alphabeticalGroups: alphabetical,
      homeButtons: homeButtons,
    );
  }

  void setPalette(LeviathanPalette next) {
    if (next == palette) return;
    palette = next;
    notifyListeners();
    _save();
  }

  void setLanguage(String next) {
    if (next == language) return;
    language = next;
    notifyListeners();
    _save();
  }

  void setAlphabeticalGroups(bool next) {
    if (next == alphabeticalGroups) return;
    alphabeticalGroups = next;
    notifyListeners();
    _save();
  }

  void setHomeButtons(List<HomeButton> next) {
    if (listEquals(next, homeButtons)) return;
    homeButtons = List.unmodifiable(next);
    notifyListeners();
    _save();
  }

  void markTourSeen() {
    if (tourSeen) return;
    tourSeen = true;
    _save();
  }

  void _save() {
    final file = this.file;
    if (file == null) return;
    writeFileAtomic(
      file,
      jsonEncode({
        'palette': palette.id,
        'language': ?language,
        'tourSeen': tourSeen,
        if (alphabeticalGroups) 'groupOrder': 'alphabetical',
        if (!listEquals(homeButtons, HomeButton.defaults))
          'homeButtons': [for (final b in homeButtons) b.name],
      }),
    );
  }
}

/// Rende le [Settings] leggibili da tutte le schermate, che si ridisegnano
/// quando cambiano.
class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope({
    super.key,
    required Settings settings,
    required super.child,
  }) : super(notifier: settings);

  /// Vedi [Settings.alphabeticalGroups]; senza impostazioni (es. nei test di
  /// una sola schermata) vale l'ordine dai più usati.
  static bool alphabeticalGroups(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SettingsScope>()
          ?.notifier
          ?.alphabeticalGroups ??
      false;
}
