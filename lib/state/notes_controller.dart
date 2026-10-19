import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../data/note_repository.dart';
import '../data/tag_color_store.dart';
import '../model/note.dart';
import '../model/tags.dart';
import '../model/task_order.dart';

/// Una nota appena spostata nel cestino, con il file dove è finita.
typedef DeletedNote = ({Note note, String trashPath});

/// Le note del workspace aperto e i tag che usano.
class NotesController extends ChangeNotifier {
  NotesController(this._repo, {this._tagColors}) {
    Tags.custom = _tagColors?.read() ?? const {};
    reload();
  }

  final NoteRepository _repo;
  final TagColorStore? _tagColors;

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

  /// Rilegge le note solo se qualche file è cambiato da fuori (es. tornando
  /// nell'app dopo averle modificate con Obsidian o sincronizzate).
  void reloadIfChanged() {
    try {
      if (!_repo.hasExternalChanges()) return;
    } on FileSystemException {
      // Cartella illeggibile: ci pensa reload a mostrare l'errore.
    }
    reload();
  }

  Note create({
    required String title,
    required String body,
    required List<String> tags,
    required List<String> sources,
    bool isTask = false,
    bool knowledge = false,
    String nextStep = '',
    DateTime? created,
  }) {
    final note = _repo.create(
      title: title,
      body: body,
      tags: tags,
      sources: sources,
      isTask: isTask,
      knowledge: knowledge,
      nextStep: nextStep,
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

  /// Mette un task del task manager nella fascia [band] fra i task di
  /// [list] agli indici `index - 1` e `index` ([list] è la fascia nel suo
  /// ordine; può contenere il task stesso). Con [band] null il task torna
  /// fra quelli da ordinare. Come la spunta, non conta come modifica.
  ///
  /// Se i vicini non lasciano posto (posizioni mancanti o uguali, es. file
  /// scritti a mano) l'intera fascia viene rinumerata.
  void place(Note task, TaskBand? band, List<Note> list, int index) {
    if (band == null) {
      _saveAll([task.placed(null, null)]);
      return;
    }
    final rank = rankAt(list, index, moving: task);
    if (rank != null) {
      _saveAll([task.placed(band, rank)]);
      return;
    }
    final others = [
      for (final n in list)
        if (n.id != task.id) n,
    ];
    final ordered = [...others]..insert(index.clamp(0, others.length), task);
    final ranks = spreadRanks(ordered.length);
    _saveAll([
      for (var i = 0; i < ordered.length; i++)
        if (ordered[i].band != band || ordered[i].rank != ranks[i])
          ordered[i].placed(band, ranks[i]),
    ]);
  }

  void _saveAll(List<Note> changed) {
    if (changed.isEmpty) return;
    final byId = {for (final n in changed) n.id: n};
    for (final note in changed) {
      _repo.save(note);
    }
    notes = [for (final n in notes) byId[n.id] ?? n];
    notifyListeners();
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

  /// Dà a [tag] il colore [color]; con null torna quello automatico.
  /// Vale per tutto il workspace: barrette, chip e grafo.
  void setTagColor(String tag, Color? color) {
    final colors = {...Tags.custom};
    if (color == null || color == Tags.autoColorOf(tag)) {
      colors.remove(tag);
    } else {
      colors[tag] = color;
    }
    Tags.custom = colors;
    _tagColors?.write(colors);
    notifyListeners();
  }

  /// Rinomina il tag [from] in [to] in tutte le note che lo usano; se [to]
  /// esiste già i due tag si uniscono. Il colore scelto a mano passa al
  /// nuovo nome, se quello non ne ha già uno.
  void renameTag(String from, String to) {
    if (from == to || to.isEmpty) return;
    final colors = {...Tags.custom};
    final color = colors.remove(from);
    if (color != null) {
      colors.putIfAbsent(to, () => color);
      Tags.custom = colors;
      _tagColors?.write(colors);
    }
    _renameIn(from, to, (n) => n.tags, (n, tags) => n.copyWith(tags: tags));
  }

  /// Rinomina la fonte [from] in [to] in tutte le note che la citano; se
  /// [to] esiste già le due fonti si uniscono.
  void renameSource(String from, String to) {
    if (from == to || to.isEmpty) return;
    _renameIn(
      from,
      to,
      (n) => n.sources,
      (n, sources) => n.copyWith(sources: sources),
    );
  }

  /// Come la spunta, rinominare non conta come modifica delle note.
  void _renameIn(
    String from,
    String to,
    List<String> Function(Note) values,
    Note Function(Note, List<String>) withValues,
  ) {
    final changed = [
      for (final note in notes)
        if (values(note).contains(from))
          withValues(note, [
            ...{for (final v in values(note)) v == from ? to : v},
          ]),
    ];
    for (final note in changed) {
      _repo.save(note);
    }
    final byId = {for (final n in changed) n.id: n};
    notes = [for (final n in notes) byId[n.id] ?? n];
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
