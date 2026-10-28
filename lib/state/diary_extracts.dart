import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/diary_store.dart';
import '../model/diary_extract.dart';

/// I pezzi del diario diventati note, che il diario colora. Ogni modifica
/// si scrive subito: il file è piccolo.
class DiaryExtracts extends ChangeNotifier {
  DiaryExtracts(this._store) {
    try {
      _all = _store.readExtracts();
    } on FileSystemException catch (e) {
      error = e.message;
    }
  }

  final DiaryStore _store;
  List<DiaryExtract> _all = [];

  /// Perché i pezzi non si sono potuti leggere o scrivere; null se va tutto
  /// bene.
  String? error;

  List<DiaryExtract> get all => _all;

  /// I pezzi del giorno [day] (nome del file, "2026-10-25").
  List<DiaryExtract> ofDay(String day) => [
    for (final e in _all)
      if (e.day == day) e,
  ];

  int _seq = 0;

  /// Aggiunge un pezzo del giorno [day]; con [noteId] è già una nota.
  DiaryExtract add({
    required String day,
    required String text,
    required int start,
    List<String> tags = const [],
    List<String> sources = const [],
    String? noteId,
  }) {
    final extract = DiaryExtract(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      day: day,
      text: text,
      start: start,
      tags: tags,
      sources: sources,
      noteId: noteId,
    );
    _set([..._all, extract]);
    return extract;
  }

  void update(DiaryExtract extract) =>
      _set([for (final e in _all) e.id == extract.id ? extract : e]);

  /// Toglie il pezzo: il testo non è più colorato (la nota resta).
  void remove(DiaryExtract extract) => _set([
    for (final e in _all)
      if (e.id != extract.id) e,
  ]);

  /// Rimette un pezzo tolto con [remove].
  void restore(DiaryExtract extract) => _set([..._all, extract]);

  /// Toglie i pezzi la cui nota non c'è più (cercata con [byId]).
  void removeOrphans(Object? Function(String id) byId) {
    final kept = [
      for (final e in _all)
        if (e.noteId == null || byId(e.noteId!) != null) e,
    ];
    if (kept.length != _all.length) _set(kept);
  }

  void _set(List<DiaryExtract> next) {
    _all = next;
    try {
      _store.writeExtracts(next);
      error = null;
    } on FileSystemException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }
}
