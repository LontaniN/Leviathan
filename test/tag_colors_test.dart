import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide Tags;
import 'package:leviathan/data/note_repository.dart';
import 'package:leviathan/data/tag_color_store.dart';
import 'package:leviathan/model/tags.dart';
import 'package:leviathan/state/notes_controller.dart';

void main() {
  late Directory root;
  late TagColorStore store;

  NotesController open() => NotesController(
    NoteRepository(
      Directory('${root.path}/ws'),
      trashDir: Directory('${root.path}/trash'),
    ),
    tagColors: store,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('leviathan_tag_colors');
    store = TagColorStore(File('${root.path}/tag-colors/ws.json'));
  });

  tearDown(() {
    Tags.custom = const {};
    root.deleteSync(recursive: true);
  });

  test('senza file nessun colore scelto', () {
    expect(store.read(), isEmpty);
  });

  test('un file rovinato non blocca nulla', () {
    store.file
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{"studio": "rosso", "idee": 3, "lavoro": "#5CC8C2"');
    expect(store.read(), isEmpty);
    store.file.writeAsStringSync('{"studio": "rosso", "lavoro": "#5CC8C2"}');
    expect(store.read(), {'lavoro': Tags.palette[3]});
  });

  test('il colore scelto vince su quello automatico e resta su disco', () {
    final notes = open();
    final chosen = Tags.palette.firstWhere(
      (c) => c != Tags.autoColorOf('studio'),
    );
    notes.setTagColor('studio', chosen);
    expect(Tags.colorOf('studio'), chosen);

    Tags.custom = const {};
    open();
    expect(Tags.colorOf('studio'), chosen);
  });

  test('tornare al colore automatico toglie la scelta', () {
    final notes = open();
    notes.setTagColor('studio', Tags.palette.first);
    notes.setTagColor('studio', null);
    expect(Tags.custom, isEmpty);
    expect(store.read(), isEmpty);
    expect(Tags.colorOf('studio'), Tags.autoColorOf('studio'));
  });
}
