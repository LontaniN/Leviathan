import 'package:flutter/material.dart';

import '../model/note.dart';
import '../model/tags.dart';
import 'theme.dart';

/// Il colore del primo tag (lo stesso del nodo nel grafo); attenuato se la
/// nota non ha tag.
Color noteColor(BuildContext context, Note note) => note.tags.isEmpty
    ? context.palette.muted.withValues(alpha: LeviathanOpacity.untagged)
    : Tags.colorOf(note.tags.first);

/// La barretta del primo tag accanto a una voce.
class TagBar extends StatelessWidget {
  const TagBar({super.key, required this.note, required this.height});

  final Note note;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: LeviathanSizes.tagBar,
      height: height,
      decoration: BoxDecoration(
        color: noteColor(context, note),
        borderRadius: BorderRadius.circular(LeviathanRadii.sm),
      ),
    );
  }
}
