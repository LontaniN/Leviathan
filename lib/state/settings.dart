import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ui/theme.dart';

/// Preferenze dell'app (per ora solo la palette).
///
/// Stanno nella memoria privata dell'app, non nella cartella delle note:
/// così si leggono prima di avere il permesso di archiviazione e l'app parte
/// già con i colori giusti.
class Settings extends ChangeNotifier {
  /// Senza [file] le preferenze vivono solo in memoria (usato nei test).
  Settings({this.file, this.palette = LeviathanPalette.grafite});

  final File? file;
  LeviathanPalette palette;

  static Future<Settings> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'preferences.json'));
    String? paletteId;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      paletteId = json['palette'] as String?;
    } on Object {
      // Primo avvio o file illeggibile: valori predefiniti.
    }
    return Settings(file: file, palette: LeviathanPalette.byId(paletteId));
  }

  void setPalette(LeviathanPalette next) {
    if (next == palette) return;
    palette = next;
    notifyListeners();
    _save();
  }

  void _save() {
    final file = this.file;
    if (file == null) return;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode({'palette': palette.id}));
  }
}
