import 'package:flutter/material.dart';

import '../model/markdown.dart';
import '../model/note.dart';
import '../model/search.dart';
import '../state/notes_controller.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Le note scritte in un periodo del calendario (un giorno o un mese),
/// dalla prima all'ultima. Con una [query] solo quelle che la contengono,
/// con le parole evidenziate.
class PeriodNotesScreen extends StatelessWidget {
  const PeriodNotesScreen({
    super.key,
    required this.title,
    required this.from,
    required this.to,
    required this.notes,
    this.demoNotes,
    this.query = '',
  });

  final String title;

  /// Inizio del periodo, incluso.
  final DateTime from;

  /// Fine del periodo, esclusa.
  final DateTime to;
  final NotesController notes;

  /// Se c'è, si mostrano queste note finte al posto di quelle vere; si
  /// aprono in sola lettura e non si spuntano.
  final List<Note>? demoNotes;

  /// La ricerca fatta nel calendario; vuota per vedere tutto il periodo.
  final String query;

  void _open(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(
          noteId: note.id,
          notes: notes,
          // Le note di prova non stanno nel workspace: si leggono e basta.
          preview: demoNotes == null ? null : note,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demo = demoNotes;
    final singleDay = to.difference(from).inHours <= 25;
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        final search = SearchQuery(text: query);
        final inPeriod = (demo ?? notes.notes)
            .where((n) => !n.created.isBefore(from) && n.created.isBefore(to))
            .toList();
        final hits = search.isEmpty
            ? [
                for (final n in inPeriod)
                  SearchHit(n, 0, plainText(n.body.trim())),
              ]
            : searchNotes(inPeriod, search);
        hits.sort((a, b) => a.note.created.compareTo(b.note.created));
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.palette.background,
            title: Text(title, overflow: TextOverflow.ellipsis),
          ),
          body: hits.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(LeviathanSpacing.xxl),
                    child: Text(
                      search.isEmpty
                          ? 'Nessuna nota in questo periodo.'
                          : 'Nessuna nota di questo periodo contiene '
                                '"$query".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.palette.muted),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
                  itemCount: hits.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final n = hits.length;
                      return SectionTitle(
                        '${n == 1 ? '1 nota' : '$n note'}'
                        '${demo != null ? ' · dati di prova' : ''}',
                      );
                    }
                    final hit = hits[i - 1];
                    final note = hit.note;
                    return NoteResultTile(
                      hit: hit,
                      terms: search.terms,
                      onTap: (n) => _open(context, n),
                      onToggleDone: demo != null ? null : notes.setDone,
                      // In un giorno solo la data è sempre la stessa: meglio
                      // l'ora.
                      dateLabel: singleDay ? _formatTime(note.created) : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

String _formatTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
