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
