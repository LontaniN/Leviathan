import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide Tags;
import 'package:leviathan/data/note_repository.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/tags.dart';
import 'package:leviathan/model/task_order.dart';

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

    test('legge le liste YAML a trattini scritte da Obsidian', () {
      const content =
          '---\ntitle: Limiti\ntags:\n  - analisi\n  - "esame"\n'
          'sources:\n- Prof. Rossi\ncreated: 2026-10-17T14:05\n---\nTesto';
      final note = Note.fromMarkdown('o', content, DateTime(2000));
      expect(note.tags, ['analisi', 'esame']);
      expect(note.sources, ['Prof. Rossi']);
      expect(note.created, DateTime(2026, 10, 17, 14, 5));
      expect(note.body, 'Testo');
    });

    test('conserva le proprietà che non conosce', () {
      const content =
          '---\n# scritto in Obsidian\ntitle: "Idea"\naliases:\n  - pensiero\n'
          'tags:\n  - lavoro\nrating: 4\ncssclasses: []\n---\nCorpo';
      final note = Note.fromMarkdown('e', content, date);
      expect(note.tags, ['lavoro']);
      expect(
        note.extraFrontmatter,
        '# scritto in Obsidian\naliases:\n  - pensiero\nrating: 4\n'
        'cssclasses: []',
      );
      // Modificata e risalvata, le righe sconosciute restano tutte; un
      // secondo giro non cambia più nulla.
      final saved = note.copyWith(title: 'Idea nuova').toMarkdown();
      expect(saved, contains('aliases:\n  - pensiero\nrating: 4\n'));
      final again = Note.fromMarkdown('e', saved, date);
      expect(again.title, 'Idea nuova');
      expect(again.tags, ['lavoro']);
      expect(again.extraFrontmatter, note.extraFrontmatter);
      expect(again.toMarkdown(), saved);
      expect(again.body, 'Corpo');
    });

    test('le proprietà sconosciute restano anche spostando un task', () {
      const content =
          '---\ntitle: "T"\ntype: "task"\ndone: false\nproject: casa\n---\n';
      final task = Note.fromMarkdown('t', content, date);
      final placed = task.placed(TaskBand.now, 'm');
      expect(placed.extraFrontmatter, 'project: casa');
      expect(placed.copyWith(done: true).extraFrontmatter, 'project: casa');
    });

    test('legge la fonte singola delle prime versioni', () {
      const content = '---\ntitle: "Vecchia"\nsource: "Giulia"\n---\nx';
      expect(Note.fromMarkdown('v', content, date).sources, ['Giulia']);
    });

    test('un task fatto: andata e ritorno', () {
      final task = Note(
        id: 't',
        title: 'Comprare il libro',
        body: '',
        tags: ['studio'],
        sources: ['Anna'],
        created: date,
        updated: date,
        isTask: true,
        done: true,
        doneAt: date.add(const Duration(days: 2)),
      );
      final markdown = task.toMarkdown();
      expect(markdown, contains('type: "task"'));
      expect(markdown, contains('done: true'));
      final back = Note.fromMarkdown('t', markdown, DateTime(2000));
      expect(back.isTask, isTrue);
      expect(back.done, isTrue);
      expect(back.doneAt, task.doneAt);
      expect(back.tags, ['studio']);
      expect(back.sources, ['Anna']);
    });

    test('le note normali non scrivono i campi dei task', () {
      final note = Note(
        id: 'n',
        title: 'Idea',
        body: '',
        tags: [],
        sources: [],
        created: date,
        updated: date,
      );
      expect(note.toMarkdown(), isNot(contains('type:')));
      expect(note.toMarkdown(), isNot(contains('done')));
    });

    test('legge un task scritto a mano', () {
      const content = '---\ntitle: Esame\ntype: task\ndone: false\n---\n';
      final note = Note.fromMarkdown('e', content, date);
      expect(note.isTask, isTrue);
      expect(note.isOpenTask, isTrue);
    });

    test('togliere la spunta o il tipo task azzera lo stato', () {
      final task = Note(
        id: 't',
        title: 'x',
        body: '',
        tags: [],
        sources: [],
        created: date,
        updated: date,
        isTask: true,
        done: true,
        doneAt: date,
      );
      final reopened = task.copyWith(done: false);
      expect(reopened.done, isFalse);
      expect(reopened.doneAt, isNull);
      final plain = task.copyWith(isTask: false);
      expect(plain.isTask, isFalse);
      expect(plain.done, isFalse);
      expect(plain.doneAt, isNull);
    });

    test('una nota fissata: andata e ritorno', () {
      final note = Note(
        id: 'x',
        title: 'In cima',
        body: '',
        tags: [],
        sources: [],
        created: date,
        updated: date,
        pinned: true,
      );
      final text = note.toMarkdown();
      expect(text, contains('pinned: true'));
      expect(Note.fromMarkdown('x', text, date).pinned, isTrue);
      final unpinned = note.copyWith(pinned: false).toMarkdown();
      expect(unpinned, isNot(contains('pinned')));
      expect(Note.fromMarkdown('x', unpinned, date).pinned, isFalse);
    });

    test('una nota di conoscenza: andata e ritorno', () {
      final note = Note(
        id: 'x',
        title: 'Cosa so',
        body: '',
        tags: [],
        sources: [],
        created: date,
        updated: date,
        knowledge: true,
      );
      final text = note.toMarkdown();
      expect(text, contains('knowledge: true'));
      final read = Note.fromMarkdown('x', text, date);
      expect(read.knowledge, isTrue);
      expect(read.kind, NoteKind.knowledge);
      final plain = note.copyWith(knowledge: false).toMarkdown();
      expect(plain, isNot(contains('knowledge')));
    });

    test('un task non è mai conoscenza', () {
      final note = Note(
        id: 'x',
        title: 'Cosa so',
        body: '',
        tags: [],
        sources: [],
        created: date,
        updated: date,
        knowledge: true,
      );
      final task = note.copyWith(isTask: true);
      expect(task.knowledge, isFalse);
      expect(task.kind, NoteKind.task);
      expect(task.toMarkdown(), isNot(contains('knowledge')));
    });

    test('file senza intestazione: tutto è corpo', () {
      final note = Note.fromMarkdown('z', 'Solo testo\nsu due righe', date);
      expect(note.body, 'Solo testo\nsu due righe');
      expect(note.displayTitle('Senza titolo'), 'Solo testo');
      final empty = Note.fromMarkdown('v', '', date);
      expect(empty.displayTitle('Untitled'), 'Untitled');
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

    test('una nota eliminata torna fuori dal cestino', () {
      final note = repo.create(
        title: 'Ripensamento',
        body: 'a',
        tags: [],
        sources: [],
        now: DateTime(2026, 1, 1),
      );
      final trashed = repo.delete(note)!;
      expect(repo.loadAll(), isEmpty);
      expect(repo.restore(note, trashed), isTrue);
      expect(repo.loadAll().single.title, 'Ripensamento');
      expect(File(trashed).existsSync(), isFalse);
      // Una seconda volta non c'è più niente da riportare.
      expect(repo.restore(note, trashed), isFalse);
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
