import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/atomic_write.dart';
import 'package:leviathan/data/note_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('leviathan_atomic'));
  tearDown(() => root.deleteSync(recursive: true));

  List<String> names(Directory dir) =>
      [for (final e in dir.listSync()) p.basename(e.path)]..sort();

  test('crea il file e le cartelle che mancano', () {
    final file = File(p.join(root.path, 'a', 'b', 'nota.md'));
    writeFileAtomic(file, 'ciao');
    expect(file.readAsStringSync(), 'ciao');
    expect(names(file.parent), ['nota.md']);
  });

  test('sostituisce un file esistente senza lasciare temporanei', () {
    final file = File(p.join(root.path, 'nota.md'))
      ..writeAsStringSync('vecchio');
    writeFileAtomic(file, 'nuovo');
    expect(file.readAsStringSync(), 'nuovo');
    expect(names(root), ['nota.md']);
  });

  test('se la scrittura fallisce non resta il temporaneo', () {
    // Una cartella al posto del file: il rename finale non può riuscire.
    final blocked = Directory(p.join(root.path, 'nota.md'))..createSync();
    expect(
      () => writeFileAtomic(File(blocked.path), 'testo'),
      throwsA(isA<FileSystemException>()),
    );
    expect(names(root), ['nota.md']);
    expect(blocked.existsSync(), isTrue);
  });

  test('le note ignorano un temporaneo rimasto da un crash', () {
    final dir = Directory(p.join(root.path, 'ws'))..createSync();
    File(p.join(dir.path, '.x.md.tmp'))
        .writeAsStringSync('---\ntitle: "x"\n---\n');
    final repo = NoteRepository(
      dir,
      trashDir: Directory(p.join(root.path, 't')),
    );
    expect(repo.loadAll(), isEmpty);
  });
}
