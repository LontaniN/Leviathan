import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/app.dart';
import 'package:leviathan/data/storage_access.dart';
import 'package:leviathan/data/workspace_repository.dart';
import 'package:leviathan/state/app_state.dart';
import 'package:leviathan/state/settings.dart';
import 'package:leviathan/ui/graph_screen.dart';
import 'package:leviathan/ui/theme.dart';

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
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
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
    expect(await tester.runAsync(repo.readLastWorkspace), 'Fotografia');
  });

  testWidgets('senza permesso mostra la richiesta di accesso', (tester) async {
    final storage = _FakeStorage(root, granted: false);
    await tester.pumpWidget(LeviathanApp(state: AppState(storage)));
    await settle(tester);

    expect(find.text('Concedi accesso'), findsOneWidget);
    await tester.tap(find.text('Concedi accesso'));
    await settle(tester);

    expect(find.text('Crea workspace'), findsOneWidget);
  });

  testWidgets('scrive una nota con tag suggeriti e la riapre', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
      final dir = Directory('${root.path}/Lavoro');
      File('${dir.path}/vecchia.md').writeAsStringSync(
        '---\ntitle: "Vecchia"\ntags: ["fotografia"]\n'
        'sources: ["Mario Rossi"]\n'
        'created: "2026-01-01T00:00:00.000"\n---\nTesto vecchio',
      );
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);
    expect(find.text('Vecchia'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('title-field')), 'Luce');
    await tester.enterText(
      find.byKey(const Key('body-field')),
      'La luce del mattino',
    );
    await tester.enterText(find.byKey(const Key('tag-field')), 'fotogr');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'fotografia  1'));
    await tester.enterText(find.byKey(const Key('tag-field')), 'Luce Naturale');
    // "mario r" + suggerimento riusa la grafia esistente; "Anna" è nuova.
    await tester.enterText(find.byKey(const Key('source-field')), 'mario r');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Mario Rossi  1'));
    await tester.enterText(find.byKey(const Key('source-field')), 'Anna,');
    await tester.pump();
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
    expect(saved, contains('sources: ["Mario Rossi","Anna"]'));

    // Lista espansa: anteprima e tag; poi si apre la nota.
    await tester.tap(find.byKey(const Key('list-toggle')));
    await settle(tester);
    expect(find.text('Tutte le note (2)'), findsOneWidget);
    expect(find.text('La luce del mattino'), findsOneWidget);

    await tester.tap(find.text('Luce'));
    await settle(tester);
    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('luce-naturale'), findsOneWidget);
  });

  testWidgets('ricerca con testo, filtro tag e filtro fonte', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      void write(String id, String title, String tags, String sources) =>
          File('$dir/$id.md').writeAsStringSync(
            '---\ntitle: "$title"\ntags: $tags\nsources: $sources\n'
            'created: "2026-01-0${id}T00:00:00.000"\n---\nCorpo $title',
          );
      write('1', 'Esposizione', '["fotografia"]', '["Mario Rossi"]');
      write('2', 'Luce del mattino', '["fotografia"]', '["Anna"]');
      write('3', 'Riunione luce', '["lavoro"]', '["Mario Rossi"]');
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('search-button')));
    await settle(tester);

    // Ricerca vuota: si vedono le opzioni dei filtri.
    expect(
      find.textContaining('note con un tag', findRichText: true),
      findsOneWidget,
    );

    final field = find.byKey(const Key('search-field'));
    await tester.enterText(field, 'luce');
    await tester.pump();
    expect(find.text('2 RISULTATI'), findsOneWidget);

    // "#fot" + invio: il primo suggerimento diventa un filtro.
    await tester.enterText(field, 'luce #fot');
    await tester.pump();
    expect(find.text('fotografia'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.text('1 RISULTATO'), findsOneWidget);

    // Solo filtri: tolto il testo, tag fotografia + fonte Mario Rossi.
    await tester.enterText(field, 'da:mario');
    await tester.pump();
    await tester.tap(find.text('Mario Rossi'));
    await tester.pump();
    expect(find.text('1 RISULTATO'), findsOneWidget);
    expect(find.text('Esposizione'), findsOneWidget);
  });

  testWidgets('grafo: apre, mostra i numeri e seleziona una nota', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      void write(String id, String title, String tags) =>
          File('$dir/$id.md').writeAsStringSync(
            '---\ntitle: "$title"\ntags: $tags\n'
            'created: "2026-01-0${id}T00:00:00.000"\n---\n',
          );
      write('1', 'Esposizione', '["fotografia"]');
      write('2', 'Luce', '["fotografia"]');
      write('3', 'Risotto', '[]');
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('graph-button')));
    await settle(tester);

    expect(find.text('3 note · 1 collegamento'), findsOneWidget);

    // Il tocco al centro di un nodo lo seleziona e mostra la scheda.
    final state = tester.state(find.byType(GraphScreen)) as dynamic;
    final Offset screen = state.debugNodeScreenPosition('3');
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const Key('graph-canvas'))) + screen,
    );
    await tester.pump();
    expect(find.byKey(const Key('graph-card')), findsOneWidget);
    expect(find.text('Risotto'), findsWidgets);

    // Chiudendo il grafo le posizioni vengono salvate.
    await tester.pageBack();
    await settle(tester);
    expect(
      File('${root.path}/.leviathan/graph/Lavoro.json').existsSync(),
      isTrue,
    );
  });

  testWidgets('fonti: elenco, ricerca e note di una persona', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      void write(String id, String title, String sources) =>
          File('$dir/$id.md').writeAsStringSync(
            '---\ntitle: "$title"\nsources: $sources\n'
            'created: "2026-01-0${id}T00:00:00.000"\n---\n',
          );
      write('1', 'Consiglio sul tempo', '["Mario Rossi"]');
      write('2', 'Ricetta', '["Anna", "Mario Rossi"]');
      write('3', 'Libro', '["Anna"]');
      write('4', 'Viaggio', '["Giulia"]');
    });

    await tester.pumpWidget(LeviathanApp(state: AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('sources-button')));
    await settle(tester);

    // Tutte le fonti, dalla più citata.
    expect(find.text('3 FONTI'), findsOneWidget);
    expect(find.text('2 note'), findsNWidgets(2));
    expect(find.text('Giulia'), findsOneWidget);

    // La ricerca ignora maiuscole e accenti.
    await tester.enterText(find.byKey(const Key('sources-search')), 'mario');
    await tester.pump();
    expect(find.text('1 FONTE'), findsOneWidget);
    expect(find.text('Giulia'), findsNothing);

    // Le note di Mario Rossi, anche quella con due fonti.
    await tester.tap(find.text('Mario Rossi'));
    await settle(tester);
    expect(find.text('2 NOTE'), findsOneWidget);
    expect(find.text('Consiglio sul tempo'), findsOneWidget);
    expect(find.text('Ricetta'), findsOneWidget);
    expect(find.text('Libro'), findsNothing);
  });

  testWidgets('sceglie una palette dalle impostazioni e la salva', (
    tester,
  ) async {
    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
    });
    final file = File('${root.path}/preferences.json');
    final settings = Settings(file: file);

    await tester.pumpWidget(
      LeviathanApp(state: AppState(_FakeStorage(root)), settings: settings),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('settings-button')));
    await settle(tester);
    expect(find.text('Impostazioni'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('palette-carta')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('palette-carta')));
    await settle(tester);

    expect(settings.palette, LeviathanPalette.carta);
    final context = tester.element(find.text('Impostazioni'));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(file.readAsStringSync(), contains('"carta"'));
  });
}
