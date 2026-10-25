import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/draft_store.dart';
import 'package:leviathan/model/note.dart';

void main() {
  final date = DateTime(2026, 10, 25, 9);

  Note task({DateTime? due, bool isTask = true}) => Note(
    id: 'x',
    title: 'Dentista',
    body: '',
    tags: const [],
    sources: const [],
    created: date,
    updated: date,
    isTask: isTask,
    due: due,
  );

  test('la scadenza di un task si scrive come giorno e si rilegge', () {
    final md = task(due: DateTime(2026, 11, 3)).toMarkdown();
    expect(md, contains('due: "2026-11-03"'));
    final back = Note.fromMarkdown('x', md, DateTime(2000));
    expect(back.due, DateTime(2026, 11, 3));
  });

  test('senza scadenza non si scrive nulla', () {
    expect(task().toMarkdown(), isNot(contains('due:')));
  });

  test('la scadenza tiene solo il giorno', () {
    final note = task(due: DateTime(2026, 11, 3, 18, 30));
    final changed = note.copyWith(due: DateTime(2026, 12, 1, 8));
    expect(changed.due, DateTime(2026, 12, 1));
  });

  test('togliendola o diventando nota la scadenza sparisce', () {
    final note = task(due: DateTime(2026, 11, 3));
    expect(note.copyWith(title: 'Altro').due, DateTime(2026, 11, 3));
    expect(note.copyWith(clearDue: true).due, isNull);
    expect(note.copyWith(isTask: false).due, isNull);
  });

  test('in una nota normale una scadenza scritta a mano resta com\'è', () {
    const content = '---\ntitle: "Gita"\ndue: "2026-11-03"\n---\nTesto';
    final note = Note.fromMarkdown('y', content, date);
    expect(note.due, isNull);
    expect(note.toMarkdown(), contains('due: "2026-11-03"'));
  });

  test('la bozza ricorda la scadenza', () {
    final root = Directory.systemTemp.createTempSync('leviathan_due');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = DraftStore(File('${root.path}/draft.json'));
    store.write((
      title: 'Dentista',
      body: '',
      tags: const [],
      sources: const [],
      isTask: true,
      knowledge: false,
      date: null,
      due: DateTime(2026, 11, 3),
    ));
    expect(store.read()?.due, DateTime(2026, 11, 3));
  });
}
