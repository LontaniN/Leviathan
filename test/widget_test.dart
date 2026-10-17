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
}
