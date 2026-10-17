import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset;

/// Ricorda dove stavano i nodi del grafo, così riaprendolo le costellazioni
/// sono già al loro posto invece di rimescolarsi.
///
/// File: `.leviathan/graph/<workspace>.json`, `{idNota: [x, y]}`.
class GraphLayoutStore {
  GraphLayoutStore(this.file);

  final File file;

  Map<String, Offset> read() {
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in json.entries)
          if (value case [num x, num y])
            key: Offset(x.toDouble(), y.toDouble()),
      };
    } on Object {
      return {};
    }
  }

  void write(Map<String, Offset> positions) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      jsonEncode({
        for (final MapEntry(:key, :value) in positions.entries)
          key: [
            double.parse(value.dx.toStringAsFixed(1)),
            double.parse(value.dy.toStringAsFixed(1)),
          ],
      }),
    );
  }
}
