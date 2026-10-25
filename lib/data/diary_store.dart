import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../model/diary_extract.dart';
import 'atomic_write.dart';

/// Il diario di un workspace: un file Markdown per giorno.
///
/// File: `<workspace>/diary/AAAA-MM-GG.md`, solo il testo scritto. La
/// sottocartella sta dentro il workspace, così si sposta da sola quando lo
/// si rinomina o lo si elimina, e il `NoteRepository` (che legge solo i file
/// in cima alla cartella) non la scambia per note.
///
/// I pezzi scelti per diventare note (vedi [DiaryExtract]) stanno accanto,
/// in `<workspace>/diary/extracts.json`; le note già portate nel diario
/// (vedi `DiarySync`) in `<workspace>/diary/synced.json`.
class DiaryStore {
  DiaryStore(this.dir);

  static const dirName = 'diary';

  final Directory dir;

  /// Il nome del file di [day], senza estensione: "2026-10-25".
  static String key(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${day.year}-${two(day.month)}-${two(day.day)}';
  }

  /// Tutti i giorni scritti, per [key]. I file illeggibili si saltano.
  Map<String, String> readAll() {
    if (!dir.existsSync()) return {};
    final days = <String, String>{};
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File || p.extension(entity.path) != '.md') continue;
      try {
        days[p.basenameWithoutExtension(entity.path)] = entity
            .readAsStringSync();
      } on FileSystemException {
        // Un giorno illeggibile resta vuoto invece di bloccare il diario.
      }
    }
    return days;
  }

  /// Il testo di [day]; vuoto se non è scritto.
  String read(DateTime day) {
    final file = File(p.join(dir.path, '${key(day)}.md'));
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  /// Scrive il testo di [day]; un testo vuoto cancella il file.
  void write(DateTime day, String text) {
    final file = File(p.join(dir.path, '${key(day)}.md'));
    if (text.trim().isEmpty) {
      if (file.existsSync()) file.deleteSync();
      return;
    }
    writeFileAtomic(file, text);
  }

  File get _extractsFile => File(p.join(dir.path, 'extracts.json'));

  /// I pezzi scelti per diventare note; quelli rovinati si saltano.
  List<DiaryExtract> readExtracts() {
    try {
      final json = jsonDecode(_extractsFile.readAsStringSync());
      return [
        if (json is List)
          for (final item in json) ?DiaryExtract.fromJson(item),
      ];
    } on FileSystemException {
      return [];
    } on FormatException {
      return [];
    }
  }

  void writeExtracts(List<DiaryExtract> extracts) {
    writeFileAtomic(
      _extractsFile,
      jsonEncode([for (final e in extracts) e.toJson()]),
    );
  }

  File get _syncedFile => File(p.join(dir.path, 'synced.json'));

  /// Gli id delle note già portate nel diario; null se non è mai stato
  /// fatto (il primo allineamento le prende tutte).
  Set<String>? readSynced() {
    try {
      final json = jsonDecode(_syncedFile.readAsStringSync());
      return {if (json is List) ...json.whereType<String>()};
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  void writeSynced(Set<String> ids) {
    writeFileAtomic(_syncedFile, jsonEncode([...ids]..sort()));
  }
}
