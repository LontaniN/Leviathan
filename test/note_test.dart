import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide Tags;
import 'package:leviathan/data/note_repository.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/tags.dart';

void main() {
  group('formato Markdown', () {
    final date = DateTime(2026, 10, 17, 14, 5, 12);

    test('andata e ritorno senza perdite', () {
      final note = Note(
        id: 'x',
        title: 'Titolo: con "virgolette"',
        body: 'Riga uno\n\n---\nRiga dopo un separatore',
        tags: ['fotografia', 'luce/naturale'],
        sources: ['Mario Rossi', 'Libro: "Luce"'],
        created: date,
        updated: date.add(const Duration(hours: 1)),
      );
      final back = Note.fromMarkdown('x', note.toMarkdown(), DateTime(2000));
      expect(back.title, note.title);
      expect(back.body, note.body);
      expect(back.tags, note.tags);
      expect(back.sources, note.sources);
      expect(back.created, note.created);
      expect(back.updated, note.updated);
    });

    test('legge file scritti a mano', () {
      const content =
          '---\ntitle: Idea veloce\ntags: [lavoro, idee]\n---\n'
          'Testo';
      final note = Note.fromMarkdown('y', content, date);
      expect(note.title, 'Idea veloce');
      expect(note.tags, ['lavoro', 'idee']);
      expect(note.body, 'Testo');
      expect(note.created, date);
    });

    test('legge la fonte singola delle prime versioni', () {
      const content = '---\ntitle: "Vecchia"\nsource: "Giulia"\n---\nx';
      expect(Note.fromMarkdown('v', content, date).sources, ['Giulia']);
    });

    test('file senza intestazione: tutto è corpo', () {
      final note = Note.fromMarkdown('z', 'Solo testo\nsu due righe', date);
      expect(note.body, 'Solo testo\nsu due righe');
      expect(note.displayTitle, 'Solo testo');
    });
  });

  group('tag', () {
    test('forma canonica', () {
      expect(Tags.normalize('  Machine Learning '), 'machine-learning');
      expect(Tags.normalize('#Città'), 'citta');
      expect(Tags.normalize('luce/Naturale'), 'luce/naturale');
      expect(Tags.normalize('a  --  b'), 'a-b');
      expect(Tags.normalize('!!!'), '');
    });

    final counts = {
      'fotografia': 5,
      'fotoritocco': 2,
      'filosofia': 3,
      'machine-learning': 4,
      'cucina': 1,
    };

    test('suggerisce per inizio, poi per frequenza', () {
      expect(Tags.suggest('foto', counts), ['fotografia', 'fotoritocco']);
    });

    test('trova parole dentro i tag composti', () {
      expect(Tags.suggest('learn', counts), ['machine-learning']);
    });

    test('tollera errori di battitura', () {
      expect(Tags.suggest('fotogarfia', counts), contains('fotografia'));
      expect(Tags.suggest('filosfia', counts), contains('filosofia'));
    });

    test('esclude i tag già presenti', () {
      expect(Tags.suggest('foto', counts, exclude: ['fotografia']), [
        'fotoritocco',
      ]);
    });

    test('a campo vuoto propone i più usati', () {
      expect(Tags.suggest('', counts, limit: 2), [
        'fotografia',
        'machine-learning',
      ]);
    });

    test('fonti: si tiene la grafia e si riusa quella esistente', () {
      expect(Sources.normalize('  Mario   Rossi '), 'Mario Rossi');
      expect(Sources.canonical('mario rossi', ['Mario Rossi']), 'Mario Rossi');
      expect(Sources.canonical('Niccolò', ['Niccolo']), 'Niccolo');
      expect(Sources.canonical('Anna', ['Mario Rossi']), 'Anna');
      expect(Sources.suggest('ros', {'Mario Rossi': 2, 'Anna': 1}), [
        'Mario Rossi',
      ]);
    });

    test('il colore di un tag è stabile', () {
      expect(Tags.colorOf('fotografia'), Tags.colorOf('fotografia'));
    });
  });

  group('archivio note', () {
    late Directory root;
    late NoteRepository repo;

    setUp(() {
      root = Directory.systemTemp.createTempSync('leviathan_notes');
      repo = NoteRepository(
        Directory('${root.path}/ws'),
        trashDir: Directory('${root.path}/trash'),
      );
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('crea, rilegge in ordine e sposta nel cestino', () {
      final first = repo.create(
        title: 'Prima',
        body: 'a',
        tags: ['x'],
        sources: [],
        now: DateTime(2026, 1, 1),
      );
      final second = repo.create(
        title: 'Seconda nota!',
        body: 'b',
        tags: [],
        sources: [],
        now: DateTime(2026, 1, 2),
      );
      expect(second.id, '20260102-000000-seconda-nota');

      expect(repo.loadAll().map((n) => n.title), ['Seconda nota!', 'Prima']);

      repo.delete(first);
      expect(repo.loadAll().map((n) => n.title), ['Seconda nota!']);
      expect(File('${root.path}/trash/${first.id}.md').existsSync(), isTrue);
    });

    test('due note nello stesso secondo non si sovrascrivono', () {
      final now = DateTime(2026, 1, 1);
      final a = repo.create(
        title: 'Uguale',
        body: '1',
        tags: [],
        sources: [],
        now: now,
      );
      final b = repo.create(
        title: 'Uguale',
        body: '2',
        tags: [],
        sources: [],
        now: now,
      );
      expect(a.id, isNot(b.id));
      expect(repo.loadAll(), hasLength(2));
    });
  });
}
