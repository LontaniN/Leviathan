import 'dart:ui' show Color;

import 'note.dart';
import 'tags.dart';

/// Colore dei nodi senza tag.
const untaggedColor = Color(0xFF8A8B93);

class GraphNode {
  GraphNode(this.note, this.color, this.degree);

  final Note note;
  final Color color;

  /// Quante altre note condividono almeno un tag con questa.
  final int degree;
}

class GraphEdge {
  GraphEdge(this.a, this.b, this.weight);

  /// Indici in [NoteGraph.nodes].
  final int a;
  final int b;

  /// Quanti tag hanno in comune le due note (più tag, più si attraggono).
  final int weight;
}

/// Il grafo delle note: ogni nota è un nodo, due note con un tag in comune
/// sono collegate. Le fonti non contano.
class NoteGraph {
  NoteGraph(this.nodes, this.edges, [this.tagMembers = const {}]);

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  /// Per ogni tag, gli indici in [nodes] delle note che lo portano.
  final Map<String, List<int>> tagMembers;

  /// Oltre questo numero di note un tag non collega tutte le coppie (sarebbero
  /// troppe: 200 note → 19.900 linee) ma ogni nota a pochi compagni.
  static const fullTagLimit = 12;

  /// Compagni per nota nei tag molto usati.
  static const sampledLinks = 4;

  factory NoteGraph.build(List<Note> notes) {
    // Ordine stabile: dalla più vecchia, così i collegamenti campionati non
    // cambiano aggiungendo una nota nuova.
    final ordered = [...notes]
      ..sort((a, b) {
        final byDate = a.created.compareTo(b.created);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    final members = <String, List<int>>{};
    for (var i = 0; i < ordered.length; i++) {
      for (final tag in ordered[i].tags) {
        (members[tag] ??= []).add(i);
      }
    }

    final weights = <int, int>{};
    void link(int a, int b) {
      if (a == b) return;
      final key = a < b ? a * ordered.length + b : b * ordered.length + a;
      weights[key] = (weights[key] ?? 0) + 1;
    }

    for (final entry in members.entries) {
      final group = entry.value;
      if (group.length <= fullTagLimit) {
        for (var i = 0; i < group.length; i++) {
          for (var j = i + 1; j < group.length; j++) {
            link(group[i], group[j]);
          }
        }
      } else {
        // Il vicino nel tempo più alcuni compagni "a caso" ma deterministici:
        // il gruppo resta compatto senza disegnare migliaia di linee.
        for (var i = 0; i < group.length; i++) {
          link(group[i], group[(i + 1) % group.length]);
          for (var k = 1; k < sampledLinks; k++) {
            final h = _hash('${ordered[group[i]].id}|${entry.key}|$k');
            link(group[i], group[h % group.length]);
          }
        }
      }
    }

    final edges = [
      for (final MapEntry(:key, :value) in weights.entries)
        GraphEdge(key ~/ ordered.length, key % ordered.length, value),
    ];

    final nodes = <GraphNode>[];
    for (var i = 0; i < ordered.length; i++) {
      final note = ordered[i];
      final neighbours = <int>{};
      for (final tag in note.tags) {
        neighbours.addAll(members[tag]!);
      }
      neighbours.remove(i);
      nodes.add(
        GraphNode(
          note,
          note.tags.isEmpty ? untaggedColor : Tags.colorOf(note.tags.first),
          neighbours.length,
        ),
      );
    }
    return NoteGraph(nodes, edges, members);
  }

  static int _hash(String s) {
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
