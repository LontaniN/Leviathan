import 'package:flutter/material.dart';

import '../model/note.dart';
import '../state/notes_controller.dart';
import 'theme.dart';

/// Sposta [note] nel cestino e offre di annullare dall'avviso in basso.
///
/// Il messenger va preso prima di chiudere la schermata della nota: chi
/// chiama lo passa già pronto.
void deleteWithUndo(
  ScaffoldMessengerState messenger,
  NotesController notes,
  Note note,
) {
  final deleted = notes.delete(note);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('«${note.displayTitle}» spostata nel cestino'),
        action: deleted == null
            ? null
            : SnackBarAction(
                label: 'Annulla',
                onPressed: () => notes.restore(deleted),
              ),
      ),
    );
}

/// Le azioni rapide su una nota, aperte tenendo premuta la sua riga.
Future<void> showNoteActions(
  BuildContext context,
  NotesController notes,
  Note note,
) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void run(VoidCallback action) {
        Navigator.pop(sheetContext);
        action();
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LeviathanSpacing.xl,
                0,
                LeviathanSpacing.xl,
                LeviathanSpacing.sm,
              ),
              child: Text(
                note.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LeviathanText.title,
              ),
            ),
            ListTile(
              key: const Key('action-pin'),
              leading: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(note.pinned ? 'Stacca dalla cima' : 'Fissa in cima'),
              onTap: () => run(() => notes.setPinned(note, !note.pinned)),
            ),
            if (note.isTask)
              ListTile(
                leading: Icon(
                  note.done ? Icons.check_box_outline_blank : Icons.check_box,
                ),
                title: Text(note.done ? 'Segna da fare' : 'Segna come fatto'),
                onTap: () => run(() => notes.setDone(note, !note.done)),
              ),
            ListTile(
              key: const Key('action-delete'),
              leading: const Icon(Icons.delete_outline),
              title: const Text('Sposta nel cestino'),
              onTap: () => run(() => deleteWithUndo(messenger, notes, note)),
            ),
          ],
        ),
      );
    },
  );
}
