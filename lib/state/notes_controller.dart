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

  void reload() {
    notes = _repo.loadAll();
    _refreshTags();
    notifyListeners();
  }

  Note create({
    required String title,
    required String body,
    required List<String> tags,
    required String source,
  }) {
    final note =
        _repo.create(title: title, body: body, tags: tags, source: source);
    notes = [note, ...notes];
    _refreshTags();
    notifyListeners();
    return note;
  }

  Note update(Note note) {
    final updated = note.copyWith(updated: DateTime.now());
    _repo.save(updated);
    notes = [for (final n in notes) n.id == updated.id ? updated : n];
    _refreshTags();
    notifyListeners();
    return updated;
  }

  void delete(Note note) {
    _repo.delete(note);
    notes = notes.where((n) => n.id != note.id).toList();
    _refreshTags();
    notifyListeners();
  }

  Note? byId(String id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  void _refreshTags() {
    final counts = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    tagCounts = counts;
  }
}
