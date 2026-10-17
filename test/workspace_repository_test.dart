import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/workspace_repository.dart';

void main() {
  late Directory root;
  late WorkspaceRepository repo;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('leviathan_test');
    repo = WorkspaceRepository(root);
  });

  tearDown(() => root.delete(recursive: true));

  test('una cartella vuota non ha workspace', () async {
    expect(await repo.listWorkspaces(), isEmpty);
  });

  test('crea workspace e li elenca in ordine alfabetico', () async {
    await repo.createWorkspace('  lavoro ');
    await repo.createWorkspace('Fotografia');
    expect(await repo.listWorkspaces(), ['Fotografia', 'lavoro']);
  });

  test('ignora le cartelle nascoste e i file', () async {
    await repo.createWorkspace('Studio');
    await repo.writeLastWorkspace('Studio');
    await File('${root.path}/note.txt').writeAsString('x');
    expect(await repo.listWorkspaces(), ['Studio']);
  });

  test('rifiuta nomi duplicati senza distinguere maiuscole', () async {
    await repo.createWorkspace('Lavoro');
    expect(() => repo.createWorkspace('LAVORO'), throwsArgumentError);
  });

  test('rinomina cartella, cestino, grafo e ultimo workspace', () async {
    await repo.createWorkspace('Lavoro');
    await File('${repo.workspaceDir('Lavoro').path}/a.md').writeAsString('x');
    await repo.trashDir('Lavoro').create(recursive: true);
    final layout = repo.graphLayoutFile('Lavoro');
    await layout.parent.create(recursive: true);
    await layout.writeAsString('{}');
    await repo.writeLastWorkspace('Lavoro');

    expect(await repo.renameWorkspace('Lavoro', ' Ufficio '), 'Ufficio');
    expect(await repo.listWorkspaces(), ['Ufficio']);
    expect(File('${repo.workspaceDir('Ufficio').path}/a.md').existsSync(), true);
    expect(repo.trashDir('Ufficio').existsSync(), true);
    expect(repo.trashDir('Lavoro').existsSync(), false);
    expect(repo.graphLayoutFile('Ufficio').existsSync(), true);
    expect(await repo.readLastWorkspace(), 'Ufficio');
  });

  test('rinomina cambiando solo le maiuscole', () async {
    await repo.createWorkspace('lavoro');
    await repo.renameWorkspace('lavoro', 'Lavoro');
    expect(await repo.listWorkspaces(), ['Lavoro']);
  });

  test('non rinomina sul nome di un altro workspace', () async {
    await repo.createWorkspace('Lavoro');
    await repo.createWorkspace('Studio');
    expect(() => repo.renameWorkspace('Studio', 'lavoro'), throwsArgumentError);
  });

  test('elimina spostando note, cestino e grafo fra gli eliminati', () async {
    await repo.createWorkspace('Lavoro');
    await repo.createWorkspace('Studio');
    await File('${repo.workspaceDir('Lavoro').path}/a.md').writeAsString('x');
    await repo.trashDir('Lavoro').create(recursive: true);
    final layout = repo.graphLayoutFile('Lavoro');
    await layout.parent.create(recursive: true);
    await layout.writeAsString('{}');

    final moved = await repo.deleteWorkspace('Lavoro');
    expect(await repo.listWorkspaces(), ['Studio']);
    expect(File('${moved.path}/note/a.md').existsSync(), true);
    expect(Directory('${moved.path}/cestino').existsSync(), true);
    expect(File('${moved.path}/grafo.json').existsSync(), true);
    expect(repo.trashDir('Lavoro').existsSync(), false);
    expect(layout.existsSync(), false);
  });

  test('ricorda l\'ultimo workspace usato', () async {
    expect(await repo.readLastWorkspace(), isNull);
    await repo.writeLastWorkspace('Lavoro');
    expect(await repo.readLastWorkspace(), 'Lavoro');
  });

  test('validazione dei nomi', () {
    String? v(String name) => WorkspaceRepository.validateName(name, []);
    expect(v('Lavoro'), isNull);
    expect(v('Hobby e progetti 2026'), isNull);
    expect(v('   '), isNotNull);
    expect(v('.nascosto'), isNotNull);
    expect(v('a/b'), isNotNull);
    expect(v('a:b'), isNotNull);
    expect(v('x' * 61), isNotNull);
  });
}
