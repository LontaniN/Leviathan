import 'dart:convert';
import 'dart:io';

import 'atomic_write.dart';

/// Le note aperte di recente in un workspace, dalla più recente.
///
/// File: `.leviathan/recent/<workspace>.json`, una lista di id.
class RecentStore {
  RecentStore(this.file);

  final File file;

  /// Quante note ricordare.
  static const limit = 20;

  List<String> read() {
    try {
      final json = jsonDecode(file.readAsStringSync());
      return [if (json is List) ...json.whereType<String>()];
    } on Object {
      return [];
    }
  }

  void write(List<String> ids) {
    writeFileAtomic(file, jsonEncode(ids.take(limit).toList()));
  }
}
