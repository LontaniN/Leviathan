import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/note_repository.dart';
import '../model/note.dart';

/// Una nota appena spostata nel cestino, con il file dove è finita.
typedef DeletedNote = ({Note note, String trashPath});

/// Le note del workspace aperto e i tag che usano.
class NotesController extends ChangeNotifier {
  NotesController(this._repo) {
    reload();
  }

  final NoteRepository _repo;

  List<Note> notes = const [];

  /// Ogni tag con il numero di note che lo usano.
  Map<String, int> tagCounts = const {};

  /// Ogni fonte con il numero di note che la citano.
  Map<String, int> sourceCounts = const {};

  /// Perché le note non si sono potute leggere; null se è andato tutto bene.
  String? error;

  void reload() {
    try {
      notes = _repo.loadAll();
      error = null;
    } on FileSystemException catch (e) {
      notes = const [];
      error = e.message;
    }
    _refreshCounts();
    notifyListeners();
  }

  Note create({
    required String title,
    required String body,
    required List<String> tags,
    required List<String> sources,
    bool isTask = false,
    bool knowledge = false,
    DateTime? created,
  }) {
    final note = _repo.create(
      title: title,
      body: body,
      tags: tags,
      sources: sources,
      isTask: isTask,
      knowledge: knowledge,
      now: created,
    );
    // Datata a un altro giorno non va per forza in cima.
    notes = [note, ...notes]..sort((a, b) => b.created.compareTo(a.created));
    _refreshCounts();
    notifyListeners();
    return note;
  }

  Note update(Note note) {
    final updated = note.copyWith(updated: DateTime.now());
    _repo.save(updated);
    // La data di creazione può essere cambiata: si riordina.
    notes = [for (final n in notes) n.id == updated.id ? updated : n]
      ..sort((a, b) => b.created.compareTo(a.created));
    _refreshCounts();
    notifyListeners();
    return updated;
  }

  /// Spunta o toglie la spunta a un task. Non conta come modifica della
  /// nota: la data di esecuzione sta in `done_at`.
  Note setDone(Note note, bool done) {
    final changed = note.copyWith(
      done: done,
      doneAt: done ? DateTime.now() : null,
    );
    _repo.save(changed);
    notes = [for (final n in notes) n.id == changed.id ? changed : n];
    notifyListeners();
    return changed;
  }

  /// Fissa la nota in cima alle recenti, o la stacca. Come la spunta, non
  /// conta come modifica.
  Note setPinned(Note note, bool pinned) {
    final changed = note.copyWith(pinned: pinned);
    _repo.save(changed);
    notes = [for (final n in notes) n.id == changed.id ? changed : n];
    notifyListeners();
    return changed;
  }

  /// Sposta la nota nel cestino. Il risultato serve a [restore] per
  /// annullare.
  DeletedNote? delete(Note note) {
    final trashPath = _repo.delete(note);
    notes = notes.where((n) => n.id != note.id).toList();
    _refreshCounts();
    notifyListeners();
    return trashPath == null ? null : (note: note, trashPath: trashPath);
  }

  /// Annulla un [delete]: la nota torna al suo posto nell'elenco.
  void restore(DeletedNote deleted) {
    if (!_repo.restore(deleted.note, deleted.trashPath)) return;
    notes = [...notes, deleted.note]
      ..sort((a, b) => b.created.compareTo(a.created));
    _refreshCounts();
    notifyListeners();
  }

  Note? byId(String id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  void _refreshCounts() {
    final tags = <String, int>{};
    final sources = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
      for (final source in note.sources) {
        sources[source] = (sources[source] ?? 0) + 1;
      }
    }
    tagCounts = tags;
    sourceCounts = sources;
  }
}
