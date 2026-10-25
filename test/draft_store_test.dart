import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/draft_store.dart';

void main() {
  late Directory root;
  late DraftStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('leviathan_draft');
    store = DraftStore(File('${root.path}/drafts/ws.json'));
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('senza file non c\'è bozza', () {
    expect(store.read(), isNull);
  });

  test('scrive e rilegge la bozza', () {
    store.write((
      title: 'Idea',
      body: 'Da finire',
      tags: ['studio'],
      sources: ['Anna'],
      isTask: true,
      knowledge: false,
      date: null,
    ));
    final draft = store.read()!;
    expect(draft.title, 'Idea');
    expect(draft.body, 'Da finire');
    expect(draft.tags, ['studio']);
    expect(draft.sources, ['Anna']);
    expect(draft.isTask, isTrue);
  });

  test('una bozza vuota cancella il file', () {
    store.write((
      title: 'x',
      body: '',
      tags: const [],
      sources: const [],
      isTask: false,
      knowledge: false,
      date: null,
    ));
    expect(store.file.existsSync(), isTrue);
    store.write((
      title: '  ',
      body: '',
      tags: const [],
      sources: const [],
      isTask: true,
      knowledge: false,
      date: null,
    ));
    expect(store.file.existsSync(), isFalse);
    expect(store.read(), isNull);
  });

  test('tiene il giorno scelto col calendario e la conoscenza', () {
    store.write((
      title: 'Dal quaderno',
      body: '',
      tags: const [],
      sources: const [],
      isTask: false,
      knowledge: true,
      date: DateTime(2024, 3, 3),
    ));
    expect(store.read()!.date, DateTime(2024, 3, 3));
    expect(store.read()!.knowledge, isTrue);
  });

  group('modifica a metà di una nota salvata', () {
    late EditDraftStore edits;

    setUp(() => edits = EditDraftStore(File('${root.path}/edits/ws.json')));

    test('scrive e rilegge nota, testo e cursore', () {
      expect(edits.read(), isNull);
      edits.write('20261020-nota', (
        title: 'Titolo',
        body: 'Corpo cambiato',
        tags: const ['studio'],
        sources: const [],
        isTask: true,
        knowledge: false,
        date: null,
      ), 5);
      final edit = edits.read()!;
      expect(edit.noteId, '20261020-nota');
      expect(edit.cursor, 5);
      expect(edit.draft.body, 'Corpo cambiato');
      expect(edit.draft.tags, ['studio']);
      edits.clear();
      expect(edits.file.existsSync(), isFalse);
    });

    test('un file senza nota non vale', () {
      edits.file
        ..createSync(recursive: true)
        ..writeAsStringSync('{"body": "x"}');
      expect(edits.read(), isNull);
    });
  });
}
