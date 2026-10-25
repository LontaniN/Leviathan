import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/diary_store.dart';
import 'package:leviathan/data/note_repository.dart';

void main() {
  late Directory root;
  late DiaryStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('leviathan_diary');
    store = DiaryStore(Directory('${root.path}/ws/diary'));
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('un file per giorno, col nome della data', () {
    store.write(DateTime(2026, 3, 7, 22, 15), 'Cena da Anna.');
    store.write(DateTime(2026, 10, 25), 'Pioggia.');

    expect(
      File('${root.path}/ws/diary/2026-03-07.md').readAsStringSync(),
      'Cena da Anna.',
    );
    expect(store.readAll(), {
      '2026-03-07': 'Cena da Anna.',
      '2026-10-25': 'Pioggia.',
    });
  });

  test('svuotare un giorno ne cancella il file', () {
    final day = DateTime(2026, 10, 25);
    store.write(day, 'Pioggia.');
    store.write(day, '  \n');

    expect(File('${root.path}/ws/diary/2026-10-25.md').existsSync(), isFalse);
    expect(store.readAll(), isEmpty);
  });

  test('senza cartella il diario è vuoto', () {
    expect(store.readAll(), isEmpty);
  });

  test('le note non vedono i giorni del diario', () {
    store.write(DateTime(2026, 10, 25), 'Pioggia.');
    final notes = NoteRepository(
      Directory('${root.path}/ws'),
      trashDir: Directory('${root.path}/trash'),
    );
    expect(notes.loadAll(), isEmpty);
  });
}
