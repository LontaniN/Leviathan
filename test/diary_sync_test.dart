import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/diary_store.dart';
import 'package:leviathan/data/note_repository.dart';
import 'package:leviathan/model/diary_extract.dart';
import 'package:leviathan/state/diary_extracts.dart';
import 'package:leviathan/state/diary_sync.dart';
import 'package:leviathan/state/notes_controller.dart';

void main() {
  late Directory root;
  late DiaryStore store;
  late NotesController notes;
  late DiaryExtracts extracts;

  setUp(() {
    root = Directory.systemTemp.createTempSync('leviathan_sync');
    store = DiaryStore(Directory('${root.path}/ws/diary'));
    notes = NotesController(
      NoteRepository(
        Directory('${root.path}/ws'),
        trashDir: Directory('${root.path}/trash'),
      ),
    );
    extracts = DiaryExtracts(store);
  });

  tearDown(() => root.deleteSync(recursive: true));

  DiarySync sync() => DiarySync(store, extracts, notes);

  test('le note che ci sono entrano nel diario, nel loro giorno', () {
    store.write(DateTime(2026, 10, 20), 'Giornata di pioggia.');
    notes.create(
      title: 'Ombrello rotto',
      body: '',
      tags: ['casa'],
      sources: [],
      created: DateTime(2026, 10, 20, 18),
    );
    notes.create(
      title: 'Prima idea',
      body: '',
      tags: [],
      sources: [],
      created: DateTime(2026, 10, 20, 9),
    );
    notes.create(
      title: '',
      body: 'Solo corpo\nsu due righe',
      tags: [],
      sources: [],
      created: DateTime(2026, 10, 21),
    );

    expect(sync().run(), 3);

    // Nell'ordine in cui sono nate, sotto quello che c'era.
    final day = store.read(DateTime(2026, 10, 20));
    expect(day, 'Giornata di pioggia.\nPrima idea\nOmbrello rotto');
    expect(store.read(DateTime(2026, 10, 21)), 'Solo corpo');
    // Collegate come se fossero nate dal diario.
    final ranges = extractRanges(day, extracts.ofDay('2026-10-20'));
    expect(
      [for (final r in ranges) day.substring(r.start, r.end)],
      ['Prima idea', 'Ombrello rotto'],
    );
    expect(ranges.last.extract.tags, ['casa']);
    expect(ranges.every((r) => r.extract.noteId != null), isTrue);
  });

  test('una nota entra una volta sola, anche togliendo il colore', () {
    notes.create(title: 'Idea', body: '', tags: [], sources: []);
    final first = sync();
    expect(first.run(), 1);
    expect(first.run(), 0);

    extracts.remove(extracts.all.single);
    // Anche un allineamento nuovo (riaprendo l'app) la ricorda.
    expect(sync().run(), 0);
    final today = store.readAll().values.single;
    expect('\n'.allMatches(today), isEmpty);
  });

  test('le note nate dal diario non entrano una seconda volta', () {
    store.write(DateTime(2026, 10, 25), 'Al mare.');
    final note = notes.create(
      title: 'Mare',
      body: 'Al mare.',
      tags: [],
      sources: [],
      created: DateTime(2026, 10, 25, 10),
    );
    extracts.add(
      day: '2026-10-25',
      text: 'Al mare.',
      start: 0,
      noteId: note.id,
    );

    expect(sync().run(), 0);
    expect(store.read(DateTime(2026, 10, 25)), 'Al mare.');
  });
}
