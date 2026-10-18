import 'package:flutter/material.dart';

import '../model/markdown.dart';
import '../model/note.dart';
import '../model/search.dart';
import '../state/notes_controller.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Tutte le note fissate, task compresi, dalla più recente. Si apre dalla
/// puntina in cima alla home.
///
/// La puntina di ogni riga stacca la nota, che esce dall'elenco; l'avviso in
/// basso permette di rimetterla.
class PinnedScreen extends StatelessWidget {
  const PinnedScreen({super.key, required this.notes});

  final NotesController notes;

  void _open(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: note.id, notes: notes),
      ),
    );
  }

  void _unpin(BuildContext context, Note note) {
    notes.setPinned(note, false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('«${note.displayTitle}» staccata dalla cima'),
          action: SnackBarAction(
            label: 'Annulla',
            // La nota va ripresa aggiornata: nel frattempo può essere
            // cambiata (es. spuntata).
            onPressed: () {
              final current = notes.byId(note.id);
              if (current != null) notes.setPinned(current, true);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        final pinned = notes.notes.where((n) => n.pinned).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Fissate')),
          body: pinned.isEmpty
              ? const _Empty()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
                  itemCount: pinned.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return SectionTitle(
                        pinned.length == 1
                            ? '1 nota fissata'
                            : '${pinned.length} note fissate',
                      );
                    }
                    final note = pinned[i - 1];
                    return NoteResultTile(
                      key: ValueKey(note.id),
                      hit: SearchHit(note, 0, plainText(note.body.trim())),
                      terms: const [],
                      onTap: (n) => _open(context, n),
                      onToggleDone: notes.setDone,
                      onTogglePin: (n, _) => _unpin(context, n),
                      divider: i < pinned.length,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.muted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: LeviathanIconSize.xl,
              color: muted,
            ),
            const SizedBox(height: LeviathanSpacing.lg),
            Text(
              'Nessuna nota fissata.\nTieni premuta una nota nelle recenti, '
              'oppure tocca la puntina in una nota o negli elenchi di Task e '
              'note.',
              textAlign: TextAlign.center,
              style: LeviathanText.body.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
