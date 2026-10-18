import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/app.dart';
import 'package:leviathan/data/storage_access.dart';
import 'package:leviathan/data/workspace_repository.dart';
import 'package:leviathan/state/app_state.dart';
import 'package:leviathan/state/settings.dart';
import 'package:leviathan/ui/app_tour.dart';
import 'package:leviathan/ui/graph_screen.dart';
import 'package:leviathan/ui/search_screen.dart';
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

/// L'app in italiano, come se la lingua fosse già stata scelta: la maggior
/// parte dei test controlla i testi italiani.
LeviathanApp _app(AppState state) => LeviathanApp(
  state: state,
  settings: Settings(language: 'it'),
);

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
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
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

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
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

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
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
    await tester.pumpWidget(_app(AppState(storage)));
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

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
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
    // Niente avviso in basso: la voce della nota nuova si illumina e poi
    // torna normale.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SnackBar), findsNothing);
    Color flashOf(String title) {
      final box = tester.widget<DecoratedBox>(
        find.ancestor(
          of: find.text(title),
          matching: find.byKey(const Key('save-flash')),
        ),
      );
      return (box.decoration as BoxDecoration).color!;
    }

    expect(flashOf('Luce').a, greaterThan(0));
    expect(flashOf('Vecchia').a, 0);
    await settle(tester);
    expect(flashOf('Luce').a, 0);

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

  testWidgets('salva una nota datata a un giorno scelto col calendario', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => WorkspaceRepository(root).createWorkspace('Lavoro'),
    );
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.enterText(find.byKey(const Key('title-field')), 'Quaderno');
    await tester.ensureVisible(find.byKey(const Key('date-button')));
    await tester.tap(find.byKey(const Key('date-button')));
    await tester.pumpAndSettle();
    expect(find.text('Quando è stata scritta?'), findsOneWidget);
    await tester.tap(find.byTooltip('Mese precedente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Il pulsante si accende e mostra il giorno scelto.
    final button = find.byKey(const Key('date-button'));
    expect(
      find.descendant(of: button, matching: find.text('3')),
      findsOneWidget,
    );

    await tester.tap(find.text('Salva nota'));
    await tester.pump();
    expect(find.textContaining('Salvata al 3 '), findsOneWidget);

    final now = DateTime.now();
    final day = DateTime(now.year, now.month - 1, 3);
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${day.year}${two(day.month)}${two(day.day)}';
    final files = Directory('${root.path}/Lavoro')
        .listSync()
        .map((f) => f.path)
        .where((p) => p.contains('quaderno'));
    expect(files.single, contains('$stamp-'));
    final saved = File(files.single).readAsStringSync();
    expect(saved, contains('created: "${day.year}-${two(day.month)}-03T'));

    // Dopo il salvataggio il calendario torna a oggi.
    expect(
      find.descendant(of: button, matching: find.text('${now.day}')),
      findsOneWidget,
    );
    await settle(tester);
  });

  testWidgets('crea un task, lo spunta dalla lista e lo ritrova', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final repo = WorkspaceRepository(root);
    await tester.runAsync(() => repo.createWorkspace('Studio'));
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.text('Task'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('title-field')), 'Esame');
    await tester.ensureVisible(find.text('Salva task'));
    await tester.tap(find.text('Salva task'));
    await settle(tester);

    File taskFile() =>
        Directory('${root.path}/Studio')
            .listSync()
            .whereType<File>()
            .singleWhere((f) => f.path.contains('esame'));
    expect(taskFile().readAsStringSync(), contains('done: false'));

    // Spunta dalla lista delle recenti.
    final check = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('task-check-'),
    );
    await tester.tap(check);
    await settle(tester);
    expect(taskFile().readAsStringSync(), contains('done: true'));
    expect(taskFile().readAsStringSync(), contains('done_at:'));

    // Il filtro stato:fatto lo trova, stato:aperto no.
    await tester.tap(find.byKey(const Key('search-button')));
    await settle(tester);
    final field = find.byKey(const Key('search-field'));
    await tester.enterText(field, 'stato:fatto ');
    await settle(tester);
    expect(find.text('1 RISULTATO'), findsOneWidget);
    expect(find.text('Esame'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await settle(tester);
    await tester.enterText(field, 'stato:aperto ');
    await settle(tester);
    expect(find.text('Nessuna nota trovata'), findsOneWidget);
  });

  testWidgets('Markdown: barra di formattazione e checklist spuntabile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final repo = WorkspaceRepository(root);
    await tester.runAsync(() => repo.createWorkspace('Studio'));
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    // La barra compare scrivendo il corpo; un invio continua la checklist.
    expect(find.byKey(const Key('format-bar')), findsNothing);
    final body = find.byKey(const Key('body-field'));
    await tester.tap(body);
    await tester.pump();
    expect(find.byKey(const Key('format-bar')), findsOneWidget);
    await tester.tap(find.byTooltip('Checklist'));
    await tester.pump();
    await tester.enterText(body, '- [ ] latte');
    await tester.enterText(body, '- [ ] latte\n');
    await tester.pump();
    final field = tester.widget<TextField>(body);
    expect(field.controller!.text, '- [ ] latte\n- [ ] ');
    await tester.enterText(body, '- [ ] latte\n- [ ] pane');
    await tester.enterText(find.byKey(const Key('title-field')), 'Spesa');
    await tester.ensureVisible(find.text('Salva nota'));
    await tester.tap(find.text('Salva nota'));
    await settle(tester);

    File noteFile() =>
        Directory('${root.path}/Studio')
            .listSync()
            .whereType<File>()
            .singleWhere((f) => f.path.contains('spesa'));

    // Nella lettura le caselle si spuntano e il file si aggiorna.
    await tester.tap(find.text('Spesa'));
    await settle(tester);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
    await settle(tester);
    expect(noteFile().readAsStringSync(), contains('- [ ] latte\n- [x] pane'));
  });

  testWidgets('schermata task: raggruppa per tag o per fonte', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Studio');
      final dir = Directory('${root.path}/Studio');
      File('${dir.path}/esame.md').writeAsStringSync(
        '---\ntitle: "Esame"\ntags: ["universita"]\n'
        'sources: ["Anna"]\ntype: "task"\ndone: false\n---\n',
      );
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.byKey(const Key('lists-button')));
    await settle(tester);
    // Si apre sul filtro "Da fare".
    expect(find.text('1 task da fare'), findsOneWidget);
    expect(find.text('universita'), findsOneWidget);

    // La tendina in alto a destra lascia solo i fatti: qui non ce n'è.
    await tester.tap(find.byKey(const Key('task-filter')));
    await settle(tester);
    await tester.tap(find.text('Fatte').last);
    await settle(tester);
    expect(find.text('Nessun task fatto.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('task-filter')));
    await settle(tester);
    await tester.tap(find.text('Tutte').last);
    await settle(tester);

    // Il riquadro del tag mostra i task da fare; toccandolo si apre
    // l'elenco.
    expect(find.text('Esame'), findsOneWidget);
    await tester.tap(find.text('universita'));
    await settle(tester);
    expect(find.text('1 TASK · 1 DA FARE'), findsOneWidget);
    expect(find.text('Esame'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text('Per fonte'));
    await settle(tester);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('universita'), findsNothing);
  });

  testWidgets('lampadina: la nota va fra la conoscenza, non fra le note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Studio');
      File(
        '${root.path}/Studio/diario.md',
      ).writeAsStringSync('---\ntitle: "Diario"\ntags: ["universita"]\n---\n');
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.byKey(const Key('knowledge-toggle')));
    await tester.pump();
    expect(find.text('Cosa sai?'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('title-field')), 'Teorema');
    await tester.ensureVisible(find.text('Salva nota'));
    await tester.tap(find.text('Salva nota'));
    await settle(tester);

    final saved = Directory('${root.path}/Studio')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.contains('teorema'));
    expect(saved.readAsStringSync(), contains('knowledge: true'));

    await tester.tap(find.byKey(const Key('lists-button')));
    await settle(tester);
    await tester.tap(find.text('Conoscenza'));
    await settle(tester);
    expect(find.text('Teorema'), findsOneWidget);
    expect(find.text('Diario'), findsNothing);

    await tester.tap(find.text('Note').last);
    await settle(tester);
    expect(find.text('Diario'), findsOneWidget);
    expect(find.text('Teorema'), findsNothing);
  });

  testWidgets('task e note: la barra cerca solo nell\'elenco scelto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Studio');
      File('${root.path}/Studio/teorema.md').writeAsStringSync(
        '---\ntitle: "Teorema di Pitagora"\nknowledge: true\n---\n',
      );
      File('${root.path}/Studio/diario.md')
          .writeAsStringSync('---\ntitle: "Ripasso"\n---\nOggi Pitagora.\n');
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.byKey(const Key('lists-button')));
    await settle(tester);
    await tester.tap(find.text('Conoscenza'));
    await settle(tester);
    expect(find.text('Cerca nella conoscenza'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('lists-search')), 'pitagora');
    await settle(tester);
    expect(find.byType(NoteResultTile), findsOneWidget);
    expect(find.byKey(const Key('grouping-toggle')), findsNothing);

    await tester.tap(find.text('Note').last);
    await settle(tester);
    expect(find.byType(NoteResultTile), findsOneWidget);
    expect(find.text('Ripasso', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Task').last);
    await settle(tester);
    expect(find.byType(NoteResultTile), findsNothing);
    expect(find.text('Nessun risultato fra i task.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lists-search-clear')));
    await settle(tester);
    expect(find.byKey(const Key('grouping-toggle')), findsOneWidget);
  });

  testWidgets('ricerca: "tag:" elenca tutti i tag, da scorrere', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      for (var i = 1; i <= 12; i++) {
        File(
          '${root.path}/Lavoro/n$i.md',
        ).writeAsStringSync('---\ntitle: "Nota $i"\ntags: ["tema-$i"]\n---\n');
      }
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('search-button')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('search-field')), 'tag:');
    await settle(tester);

    final last = find.text('tema-12');
    await tester.scrollUntilVisible(
      last,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(last, findsOneWidget);
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

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
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

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
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
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(
      File('${root.path}/.leviathan/graph/Lavoro.json').existsSync(),
      isTrue,
    );
  });

  testWidgets('vista note: raggruppa per tag o per fonte, senza i task', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      void write(
        String id,
        String title,
        String tags,
        String sources, {
        bool task = false,
      }) => File('$dir/$id.md').writeAsStringSync(
        '---\ntitle: "$title"\ntags: $tags\nsources: $sources\n'
        '${task ? 'type: "task"\n' : ''}'
        'created: "2026-01-0${id}T00:00:00.000"\n---\n',
      );
      write('1', 'Consiglio sul tempo', '["meteo"]', '["Mario Rossi"]');
      write('2', 'Ricetta', '["cucina"]', '["Anna", "Mario Rossi"]');
      write('3', 'Libro', '[]', '["Anna"]');
      write('4', 'Chiamare Giulia', '["meteo"]', '["Giulia"]', task: true);
    });

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('lists-button')));
    await settle(tester);
    await tester.tap(find.text('Note'));
    await settle(tester);

    // Per tag: i task restano nell'altra vista.
    expect(find.text('3 note'), findsOneWidget);
    expect(find.text('meteo'), findsOneWidget);
    expect(find.text('cucina'), findsOneWidget);
    expect(find.text('Senza tag'), findsOneWidget);
    expect(find.text('Chiamare Giulia'), findsNothing);

    // Anche "Senza tag" ha la sua ricerca.
    await tester.tap(find.text('Senza tag'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('group-search-button')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('group-search')), 'libr');
    await settle(tester);
    expect(find.text('Libro'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('group-search')), 'ricetta');
    await settle(tester);
    expect(find.text('Ricetta'), findsNothing);
    expect(
      find.text('Nessun risultato fra le note senza tag.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // Per fonte: una nota con due fonti compare in entrambi i gruppi.
    await tester.tap(find.text('Per fonte'));
    await settle(tester);
    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Giulia'), findsNothing);
    expect(find.text('Ricetta'), findsNWidgets(2));

    // Il riquadro apre le note della fonte, dalla più recente.
    await tester.tap(find.text('Mario Rossi'));
    await settle(tester);
    expect(find.text('2 NOTE'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ricetta')).dy,
      lessThan(tester.getTopLeft(find.text('Consiglio sul tempo')).dy),
    );
    expect(find.text('Libro'), findsNothing);

    // Dalla nota, la fonte apre la sua schermata e non la ricerca.
    await tester.tap(find.text('Ricetta'));
    await settle(tester);
    await tester.tap(find.text('Anna'));
    await settle(tester);
    expect(find.text('2 NOTE'), findsOneWidget);
    expect(find.text('Libro'), findsOneWidget);
    expect(find.byKey(const Key('search-field')), findsNothing);

    // La lente cerca solo fra le note di Anna.
    await tester.tap(find.byKey(const Key('group-search-button')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('group-search')), 'libro');
    await settle(tester);
    expect(find.text('Libro'), findsOneWidget);
    expect(find.text('Ricetta'), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(BackButton));
      await settle(tester);
    }

    // Tornando ai task il raggruppamento resta per fonte.
    await tester.tap(find.text('Task'));
    await settle(tester);
    expect(find.text('Giulia'), findsOneWidget);
    expect(find.text('Chiamare Giulia'), findsOneWidget);
  });

  testWidgets('calendario: la ricerca lascia solo i giorni trovati', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    String day(int d) => DateTime(now.year, now.month, d).toIso8601String();
    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Diario');
      final dir = '${root.path}/Diario';
      File('$dir/a.md').writeAsStringSync(
        '---\ntitle: "Gita"\ncreated: "${day(1)}"\n---\n'
        'Siamo andati al lago con Anna.',
      );
      File('$dir/b.md').writeAsStringSync(
        '---\ntitle: "Spesa"\ncreated: "${day(2)}"\n---\nPane e latte.',
      );
    });

    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('calendar-button')));
    await settle(tester);
    // Nei test è una build di sviluppo: via i dati di prova.
    await tester.tap(find.byKey(const Key('demo-toggle')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('calendar-search-button')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('calendar-search')), 'lago');
    await settle(tester);

    expect(find.text('1 nota in 1 giorno'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(
      find.textContaining('lago con Anna', findRichText: true),
      findsOneWidget,
    );

    // La casella apre solo le note del giorno che contengono la parola.
    await tester.tap(find.text('1'));
    await settle(tester);
    expect(find.text('Gita'), findsOneWidget);
    expect(find.text('Spesa'), findsNothing);
  });

  testWidgets('fissa una nota in cima tenendola premuta', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      File('$dir/vecchia.md').writeAsStringSync(
        '---\ntitle: "Vecchia"\ncreated: "2026-01-01T00:00:00.000"\n---\n',
      );
      File('$dir/nuova.md').writeAsStringSync(
        '---\ntitle: "Nuova"\ncreated: "2026-02-01T00:00:00.000"\n---\n',
      );
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);
    expect(find.text('FISSATE'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Nuova')).dy,
      lessThan(tester.getTopLeft(find.text('Vecchia')).dy),
    );

    await tester.longPress(find.text('Vecchia'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('action-pin')));
    await settle(tester);

    expect(find.text('FISSATE'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Vecchia')).dy,
      lessThan(tester.getTopLeft(find.text('Nuova')).dy),
    );
    expect(
      File('${root.path}/Lavoro/vecchia.md').readAsStringSync(),
      contains('pinned: true'),
    );
  });

  testWidgets('fissa dagli elenchi e ritrova tutto fra le fissate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      File('${root.path}/Lavoro/antica.md').writeAsStringSync(
        '---\ntitle: "Antica"\ntags: ["storia"]\n'
        'created: "2025-01-01T00:00:00.000"\n---\n',
      );
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    // Senza fissate la schermata lo spiega.
    await tester.tap(find.byKey(const Key('pinned-button')));
    await settle(tester);
    expect(find.textContaining('Nessuna nota fissata'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // Dal riquadro del tag, la puntina accanto alla nota la fissa.
    await tester.tap(find.byKey(const Key('lists-button')));
    await settle(tester);
    await tester.tap(find.text('Note'));
    await settle(tester);
    await tester.tap(find.text('storia'));
    await settle(tester);
    final pin = find.byKey(const Key('pin-antica'));
    await tester.tap(pin);
    await settle(tester);
    expect(tester.widget<IconButton>(pin).isSelected, isTrue);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(BackButton));
      await settle(tester);
    }

    await tester.tap(find.byKey(const Key('pinned-button')));
    await settle(tester);
    expect(find.text('1 NOTA FISSATA'), findsOneWidget);
    expect(find.text('Antica'), findsOneWidget);

    // Staccata, esce dall'elenco; "Annulla" la rimette.
    await tester.tap(find.byKey(const Key('pin-antica')));
    await settle(tester);
    expect(find.text('Antica'), findsNothing);
    await tester.tap(find.text('Annulla'));
    await settle(tester);
    expect(find.text('Antica'), findsOneWidget);
    expect(
      File('${root.path}/Lavoro/antica.md').readAsStringSync(),
      contains('pinned: true'),
    );
  });

  testWidgets('elimina una nota dalla lettura e annulla', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final file = File('${root.path}/Lavoro/idea.md');
    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      file.writeAsStringSync(
        '---\ntitle: "Idea"\ncreated: "2026-01-01T00:00:00.000"\n---\n'
        'Una frase di cinque parole.',
      );
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.text('Idea'));
    await settle(tester);
    expect(find.textContaining('5 parole'), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('delete-note')));
    await settle(tester);

    // Si torna alla home: la nota è nel cestino e l'avviso offre di
    // annullare.
    expect(file.existsSync(), isFalse);
    expect(find.text('Idea'), findsNothing);
    await tester.tap(find.text('Annulla'));
    await settle(tester);
    expect(file.existsSync(), isTrue);
    expect(find.text('Idea'), findsOneWidget);
  });

  testWidgets('la bozza della home resta dopo la riapertura', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(
      () => WorkspaceRepository(root).createWorkspace('Lavoro'),
    );
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.enterText(find.byKey(const Key('title-field')), 'A metà');
    await settle(tester);
    final draft = File('${root.path}/.leviathan/drafts/Lavoro.json');
    expect(draft.readAsStringSync(), contains('A metà'));

    // L'app riparte da zero: il titolo è ancora nel campo.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);
    final title = tester.widget<TextField>(
      find.byKey(const Key('title-field')),
    );
    expect(title.controller!.text, 'A metà');

    // Salvata la nota, la bozza sparisce.
    await tester.ensureVisible(find.text('Salva nota'));
    await tester.tap(find.text('Salva nota'));
    await settle(tester);
    expect(draft.existsSync(), isFalse);
  });

  testWidgets('sceglie una palette dalle impostazioni e la salva', (
    tester,
  ) async {
    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
    });
    final file = File('${root.path}/preferences.json');
    final settings = Settings(file: file, language: 'it');

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

  testWidgets('primo avvio: si sceglie la lingua dal menu a tendina', (
    tester,
  ) async {
    final file = File('${root.path}/preferences.json');
    final settings = Settings(file: file);
    await tester.pumpWidget(
      LeviathanApp(state: AppState(_FakeStorage(root)), settings: settings),
    );
    await settle(tester);

    // Nei test la lingua del "telefono" è l'inglese.
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language-menu')));
    await settle(tester);
    await tester.tap(find.text('Italiano').last);
    await settle(tester);
    // La schermata si riscrive subito nella lingua scelta.
    expect(find.text('Scegli la lingua'), findsOneWidget);
    expect(settings.language, isNull);

    await tester.tap(find.byKey(const Key('language-continue')));
    await settle(tester);
    expect(settings.language, 'it');
    expect(file.readAsStringSync(), contains('"language":"it"'));
    expect(find.text('Crea workspace'), findsOneWidget);
  });

  testWidgets('in inglese tutta la UI è in inglese', (tester) async {
    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Work');
    });
    await tester.pumpWidget(
      LeviathanApp(
        state: AppState(_FakeStorage(root)),
        settings: Settings(language: 'en'),
      ),
    );
    await settle(tester);

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Search notes'), findsOneWidget);
    expect(find.text('Save note'), findsOneWidget);
    expect(find.byKey(const Key('home-summary')), findsOneWidget);
    expect(find.text('0 notes'), findsOneWidget);
  });

  testWidgets('cambia lingua dalle impostazioni', (tester) async {
    final repo = WorkspaceRepository(root);
    await tester.runAsync(() async {
      await repo.createWorkspace('Lavoro');
    });
    final settings = Settings(language: 'en');
    await tester.pumpWidget(
      LeviathanApp(state: AppState(_FakeStorage(root)), settings: settings),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('settings-button')));
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-language')));
    await settle(tester);
    await tester.tap(find.text('Italiano').last);
    await settle(tester);

    expect(settings.language, 'it');
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.text('Inchiostro'), findsOneWidget);
  });

  testWidgets('tour guidato al primo workspace: avanti, indietro, fine', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final file = File('${root.path}/preferences.json');
    final settings = Settings(file: file, language: 'it');
    await tester.pumpWidget(
      LeviathanApp(state: AppState(_FakeStorage(root)), settings: settings),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Lavoro');
    await tester.tap(find.text('Crea workspace'));
    await settle(tester);

    expect(find.text('Lavoro è pronto'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-start')));
    await settle(tester);
    expect(find.text('1 DI 6'), findsOneWidget);
    expect(find.text('Scrivi una nota'), findsOneWidget);
    // Sul primo passo non si torna indietro.
    expect(find.byKey(const Key('tour-back')), findsNothing);

    await tester.tap(find.byKey(const Key('tour-next')));
    await settle(tester);
    expect(find.text('I tag collegano tutto'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-back')));
    await settle(tester);
    expect(find.text('Scrivi una nota'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('tour-next')));
      await settle(tester);
    }
    expect(find.text('5 DI 6'), findsOneWidget);
    expect(find.text('Metti in ordine i task'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-next')));
    await settle(tester);
    expect(find.text('6 DI 6'), findsOneWidget);
    expect(find.text('Le altre viste'), findsOneWidget);
    // All'ultimo passo resta solo Fine.
    expect(find.byKey(const Key('tour-skip')), findsNothing);
    await tester.tap(find.text('Fine'));
    await settle(tester);

    expect(find.byType(AppTour), findsNothing);
    expect(settings.tourSeen, isTrue);
    expect(file.readAsStringSync(), contains('"tourSeen":true'));
    // Finito il tour la home risponde di nuovo.
    await tester.tap(find.byKey(const Key('settings-button')));
    await settle(tester);
    expect(find.text('Impostazioni'), findsOneWidget);
  });

  testWidgets('il tour si salta e non riparte', (tester) async {
    final settings = Settings(language: 'it');
    final state = AppState(_FakeStorage(root));
    await tester.pumpWidget(LeviathanApp(state: state, settings: settings));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Lavoro');
    await tester.tap(find.text('Crea workspace'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('tour-skip')));
    await settle(tester);
    expect(find.byType(AppTour), findsNothing);
    expect(settings.tourSeen, isTrue);

    // Un secondo workspace non lo fa ripartire.
    await tester.runAsync(() => state.createWorkspace('Studio'));
    await settle(tester);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.byType(AppTour), findsNothing);
  });

  testWidgets('niente tour aprendo un workspace che c\'era già', (
    tester,
  ) async {
    await tester.runAsync(() => WorkspaceRepository(root).createWorkspace('A'));
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    expect(find.text('A'), findsOneWidget);
    expect(find.byType(AppTour), findsNothing);
  });

  testWidgets('il tour si rivede dalle impostazioni', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() => WorkspaceRepository(root).createWorkspace('A'));
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.byKey(const Key('settings-button')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('replay-tour')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('replay-tour')));
    await settle(tester);

    // Torna alla home e parte dal primo passo, senza benvenuto.
    expect(find.text('Impostazioni'), findsNothing);
    expect(find.byKey(const Key('tour-welcome')), findsNothing);
    expect(find.text('1 DI 6'), findsOneWidget);
  });

  testWidgets('task manager: ordina a confronti, spunta e ritrova', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      void task(String id, String extra) => File('$dir/$id.md')
          .writeAsStringSync(
            '---\ntitle: "$id"\ntags: ["casa"]\n'
            'created: "2026-10-01T00:00:00.000"\n'
            'type: "task"\ndone: false\n$extra---\n',
          );
      task('Primo', 'priority: "now"\nrank: "c"\n');
      task('Terzo', 'priority: "now"\nrank: "m"\n');
      task('Nuovo', '');
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);

    await tester.tap(find.byKey(const Key('task-manager-button')));
    await settle(tester);
    expect(find.text('DA ORDINARE'), findsOneWidget);
    expect(find.byKey(const Key('now-load')), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Trascina qui un task'), findsNWidgets(2));

    // "Nuovo" va in Ora, dopo "Primo" e prima di "Terzo".
    await tester.tap(find.byKey(const Key('compare-Nuovo')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose-now')));
    await settle(tester);
    expect(find.text('Quale viene prima?'), findsOneWidget);
    // Il primo confronto è con "Terzo" (a metà): viene prima il nuovo.
    expect(
      find.descendant(
        of: find.byKey(const Key('compare-pivot')),
        matching: find.text('Terzo'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('compare-new')));
    await settle(tester);
    // Poi con "Primo": viene prima lui.
    await tester.tap(find.byKey(const Key('compare-pivot')));
    await settle(tester);

    expect(find.text('DA ORDINARE'), findsNothing);
    expect(find.text('3/3'), findsOneWidget);
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Primo'), lessThan(y('Nuovo')));
    expect(y('Nuovo'), lessThan(y('Terzo')));
    final file = File('${root.path}/Lavoro/Nuovo.md').readAsStringSync();
    expect(file, contains('priority: "now"'));

    // Spuntato esce da "Da fare" e compare fra i completati.
    await tester.tap(find.byKey(const Key('task-check-Primo')));
    await settle(tester);
    expect(find.text('Primo'), findsNothing);
    expect(find.text('Fatto: Primo'), findsOneWidget);
    await tester.tap(find.text('Completati'));
    await settle(tester);
    expect(find.text('Primo'), findsOneWidget);
    expect(find.text('OGGI'), findsOneWidget);
  });

  testWidgets('task manager: trascina nella fascia e fra le fasce', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await WorkspaceRepository(root).createWorkspace('Lavoro');
      final dir = '${root.path}/Lavoro';
      void task(String id, String extra) =>
          File('$dir/$id.md').writeAsStringSync(
            '---\ntitle: "$id"\ncreated: "2026-10-01T00:00:00.000"\n'
            'type: "task"\ndone: false\n$extra---\n',
          );
      task('Uno', 'priority: "now"\nrank: "c"\n');
      task('Due', 'priority: "now"\nrank: "m"\n');
      task('Tre', 'priority: "later"\nrank: "i"\n');
    });
    await tester.pumpWidget(_app(AppState(_FakeStorage(root))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('task-manager-button')));
    await settle(tester);

    double y(String t) => tester.getCenter(find.text(t)).dy;
    Future<void> drag(String id, double dy) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Key('drag-$id'))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, dy / 10));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await settle(tester);
    }

    // "Due" sopra "Uno".
    await drag('Due', y('Uno') - y('Due') - 10);
    expect(y('Due'), lessThan(y('Uno')));

    // "Tre" da Più avanti in cima a Ora.
    await drag('Tre', y('Due') - y('Tre') - 10);
    expect(y('Tre'), lessThan(y('Due')));
    expect(find.text('3/3'), findsOneWidget);
    final file = File('${root.path}/Lavoro/Tre.md').readAsStringSync();
    expect(file, contains('priority: "now"'));
  });
}
