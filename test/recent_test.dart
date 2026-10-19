import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/note_repository.dart';
import 'package:leviathan/data/recent_store.dart';
import 'package:leviathan/state/notes_controller.dart';

void main() {
  late Directory root;
  late NoteRepository repo;
  late RecentStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('leviathan_recent');
    repo = NoteRepository(
      Directory('${root.path}/ws'),
      trashDir: Directory('${root.path}/trash'),
    );
    store = RecentStore(File('${root.path}/recent/ws.json'));
  });

  tearDown(() => root.deleteSync(recursive: true));

  NotesController controller() => NotesController(repo, recent: store);

  test('le note aperte di recente, dalla più recente e senza doppioni', () {
    final notes = controller();
    final a = notes.create(title: 'A', body: '', tags: [], sources: []);
    final b = notes.create(title: 'B', body: '', tags: [], sources: []);
    final c = notes.create(title: 'C', body: '', tags: [], sources: []);
    notes
      ..markOpened(a.id)
      ..markOpened(b.id)
      ..markOpened(c.id)
      ..markOpened(a.id);
    expect(notes.recentlyOpened().map((n) => n.title), ['A', 'C', 'B']);
    expect(notes.recentlyOpened(limit: 2).map((n) => n.title), ['A', 'C']);
  });

  test('si ricordano alla riapertura, senza le note eliminate', () {
    final notes = controller();
    final a = notes.create(title: 'A', body: '', tags: [], sources: []);
    final b = notes.create(title: 'B', body: '', tags: [], sources: []);
    notes
      ..markOpened(a.id)
      ..markOpened(b.id)
      ..delete(b);
    expect(controller().recentlyOpened().map((n) => n.title), ['A']);
  });

  test('ne tiene al massimo ${RecentStore.limit}', () {
    final notes = controller();
    for (var i = 0; i < RecentStore.limit + 5; i++) {
      notes.markOpened('nota-$i');
    }
    expect(store.read(), hasLength(RecentStore.limit));
    expect(store.read().first, 'nota-${RecentStore.limit + 4}');
  });
}
