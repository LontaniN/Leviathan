import 'dart:io';

import '../data/diary_store.dart';
import '../model/note.dart';
import 'diary_extracts.dart';
import 'notes_controller.dart';

/// Tiene il diario allineato alle note: ogni nota che non è nata dal diario
/// ci entra come una riga col suo titolo, nel giorno della nota, collegata a
/// lei come se la si fosse creata da lì (colorata, si tocca e si apre).
///
/// Una nota ci entra una volta sola: chi la porta nel diario se lo segna
/// ([DiaryStore.writeSynced]), così togliendo il colore o cancellando la
/// riga non torna. Le note nate dal diario sono già collegate e si saltano.
/// La prima volta prende tutte le note che ci sono.
class DiarySync {
  DiarySync(this._store, this._extracts, this._notes);

  final DiaryStore _store;
  final DiaryExtracts _extracts;
  final NotesController _notes;

  /// Le note già portate nel diario, lette la prima volta che serve.
  Set<String>? _synced;

  /// Porta nel diario le note che non ci sono ancora. Restituisce quante ne
  /// ha aggiunte. Se le note non si sono potute leggere non fa nulla.
  int run() {
    if (_notes.error != null) return 0;
    try {
      return _run();
    } on FileSystemException {
      // Si riprova al prossimo cambiamento delle note.
      return 0;
    }
  }

  int _run() {
    final synced = _synced ??= _store.readSynced() ?? {};
    final linked = {for (final e in _extracts.all) ?e.noteId};
    final missing = [
      for (final note in _notes.notes)
        if (!synced.contains(note.id)) note,
    ]..sort((a, b) => a.created.compareTo(b.created));
    if (missing.isEmpty) return 0;
    var added = 0;
    try {
      for (final note in missing) {
        final line = _line(note);
        if (!linked.contains(note.id) && line.isNotEmpty) {
          _append(note, line);
          added++;
        }
        // Segnata solo dopo averla scritta: se il disco si rifiuta a metà,
        // la prossima volta si riprova da qui.
        synced.add(note.id);
      }
    } finally {
      _store.writeSynced(synced);
    }
    return added;
  }

  void _append(Note note, String line) {
    final day = note.created;
    final text = _store.read(day);
    // Una riga nuova in fondo alla giornata.
    final prefix = text.isEmpty || text.endsWith('\n') ? '' : '\n';
    _store.write(day, '$text$prefix$line');
    _extracts.add(
      day: DiaryStore.key(day),
      text: line,
      start: text.length + prefix.length,
      tags: note.tags,
      sources: note.sources,
      noteId: note.id,
    );
  }

  /// La riga di una nota: il titolo, o l'inizio del corpo se non ne ha; su
  /// una riga sola.
  static String _line(Note note) =>
      note.displayTitle('').replaceAll(RegExp(r'\s+'), ' ').trim();
}
