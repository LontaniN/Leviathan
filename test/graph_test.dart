import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart' hide Tags;
import 'package:leviathan/data/graph_layout_store.dart';
import 'package:leviathan/graph/force_layout.dart';
import 'package:leviathan/graph/graph_view.dart';
import 'package:leviathan/model/graph.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/tags.dart';

Note _note(
  String id,
  List<String> tags, {
  int day = 1,
  List<String>? sources,
}) => Note(
  id: id,
  title: id,
  body: '',
  tags: tags,
  sources: sources ?? const [],
  created: DateTime(2026, 1, day),
  updated: DateTime(2026, 1, day),
);

double _dist(ForceLayout l, int a, int b) =>
    math.sqrt(math.pow(l.x[a] - l.x[b], 2) + math.pow(l.y[a] - l.y[b], 2));

void main() {
  group('costruzione del grafo', () {
    test('collega le note con tag in comune, pesando i tag condivisi', () {
      final g = NoteGraph.build([
        _note('a', ['foto', 'luce'], day: 1),
        _note('b', ['foto', 'luce'], day: 2),
        _note('c', ['foto'], day: 3),
        _note('d', ['cucina'], day: 4),
        _note('e', [], day: 5, sources: ['Mario']),
      ]);
      final byId = {
        for (final e in g.edges)
          '${g.nodes[e.a].note.id}${g.nodes[e.b].note.id}': e.weight,
      };
      expect(byId, {'ab': 2, 'ac': 1, 'bc': 1});
    });

    test('colore del primo tag, grigio senza tag', () {
      final g = NoteGraph.build([
        _note('a', ['luce', 'foto']),
        _note('b', []),
      ]);
      expect(g.nodes[0].color, Tags.colorOf('luce'));
      expect(g.nodes[1].color, untaggedColor);
    });

    test('le fonti non creano collegamenti', () {
      final g = NoteGraph.build([
        _note('a', [], sources: ['Mario']),
        _note('b', [], sources: ['Mario'], day: 2),
      ]);
      expect(g.edges, isEmpty);
    });

    test('tag molto usati: pochi collegamenti, ma il grado resta vero', () {
      final notes = [
        for (var i = 0; i < 200; i++) _note('n$i', ['lavoro'], day: 1),
      ];
      final g = NoteGraph.build(notes);
      expect(g.edges.length, lessThan(200 * NoteGraph.sampledLinks));
      expect(g.edges.length, greaterThan(200));
      expect(g.nodes.every((n) => n.degree == 199), isTrue);
    });

    test('collegamenti stabili tra una costruzione e l\'altra', () {
      final notes = [
        for (var i = 0; i < 40; i++) _note('n$i', ['x'], day: 1),
      ];
      String sig(NoteGraph g) =>
          (g.edges.map((e) => '${e.a}-${e.b}').toList()..sort()).join(',');
      expect(
        sig(NoteGraph.build(notes)),
        sig(NoteGraph.build(notes.reversed.toList())),
      );
    });
  });

  group('simulazione', () {
    test('le note collegate finiscono più vicine delle altre', () {
      final notes = [
        for (var i = 0; i < 10; i++) _note('a$i', ['foto'], day: i + 1),
        for (var i = 0; i < 10; i++) _note('b$i', ['cucina'], day: i + 11),
      ];
      final g = NoteGraph.build(notes);
      final seed = seedPositions(g, {});
      final layout = ForceLayout(
        g.nodes.length,
        [for (final e in g.edges) (a: e.a, b: e.b, weight: e.weight)],
        x: seed.x,
        y: seed.y,
      )..runToEnd();

      expect(layout.isRunning, isFalse);
      var inside = 0.0, across = 0.0;
      for (var i = 0; i < 10; i++) {
        inside += _dist(layout, i, (i + 1) % 10);
        across += _dist(layout, i, 10 + i);
      }
      expect(inside * 2, lessThan(across));
      for (var i = 0; i < g.nodes.length; i++) {
        expect(layout.x[i].isFinite && layout.y[i].isFinite, isTrue);
      }
    });

    test('regge nodi sovrapposti e grafi senza collegamenti', () {
      final layout = ForceLayout(30, const [])..runToEnd();
      final points = {
        for (var i = 0; i < 30; i++)
          '${layout.x[i].toStringAsFixed(3)},${layout.y[i].toStringAsFixed(3)}',
      };
      expect(points.length, 30); // si sono separati
    });

    test('un nodo trascinato resta fermo', () {
      final layout = ForceLayout(3, const [(a: 0, b: 1, weight: 1)]);
      layout.x[2] = 100;
      layout.pinned = 2;
      for (var i = 0; i < 50; i++) {
        layout.tick();
      }
      expect(layout.x[2], 100);
    });
  });

  group('posizioni e inquadratura', () {
    test('usa le posizioni salvate e mette le nuove vicino ai compagni', () {
      final g = NoteGraph.build([
        _note('a', ['x'], day: 1),
        _note('b', ['x'], day: 2),
      ]);
      final seed = seedPositions(g, {'a': const Offset(500, 500)});
      expect(seed.known, 1);
      expect(seed.x[0], 500);
      expect(
        (Offset(seed.x[1], seed.y[1]) - const Offset(500, 500)).distance,
        lessThan(20),
      );
    });

    test('schermo e grafo si convertono avanti e indietro', () {
      const view = GraphViewport(pan: Offset(30, -10), scale: 2);
      const size = Size(400, 800);
      const world = Offset(12, 34);
      final back = view.toWorld(view.toScreen(world, size), size);
      expect((back - world).distance, lessThan(1e-9));
    });

    test('lo zoom tiene fermo il punto sotto le dita', () {
      const size = Size(400, 800);
      const view = GraphViewport(pan: Offset(5, 5), scale: 1);
      const focal = Offset(300, 200);
      final world = view.toWorld(focal, size);
      final zoomed = view.zoomAround(focal, 3, size, worldAtFocal: world);
      expect((zoomed.toScreen(world, size) - focal).distance, lessThan(1e-9));
    });

    test('il tocco trova il nodo più vicino, con tolleranza', () {
      final g = NoteGraph.build([_note('a', []), _note('b', [], day: 2)]);
      final layout = ForceLayout(2, const []);
      layout.x[1] = 100;
      expect(
        hitTestNode(layout.x, layout.y, g.nodes, const Offset(95, 3), 1),
        1,
      );
      expect(
        hitTestNode(layout.x, layout.y, g.nodes, const Offset(50, 0), 1),
        -1,
      );
    });

    test('le posizioni si salvano e si rileggono', () {
      final dir = Directory.systemTemp.createTempSync('leviathan_graph');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = GraphLayoutStore(File('${dir.path}/g/ws.json'));
      expect(store.read(), isEmpty);
      store.write({'a': const Offset(1.234, -5.0)});
      expect(store.read(), {'a': const Offset(1.2, -5.0)});
    });
  });
}
