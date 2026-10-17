import 'package:flutter/material.dart';

import '../model/note.dart';
import 'theme.dart';

/// La casella di un task: toccandola si spunta o si toglie la spunta.
///
/// Senza [onChanged] è solo un'indicazione e non risponde ai tocchi.
class TaskCheck extends StatelessWidget {
  const TaskCheck({super.key, required this.note, this.onChanged});

  final Note note;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final done = note.done;
    final icon = Icon(
      done ? Icons.check_box : Icons.check_box_outline_blank,
      size: LeviathanIconSize.lg,
      color: done ? context.palette.muted : context.palette.accent,
    );
    if (onChanged == null) return icon;
    // Il margine attorno all'icona allarga la zona che risponde al tocco.
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Segna da fare' : 'Segna come fatto',
      child: InkResponse(
        key: Key('task-check-${note.id}'),
        onTap: () => onChanged!(!done),
        radius: LeviathanIconSize.lg,
        child: Padding(
          padding: const EdgeInsets.all(LeviathanSpacing.xs),
          child: icon,
        ),
      ),
    );
  }
}

/// Lo stile del titolo di una nota: i task eseguiti sono barrati e attenuati.
TextStyle taskTitleStyle(BuildContext context, Note note, TextStyle base) {
  if (!(note.isTask && note.done)) return base;
  final muted = context.palette.muted;
  return base.copyWith(
    color: muted,
    decoration: TextDecoration.lineThrough,
    decorationColor: muted,
  );
}
