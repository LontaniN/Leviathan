import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ui/theme.dart';

/// Preferenze dell'app: lingua dell'interfaccia e palette.
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
  });

  final File? file;
  LeviathanPalette palette;

  /// Codice della lingua scelta ('en', 'it'); null finché non la si sceglie
  /// al primo avvio.
  String? language;

  static Future<Settings> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'preferences.json'));
    String? paletteId;
    String? language;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      paletteId = json['palette'] as String?;
      language = json['language'] as String?;
    } on Object {
      // Primo avvio o file illeggibile: valori predefiniti.
    }
    return Settings(
      file: file,
      palette: LeviathanPalette.byId(paletteId),
      language: language,
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

  void _save() {
    final file = this.file;
    if (file == null) return;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      jsonEncode({'palette': palette.id, 'language': ?language}),
    );
  }
}
