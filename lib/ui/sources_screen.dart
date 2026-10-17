import 'package:flutter/material.dart';

import '../model/note.dart';
import '../model/search.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Tutte le fonti (di solito persone) del workspace, con una barra per
/// cercarle. Toccandone una si vedono le note che la citano.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Senza ricerca: dalla fonte con più note; a parità, in ordine alfabetico.
  /// Con ricerca: le più pertinenti (tollera maiuscole, accenti e refusi).
  List<String> _visible(Map<String, int> counts) {
    final query = _query.text.trim();
    if (query.isNotEmpty) {
      return rankSuggestions(query, counts, limit: counts.length);
    }
    return counts.keys.toList()..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : foldText(a).compareTo(foldText(b));
    });
  }

  void _open(String source) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SourceNotesScreen(source: source, notes: widget.notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        final counts = widget.notes.sourceCounts;
        final visible = _visible(counts);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: LeviathanColors.background,
            title: const Text('Fonti'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  key: const Key('sources-search'),
                  controller: _query,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Cerca una fonte',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Svuota',
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _query.clear,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: counts.isEmpty
                    ? const _Empty(
                        'Nessuna fonte ancora: aggiungine una mentre scrivi '
                        'una nota.',
                      )
                    : visible.isEmpty
                    ? const _Empty('Nessuna fonte trovata')
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: visible.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            final n = visible.length;
                            return SectionTitle(
                              n == 1 ? '1 fonte' : '$n fonti',
                            );
                          }
                          final source = visible[i - 1];
                          final count = counts[source]!;
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: LeviathanColors.surface,
                              child: Icon(
                                Icons.person,
                                color: LeviathanColors.muted,
                              ),
                            ),
                            title: Text(source),
                            subtitle: Text(
                              count == 1 ? '1 nota' : '$count note',
                              style: const TextStyle(
                                color: LeviathanColors.muted,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: LeviathanColors.muted,
                            ),
                            onTap: () => _open(source),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Le note che hanno [source] tra le loro fonti, dalla più recente.
class SourceNotesScreen extends StatelessWidget {
  const SourceNotesScreen({
    super.key,
    required this.source,
    required this.notes,
  });

  final String source;
  final NotesController notes;

  void _open(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: note.id, notes: notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        // Con una sola fonte nel filtro basta che la nota la contenga.
        final hits = searchNotes(notes.notes, SearchQuery(sources: [source]));
        return Scaffold(
          appBar: AppBar(
            backgroundColor: LeviathanColors.background,
            title: Row(
              children: [
                const Icon(Icons.person, color: LeviathanColors.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(source, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          body: hits.isEmpty
              ? const _Empty('Nessuna nota con questa fonte')
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: hits.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final n = hits.length;
                      return SectionTitle(n == 1 ? '1 nota' : '$n note');
                    }
                    return NoteResultTile(
                      hit: hits[i - 1],
                      terms: const [],
                      onTap: (note) => _open(context, note),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: LeviathanColors.muted),
        ),
      ),
    );
  }
}
