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
    expect(
      File('${repo.workspaceDir('Ufficio').path}/a.md').existsSync(),
      true,
    );
    expect(repo.trashDir('Ufficio').existsSync(), true);
    expect(repo.trashDir('Lavoro').existsSync(), false);
    expect(repo.graphLayoutFile('Ufficio').existsSync(), true);
    expect(await repo.readLastWorkspace(), 'Ufficio');
  });

  test('rinominando ed eliminando seguono modifica a metà e recenti', () async {
    await repo.createWorkspace('Lavoro');
    for (final file in [
      repo.editDraftFile('Lavoro'),
      repo.recentFile('Lavoro'),
    ]) {
      await file.parent.create(recursive: true);
      await file.writeAsString('[]');
    }
    await repo.renameWorkspace('Lavoro', 'Ufficio');
    expect(repo.editDraftFile('Ufficio').existsSync(), true);
    expect(repo.recentFile('Ufficio').existsSync(), true);
    expect(repo.recentFile('Lavoro').existsSync(), false);

    final moved = await repo.deleteWorkspace('Ufficio');
    expect(File('${moved.path}/edit-draft.json').existsSync(), true);
    expect(File('${moved.path}/recent.json').existsSync(), true);
    expect(repo.recentFile('Ufficio').existsSync(), false);
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
    expect(moved.parent.path, endsWith('deleted'));
    expect(File('${moved.path}/notes/a.md').existsSync(), true);
    expect(Directory('${moved.path}/trash').existsSync(), true);
    expect(File('${moved.path}/graph.json').existsSync(), true);
    expect(repo.trashDir('Lavoro').existsSync(), false);
    expect(layout.existsSync(), false);
  });

  test('porta ai nomi inglesi gli eliminati delle prime versioni', () async {
    final old = '${root.path}/.leviathan/eliminati/Vecchio 2026-10-01';
    await File('$old/note/a.md').create(recursive: true);
    await Directory('$old/cestino').create();
    await File('$old/grafo.json').writeAsString('{}');
    await File('$old/bozza.json').writeAsString('{}');

    await repo.migrateLegacyNames();

    final moved = '${root.path}/.leviathan/deleted/Vecchio 2026-10-01';
    expect(File('$moved/notes/a.md').existsSync(), true);
    expect(Directory('$moved/trash').existsSync(), true);
    expect(File('$moved/graph.json').existsSync(), true);
    expect(File('$moved/draft.json').existsSync(), true);
    expect(Directory('${root.path}/.leviathan/eliminati').existsSync(), false);
    // Una seconda volta non c'è più niente da fare.
    await repo.migrateLegacyNames();
    expect(File('$moved/notes/a.md').existsSync(), true);
  });

  test('ricorda l\'ultimo workspace usato', () async {
    expect(await repo.readLastWorkspace(), isNull);
    await repo.writeLastWorkspace('Lavoro');
    expect(await repo.readLastWorkspace(), 'Lavoro');
  });

  test('validazione dei nomi', () {
    WorkspaceNameError? v(String name) =>
        WorkspaceRepository.validateName(name, ['Studio']);
    expect(v('Lavoro'), isNull);
    expect(v('Hobby e progetti 2026'), isNull);
    expect(v('   '), WorkspaceNameError.empty);
    expect(v('.nascosto'), WorkspaceNameError.leadingDot);
    expect(v('fine.'), WorkspaceNameError.trailingDot);
    expect(v('a/b'), WorkspaceNameError.invalidChars);
    expect(v('a:b'), WorkspaceNameError.invalidChars);
    expect(v('x' * 61), WorkspaceNameError.tooLong);
    expect(v('studio'), WorkspaceNameError.taken);
  });
}
