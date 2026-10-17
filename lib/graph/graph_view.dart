import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../model/graph.dart';

/// Raggio di un nodo: cresce con i collegamenti, come nell'immagine di
/// riferimento (i "centri" delle costellazioni sono più grandi).
double nodeRadius(int degree) => math.min(14, 3 + math.sqrt(degree) * 1.1);

/// Posizioni iniziali: quelle salvate se ci sono; le note nuove vicino alle
/// note a cui sono collegate; il resto su una spirale (come d3).
///
/// Restituisce anche quante posizioni erano già note.
({Float64List x, Float64List y, int known}) seedPositions(
  NoteGraph graph,
  Map<String, Offset> saved,
) {
  final n = graph.nodes.length;
  final x = Float64List(n);
  final y = Float64List(n);
  final placed = List<bool>.filled(n, false);
  var known = 0;
  for (var i = 0; i < n; i++) {
    final pos = saved[graph.nodes[i].note.id];
    if (pos != null) {
      x[i] = pos.dx;
      y[i] = pos.dy;
      placed[i] = true;
      known++;
    }
  }
  final neighbours = List.generate(n, (_) => <int>[]);
  for (final e in graph.edges) {
    neighbours[e.a].add(e.b);
    neighbours[e.b].add(e.a);
  }
  const golden = math.pi * (3 - 2.23606797749979); // pi * (3 - sqrt(5))
  for (var i = 0; i < n; i++) {
    if (placed[i]) continue;
    final anchors = neighbours[i].where((j) => placed[j]).toList();
    final jitterAngle = i * golden;
    if (anchors.isNotEmpty) {
      var ax = 0.0, ay = 0.0;
      for (final j in anchors) {
        ax += x[j];
        ay += y[j];
      }
      x[i] = ax / anchors.length + 12 * math.cos(jitterAngle);
      y[i] = ay / anchors.length + 12 * math.sin(jitterAngle);
    } else {
      final r = 10 * math.sqrt(0.5 + i);
      x[i] = r * math.cos(jitterAngle);
      y[i] = r * math.sin(jitterAngle);
    }
    placed[i] = true;
  }
  return (x: x, y: y, known: known);
}

/// Inquadratura: spostamento e zoom tra coordinate del grafo e dello schermo.
class GraphViewport {
  const GraphViewport({this.pan = Offset.zero, this.scale = 1});

  /// Dove finisce l'origine del grafo rispetto al centro dello schermo.
  final Offset pan;
  final double scale;

  static const minScale = 0.08;
  static const maxScale = 6.0;

  Offset toScreen(Offset world, Size size) =>
      size.center(Offset.zero) + pan + world * scale;

  Offset toWorld(Offset screen, Size size) =>
      (screen - size.center(Offset.zero) - pan) / scale;

  /// Zoom di [factor] tenendo fermo sotto il dito il punto [focal].
  GraphViewport zoomAround(
    Offset focal,
    double newScale,
    Size size, {
    required Offset worldAtFocal,
  }) {
    final s = newScale.clamp(minScale, maxScale);
    return GraphViewport(
      scale: s,
      pan: focal - size.center(Offset.zero) - worldAtFocal * s,
    );
  }

  /// Inquadra il rettangolo [bounds] (coordinate del grafo) con un margine.
  static GraphViewport fit(Rect bounds, Size size, {double margin = 48}) {
    final w = math.max(bounds.width, 1.0);
    final h = math.max(bounds.height, 1.0);
    final s = math
        .min((size.width - 2 * margin) / w, (size.height - 2 * margin) / h)
        .clamp(minScale, 2.0);
    return GraphViewport(scale: s, pan: -bounds.center * s);
  }
}

/// Il nodo sotto il punto [world], con un po' di tolleranza per il dito.
int hitTestNode(
  Float64List xs,
  Float64List ys,
  List<GraphNode> nodes,
  Offset world,
  double scale,
) {
  var best = -1;
  var bestD = double.infinity;
  final slop = 14 / scale; // ~14 px sullo schermo, a qualsiasi zoom
  for (var i = 0; i < nodes.length; i++) {
    final dx = xs[i] - world.dx;
    final dy = ys[i] - world.dy;
    final d = math.sqrt(dx * dx + dy * dy);
    final reach = nodeRadius(nodes[i].degree) + slop;
    if (d <= reach && d < bestD) {
      best = i;
      bestD = d;
    }
  }
  return best;
}

Rect boundsOf(Float64List xs, Float64List ys, [Iterable<int>? only]) {
  final indices = only ?? List.generate(xs.length, (i) => i);
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final i in indices) {
    minX = math.min(minX, xs[i]);
    minY = math.min(minY, ys[i]);
    maxX = math.max(maxX, xs[i]);
    maxY = math.max(maxY, ys[i]);
  }
  if (minX == double.infinity) return Rect.zero;
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
