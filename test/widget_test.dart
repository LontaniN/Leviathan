import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/app.dart';
import 'package:leviathan/data/storage_access.dart';
import 'package:leviathan/data/workspace_repository.dart';
import 'package:leviathan/state/app_state.dart';

class _FakeStorage implements StorageAccess {
  _FakeStorage(this.dir, {this.granted = true});

  final Directory dir;
  bool granted;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async => granted = true;

  @override
  Future<Directory> root() async => dir;
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('leviathan_widget');
  });

  tearDown(() => root.delete(recursive: true));

  // Il file system reale va usato fuori dal tempo simulato dei widget test.
  // Niente pumpAndSettle: lo spinner di caricamento non si fermerebbe mai.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('primo avvio: crea il workspace e lo apre', (tester) async {
    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);

    expect(find.text('Crea workspace'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lavoro');
    await tester.tap(find.text('Crea workspace'));
    await settle(tester);

    expect(find.text('Lavoro'), findsOneWidget);
    expect(Directory('${root.path}/Lavoro').existsSync(), isTrue);
  });

  testWidgets('riapre l\'ultimo workspace usato', (tester) async {
    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
      await repo.createWorkspace('Fotografia');
      await repo.writeLastWorkspace('Lavoro');
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);

    expect(find.text('Lavoro'), findsOneWidget);
    expect(find.text('Fotografia'), findsNothing);
  });

  testWidgets('cambia workspace dal menu in alto', (tester) async {
    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
      await repo.createWorkspace('Fotografia');
      await repo.writeLastWorkspace('Lavoro');
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.byKey(const Key('workspace-button')));
    await settle(tester);
    await tester.tap(find.text('Fotografia'));
    await settle(tester);

    expect(find.text('Fotografia'), findsOneWidget);
    expect(find.text('Lavoro'), findsNothing);
    expect(
      await tester.runAsync(repo.readLastWorkspace),
      'Fotografia',
    );
  });

  testWidgets('senza permesso mostra la richiesta di accesso',
      (tester) async {
    final storage = _FakeStorage(root, granted: false);
    await tester.pumpWidget(LeviathanApp(state: AppState(storage)));
    await settle(tester);

    expect(find.text('Concedi accesso'), findsOneWidget);
    await tester.tap(find.text('Concedi accesso'));
    await settle(tester);

    expect(find.text('Crea workspace'), findsOneWidget);
  });

  testWidgets('scrive una nota con tag suggeriti e la riapre',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
      final dir = Directory('${root.path}/Lavoro');
      File('${dir.path}/vecchia.md').writeAsStringSync(
          '---\ntitle: "Vecchia"\ntags: ["fotografia"]\n'
          'created: "2026-01-01T00:00:00.000"\n---\nTesto vecchio');
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);
    expect(find.text('Vecchia'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('title-field')), 'Luce');
    await tester.enterText(
        find.byKey(const Key('body-field')), 'La luce del mattino');
    await tester.enterText(find.byKey(const Key('tag-field')), 'fotogr');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'fotografia  1'));
    await tester.enterText(find.byKey(const Key('tag-field')), 'Luce Naturale');
    await tester.enterText(
        find.byKey(const Key('source-field')), 'Manuale di fotografia');
    await tester.ensureVisible(find.text('Salva nota'));
    await tester.tap(find.text('Salva nota'));
    await settle(tester);

    // La nota nuova è in cima alla lista e su disco.
    final files = Directory('${root.path}/Lavoro')
        .listSync()
        .map((f) => f.path)
        .where((p) => p.contains('luce'));
    expect(files, hasLength(1));
    final saved = File(files.single).readAsStringSync();
    expect(saved, contains('tags: ["fotografia","luce-naturale"]'));
    expect(saved, contains('source: "Manuale di fotografia"'));

    // Lista espansa: anteprima e tag; poi si apre la nota.
    await tester.tap(find.byKey(const Key('list-toggle')));
    await settle(tester);
    expect(find.text('Tutte le note (2)'), findsOneWidget);
    expect(find.text('La luce del mattino'), findsOneWidget);

    await tester.tap(find.text('Luce'));
    await settle(tester);
    expect(find.text('Manuale di fotografia'), findsOneWidget);
    expect(find.text('luce-naturale'), findsOneWidget);
  });
}
