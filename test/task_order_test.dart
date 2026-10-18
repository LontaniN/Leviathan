import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/note_repository.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/task_order.dart';
import 'package:leviathan/state/notes_controller.dart';

Note _task(String id, {TaskBand? band, String? rank, int day = 1}) => Note(
  id: id,
  title: id,
  body: '',
  tags: const [],
  sources: const [],
  created: DateTime(2026, 10, day),
  updated: DateTime(2026, 10, day),
  isTask: true,
  band: band,
  rank: rank,
);

void main() {
  group('rankBetween', () {
    test('sta sempre in mezzo ai vicini', () {
      expect(rankBetween(null, null), isNotEmpty);
      final a = rankBetween(null, null);
      final before = rankBetween(null, a);
      final after = rankBetween(a, null);
      expect(before.compareTo(a), lessThan(0));
      expect(after.compareTo(a), greaterThan(0));
      final mid = rankBetween(before, a);
      expect(mid.compareTo(before), greaterThan(0));
      expect(mid.compareTo(a), lessThan(0));
    });

    test('regge molti inserimenti nello stesso punto', () {
      // Sempre in cima, sempre in fondo e sempre fra gli stessi due.
      var top = rankBetween(null, null);
      var bottom = top;
      var lo = 'a', hi = 'b';
      for (var i = 0; i < 200; i++) {
        final t = rankBetween(null, top);
        expect(t.compareTo(top), lessThan(0));
        top = t;
        final b = rankBetween(bottom, null);
        expect(b.compareTo(bottom), greaterThan(0));
        bottom = b;
        final m = rankBetween(lo, hi);
        expect(m.compareTo(lo), greaterThan(0));
        expect(m.compareTo(hi), lessThan(0));
        expect(m.endsWith('0'), isFalse);
        hi = m;
      }
    });

    test('inserimenti a caso restano in ordine', () {
      final random = Random(7);
      final ranks = <String>[];
      for (var i = 0; i < 300; i++) {
        final at = random.nextInt(ranks.length + 1);
        final r = rankBetween(
          at > 0 ? ranks[at - 1] : null,
          at < ranks.length ? ranks[at] : null,
        );
        ranks.insert(at, r);
      }
      expect([...ranks]..sort(), ranks);
      expect(ranks.toSet().length, ranks.length);
    });

    test('rifiuta vicini fuori ordine', () {
      expect(() => rankBetween('b', 'a'), throwsArgumentError);
      expect(() => rankBetween('a', 'a'), throwsArgumentError);
    });

    test('spreadRanks dà posizioni crescenti', () {
      final ranks = spreadRanks(20);
      expect([...ranks]..sort(), ranks);
      expect(ranks.toSet().length, 20);
    });
  });

  group('BinaryInsertion', () {
    test('trova il posto in log₂(n) domande', () {
      final list = [for (var i = 0; i < 30; i++) _task('t$i')];
      for (var target = 0; target <= list.length; target++) {
        final insertion = BinaryInsertion(list);
        var questions = 0;
        while (!insertion.isDone) {
          final pivot = list.indexOf(insertion.pivot!);
          insertion.answer(before: target <= pivot);
          questions++;
        }
        expect(insertion.index, target);
        expect(questions, lessThanOrEqualTo(5));
      }
    });

    test('fascia vuota: nessuna domanda', () {
      final insertion = BinaryInsertion(const []);
      expect(insertion.isDone, isTrue);
      expect(insertion.index, 0);
      expect(insertion.remaining, 0);
    });
  });

  group('TaskBoard', () {
    test('divide per fascia e ordina per posizione', () {
      final board = TaskBoard.of([
        _task('vecchio', day: 1),
        _task('nuovo', day: 5),
        _task('b', band: TaskBand.now, rank: 'm'),
        _task('a', band: TaskBand.now, rank: 'c'),
        _task('senza', band: TaskBand.now),
        _task('dopo', band: TaskBand.later, rank: 'i'),
        _task('fatto', band: TaskBand.now, rank: 'a').copyWith(done: true),
      ]);
      expect(board.unsorted.map((n) => n.id), ['nuovo', 'vecchio']);
      expect(board.bands[TaskBand.now]!.map((n) => n.id), ['a', 'b', 'senza']);
      expect(board.bands[TaskBand.next], isEmpty);
      expect(board.bands[TaskBand.later]!.map((n) => n.id), ['dopo']);
    });
  });

  group('frontmatter', () {
    test('fascia e posizione fanno andata e ritorno', () {
      final note = _task('x', band: TaskBand.next, rank: 'i5');
      final text = note.toMarkdown();
      expect(text, contains('priority: "next"'));
      expect(text, contains('rank: "i5"'));
      final back = Note.fromMarkdown('x', text, DateTime(2000));
      expect(back.band, TaskBand.next);
      expect(back.rank, 'i5');
    });

    test('una nota normale non ha fascia', () {
      const content = '---\ntitle: "N"\npriority: "now"\nrank: "i"\n---\n';
      final note = Note.fromMarkdown('n', content, DateTime(2000));
      expect(note.band, isNull);
      expect(note.rank, isNull);
      expect(note.toMarkdown(), isNot(contains('priority')));
    });

    test('togliendo il task si perdono fascia e posizione', () {
      final note = _task('x', band: TaskBand.now, rank: 'i');
      final plain = note.copyWith(isTask: false);
      expect(plain.band, isNull);
      expect(plain.rank, isNull);
      expect(note.placed(null, 'i').rank, isNull);
    });
  });

  group('NotesController.place', () {
    late Directory dir;
    late NotesController notes;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('leviathan_tasks');
      final repo = NoteRepository(
        Directory('${dir.path}/ws'),
        trashDir: Directory('${dir.path}/trash'),
      );
      for (final (i, id) in ['a', 'b', 'c'].indexed) {
        repo.save(_task(id, day: i + 1));
      }
      notes = NotesController(repo);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    List<String> now() => [
      for (final n in TaskBoard.of(notes.notes).bands[TaskBand.now]!) n.id,
    ];

    void put(String id, TaskBand? band, int index) {
      final list = band == null
          ? TaskBoard.of(notes.notes).unsorted
          : TaskBoard.of(notes.notes).bands[band]!;
      notes.place(notes.byId(id)!, band, list, index);
    }

    test('sposta nelle fasce e fra le fasce, e lo scrive su disco', () {
      put('a', TaskBand.now, 0);
      put('b', TaskBand.now, 1);
      put('c', TaskBand.now, 0);
      expect(now(), ['c', 'a', 'b']);
      // Spostato in fondo: il primo diventa l'ultimo.
      put('c', TaskBand.now, 2);
      expect(now(), ['a', 'b', 'c']);
      put('a', TaskBand.later, 0);
      expect(now(), ['b', 'c']);
      expect(notes.byId('a')!.band, TaskBand.later);
      put('b', null, 0);
      expect(notes.byId('b')!.band, isNull);
      expect(
        File('${dir.path}/ws/c.md').readAsStringSync(),
        contains('priority: "now"'),
      );
      expect(
        File('${dir.path}/ws/b.md').readAsStringSync(),
        isNot(contains('priority')),
      );
    });

    test('rinumera la fascia se le posizioni non lasciano posto', () {
      // File scritti a mano, con la stessa posizione o senza.
      for (final id in ['a', 'b']) {
        notes.place(notes.byId(id)!, TaskBand.now, const [], 0);
      }
      final repo = NoteRepository(
        Directory('${dir.path}/ws'),
        trashDir: Directory('${dir.path}/trash'),
      );
      repo.save(notes.byId('a')!.placed(TaskBand.now, 'i'));
      repo.save(notes.byId('b')!.placed(TaskBand.now, 'i'));
      notes.reload();
      put('c', TaskBand.now, 1);
      expect(now(), ['a', 'c', 'b']);
      final ranks = [for (final id in now()) notes.byId(id)!.rank!];
      expect([...ranks]..sort(), ranks);
      expect(ranks.toSet().length, 3);
    });
  });
}
