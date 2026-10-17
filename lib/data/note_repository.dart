import 'dart:io';

import 'package:path/path.dart' as p;

import '../model/note.dart';

/// Legge e scrive le note di un workspace: un file `.md` per nota.
///
/// Le operazioni sono sincrone: i file sono piccoli e così una nota non resta
/// mai scritta a metà. Se un giorno i workspace diventeranno enormi, la lettura
/// iniziale potrà passare a un indice.
class NoteRepository {
  NoteRepository(this.dir, {required this.trashDir});

  final Directory dir;

  /// Le note eliminate finiscono qui invece di essere cancellate.
  final Directory trashDir;

  /// Tutte le note, dalla più recente.
  List<Note> loadAll() {
    if (!dir.existsSync()) return [];
    final notes = <Note>[];
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File || p.extension(entity.path) != '.md') continue;
      try {
        notes.add(
          Note.fromMarkdown(
            p.basenameWithoutExtension(entity.path),
            entity.readAsStringSync(),
            entity.lastModifiedSync(),
          ),
        );
      } on FileSystemException {
        // File illeggibile: lo si salta invece di bloccare tutto il workspace.
      }
    }
    notes.sort((a, b) => b.created.compareTo(a.created));
    return notes;
  }

  /// Crea una nuova nota con un id basato su data e titolo.
  Note create({
    required String title,
    required String body,
    required List<String> tags,
    required List<String> sources,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final note = Note(
      id: _newId(time, title),
      title: title,
      body: body,
      tags: tags,
      sources: sources,
      created: time,
      updated: time,
    );
    save(note);
    return note;
  }

  void save(Note note) {
    dir.createSync(recursive: true);
    _file(note.id).writeAsStringSync(note.toMarkdown());
  }

  /// Sposta la nota nel cestino.
  void delete(Note note) {
    final file = _file(note.id);
    if (!file.existsSync()) return;
    trashDir.createSync(recursive: true);
    var target = p.join(trashDir.path, '${note.id}.md');
    if (File(target).existsSync()) {
      target = p.join(
        trashDir.path,
        '${note.id}-${DateTime.now().millisecondsSinceEpoch}.md',
      );
    }
    file.renameSync(target);
  }

  File _file(String id) => File(p.join(dir.path, '$id.md'));

  String _newId(DateTime time, String title) {
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${time.year}${two(time.month)}${two(time.day)}-'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
    final slug = _slug(title);
    final base = slug.isEmpty ? stamp : '$stamp-$slug';
    var id = base;
    for (var i = 2; _file(id).existsSync(); i++) {
      id = '$base-$i';
    }
    return id;
  }

  static String _slug(String title) {
    const accents = {
      'à': 'a',
      'è': 'e',
      'é': 'e',
      'ì': 'i',
      'ò': 'o',
      'ù': 'u',
    };
    var slug = title.toLowerCase().split('').map((c) => accents[c] ?? c).join();
    slug = slug
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.length > 40) {
      slug = slug.substring(0, 40).replaceAll(RegExp(r'-+$'), '');
    }
    return slug;
  }
}
