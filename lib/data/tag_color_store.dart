import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'atomic_write.dart';

/// I colori scelti a mano per i tag di un workspace; gli altri tag tengono
/// quello automatico.
///
/// File: `.leviathan/tag-colors/<workspace>.json`, `{tag: "#RRGGBB"}`.
class TagColorStore {
  TagColorStore(this.file);

  final File file;

  Map<String, Color> read() {
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in json.entries)
          if (value is String) key: ?_parse(value),
      };
    } on Object {
      return {};
    }
  }

  void write(Map<String, Color> colors) {
    writeFileAtomic(
      file,
      jsonEncode({
        for (final MapEntry(:key, :value) in colors.entries) key: _hex(value),
      }),
    );
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static Color? _parse(String s) {
    final hex = s.startsWith('#') ? s.substring(1) : s;
    if (hex.length != 6) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }
}
