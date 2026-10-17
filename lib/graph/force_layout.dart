import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Un collegamento per la simulazione: indici dei nodi e peso.
typedef Link = ({int a, int b, int weight});

/// Simulazione fisica del grafo, sul modello di d3-force (lo stesso usato da
/// Obsidian): i nodi si respingono, i collegamenti fanno da molle e una
/// leggera gravità tiene tutto attorno al centro.
///
/// La repulsione usa Barnes-Hut: i gruppi di nodi lontani contano come un
/// unico nodo pesante, così il costo resta O(n log n) anche con migliaia di
/// note. La simulazione "si raffredda" ([alpha]) e si ferma da sola quando il
/// grafo è assestato, per non consumare batteria.
class ForceLayout extends ChangeNotifier {
  ForceLayout(this.count, List<Link> links, {Float64List? x, Float64List? y})
    : x = x ?? Float64List(count),
      y = y ?? Float64List(count),
      vx = Float64List(count),
      vy = Float64List(count),
      _links = links {
    _degree = Int32List(count);
    for (final l in links) {
      _degree[l.a]++;
      _degree[l.b]++;
    }
  }

  final int count;
  final Float64List x;
  final Float64List y;
  final Float64List vx;
  final Float64List vy;
  final List<Link> _links;
  late final Int32List _degree;

  // Parametri (unità: pixel logici a zoom 1).
  static const repulsion = -45.0;
  static const linkDistance = 32.0;
  static const gravity = 0.06;
  static const theta = 0.9;
  static const velocityDecay = 0.6;
  static const alphaMin = 0.002;
  static final alphaDecay = 1 - math.pow(alphaMin, 1 / 300).toDouble();

  double alpha = 1;

  /// Nodo tenuto fermo dal dito (trascinamento), o -1.
  int pinned = -1;

  bool get isRunning => alpha >= alphaMin || pinned >= 0;

  /// Rimette in moto la simulazione (es. dopo un trascinamento).
  void reheat([double to = 0.3]) {
    if (alpha < to) alpha = to;
  }

  /// Un passo di simulazione. Restituisce false se è già ferma.
  bool tick() {
    if (!isRunning) return false;
    alpha += (0 - alpha) * alphaDecay;
    _applyLinks();
    _applyRepulsion();
    for (var i = 0; i < count; i++) {
      vx[i] += -x[i] * gravity * alpha;
      vy[i] += -y[i] * gravity * alpha;
      if (i == pinned) {
        vx[i] = 0;
        vy[i] = 0;
        continue;
      }
      vx[i] *= velocityDecay;
      vy[i] *= velocityDecay;
      x[i] += vx[i];
      y[i] += vy[i];
    }
    notifyListeners();
    return true;
  }

  void _applyLinks() {
    for (final l in _links) {
      var dx = x[l.b] + vx[l.b] - x[l.a] - vx[l.a];
      var dy = y[l.b] + vy[l.b] - y[l.a] - vy[l.a];
      if (dx == 0 && dy == 0) {
        dx = _jitter();
        dy = _jitter();
      }
      final dist = math.sqrt(dx * dx + dy * dy);
      // Come d3: la molla è più debole sui nodi molto collegati, altrimenti
      // i grandi gruppi collasserebbero in un punto.
      final strength = math.min(
        1.0,
        l.weight / math.min(_degree[l.a], _degree[l.b]),
      );
      final f = (dist - linkDistance) / dist * alpha * strength;
      final fx = dx * f;
      final fy = dy * f;
      final bias = _degree[l.a] / (_degree[l.a] + _degree[l.b]);
      vx[l.b] -= fx * bias;
      vy[l.b] -= fy * bias;
      vx[l.a] += fx * (1 - bias);
      vy[l.a] += fy * (1 - bias);
    }
  }

  void _applyRepulsion() {
    if (count < 2) return;
    final root = _Quad.build(x, y);
    for (var i = 0; i < count; i++) {
      _repel(root, i);
    }
  }

  void _repel(_Quad quad, int i) {
    if (quad.count == 0) return;
    if (quad.isLeaf && quad.index == i && quad.count == 1) return;
    var dx = quad.cx - x[i];
    var dy = quad.cy - y[i];
    var d2 = dx * dx + dy * dy;
    final farEnough = quad.size * quad.size / (theta * theta) < d2;
    if (quad.isLeaf || farEnough) {
      var n = quad.count;
      // Un nodo non respinge se stesso dentro un gruppo che lo contiene.
      if (quad.isLeaf && quad.containsIndex(i)) n -= 1;
      if (n <= 0) return;
      if (dx == 0 && dy == 0) {
        dx = _jitter();
        dy = _jitter();
        d2 = dx * dx + dy * dy;
      }
      if (d2 < 1) d2 = math.sqrt(d2);
      final w = repulsion * n * alpha / d2;
      vx[i] += dx * w;
      vy[i] += dy * w;
      return;
    }
    for (final child in quad.children!) {
      if (child != null) _repel(child, i);
    }
  }

  int _seed = 1;
  double _jitter() {
    _seed = (_seed * 16807) % 2147483647;
    return (_seed / 2147483647 - 0.5) * 1e-3;
  }

  /// Fa girare la simulazione fino a fermarla (per i test e il primo avvio).
  void runToEnd({int maxTicks = 600}) {
    for (var t = 0; t < maxTicks && tick(); t++) {}
  }
}

/// Quadtree di Barnes-Hut: ogni cella sa quanti nodi contiene e il loro
/// baricentro.
class _Quad {
  _Quad(this.x0, this.y0, this.size);

  final double x0;
  final double y0;
  final double size;
  double cx = 0;
  double cy = 0;
  int count = 0;

  /// Nelle foglie: l'indice del nodo (o dei nodi sovrapposti).
  int index = -1;
  List<int>? _extra;
  List<_Quad?>? children;

  bool get isLeaf => children == null;

  bool containsIndex(int i) => index == i || (_extra?.contains(i) ?? false);

  static _Quad build(Float64List xs, Float64List ys) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i < xs.length; i++) {
      minX = math.min(minX, xs[i]);
      minY = math.min(minY, ys[i]);
      maxX = math.max(maxX, xs[i]);
      maxY = math.max(maxY, ys[i]);
    }
    final size = math.max(maxX - minX, maxY - minY) + 1;
    final root = _Quad(minX, minY, size);
    for (var i = 0; i < xs.length; i++) {
      root._insert(i, xs[i], ys[i], xs, ys, 0);
    }
    return root;
  }

  void _insert(
    int i,
    double px,
    double py,
    Float64List xs,
    Float64List ys,
    int depth,
  ) {
    cx = (cx * count + px) / (count + 1);
    cy = (cy * count + py) / (count + 1);
    count++;
    if (count == 1) {
      index = i;
      return;
    }
    if (isLeaf) {
      // Nodi (quasi) sovrapposti: restano nella stessa foglia.
      if (depth > 24 || size < 1e-3) {
        (_extra ??= []).add(i);
        return;
      }
      children = List<_Quad?>.filled(4, null);
      final existing = index;
      index = -1;
      _child(
        xs[existing],
        ys[existing],
      )._insert(existing, xs[existing], ys[existing], xs, ys, depth + 1);
    }
    _child(px, py)._insert(i, px, py, xs, ys, depth + 1);
  }

  _Quad _child(double px, double py) {
    final half = size / 2;
    final right = px >= x0 + half;
    final bottom = py >= y0 + half;
    final slot = (bottom ? 2 : 0) + (right ? 1 : 0);
    return children![slot] ??= _Quad(
      right ? x0 + half : x0,
      bottom ? y0 + half : y0,
      half,
    );
  }
}
