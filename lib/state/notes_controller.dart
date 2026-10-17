import 'package:flutter/foundation.dart';

import '../data/note_repository.dart';
import '../model/note.dart';

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

  void reload() {
    notes = _repo.loadAll();
    _refreshCounts();
    notifyListeners();
  }

  Note create({
    required String title,
    required String body,
    required List<String> tags,
    required List<String> sources,
    bool isTask = false,
  }) {
    final note = _repo.create(
      title: title,
      body: body,
      tags: tags,
      sources: sources,
      isTask: isTask,
    );
    notes = [note, ...notes];
    _refreshCounts();
    notifyListeners();
    return note;
  }

  Note update(Note note) {
    final updated = note.copyWith(updated: DateTime.now());
    _repo.save(updated);
    notes = [for (final n in notes) n.id == updated.id ? updated : n];
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

  void delete(Note note) {
    _repo.delete(note);
    notes = notes.where((n) => n.id != note.id).toList();
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
