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
      nextStep: 'stasera, alla scrivania',
      date: null,
    ));
    final draft = store.read()!;
    expect(draft.title, 'Idea');
    expect(draft.body, 'Da finire');
    expect(draft.tags, ['studio']);
    expect(draft.sources, ['Anna']);
    expect(draft.isTask, isTrue);
    expect(draft.nextStep, 'stasera, alla scrivania');
  });

  test('una bozza vuota cancella il file', () {
    store.write((
      title: 'x',
      body: '',
      tags: const [],
      sources: const [],
      isTask: false,
      knowledge: false,
      nextStep: '',
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
      nextStep: '',
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
      nextStep: '',
      date: DateTime(2024, 3, 3),
    ));
    expect(store.read()!.date, DateTime(2024, 3, 3));
    expect(store.read()!.knowledge, isTrue);
  });
}
