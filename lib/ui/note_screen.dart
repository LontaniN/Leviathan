import 'package:flutter/material.dart';

import '../model/note.dart';
import '../state/notes_controller.dart';
import 'home_screen.dart' show formatDate;
import 'note_editor.dart';
import 'search_screen.dart';
import 'chip_input.dart';
import 'theme.dart';

/// Lettura di una nota a schermo intero, con modifica ed eliminazione.
class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key, required this.noteId, required this.notes});

  final String noteId;
  final NotesController notes;

  /// Toccando un tag o una fonte si cercano le note che li condividono.
  void _search(
    BuildContext context, {
    List<String> tags = const [],
    List<String> sources = const [],
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          notes: notes,
          initialTags: tags,
          initialSources: sources,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare la nota?'),
        content: const Text(
          'La nota viene spostata nel cestino del workspace '
          '(cartella .leviathan/trash), non cancellata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.pop(context);
    notes.delete(note);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        final note = notes.byId(noteId);
        if (note == null) return const Scaffold();
        final text = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: LeviathanColors.background,
            actions: [
              IconButton(
                tooltip: 'Modifica',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _EditNotePage(note: note, notes: notes),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Elimina',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, note),
              ),
            ],
          ),
          body: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                Text(note.displayTitle, style: text.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  note.updated.isAfter(note.created)
                      ? '${formatDate(note.created)} · modificata '
                            '${formatDate(note.updated)}'
                      : formatDate(note.created),
                  style: text.bodySmall?.copyWith(color: LeviathanColors.muted),
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in note.tags)
                        GestureDetector(
                          onTap: () => _search(context, tags: [tag]),
                          child: TagChip(tag),
                        ),
                    ],
                  ),
                ],
                if (note.sources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final source in note.sources)
                        GestureDetector(
                          onTap: () => _search(context, sources: [source]),
                          child: SourceChip(source),
                        ),
                    ],
                  ),
                ],
                const Divider(height: 32),
                Text(note.body, style: text.bodyLarge?.copyWith(height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditNotePage extends StatelessWidget {
  const _EditNotePage({required this.note, required this.notes});

  final Note note;
  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica nota'),
        backgroundColor: LeviathanColors.background,
      ),
      body: NoteEditor(
        initial: note,
        tagCounts: notes.tagCounts,
        sourceCounts: notes.sourceCounts,
        saveLabel: 'Salva modifiche',
        onSave: (draft) {
          notes.update(
            note.copyWith(
              title: draft.title,
              body: draft.body,
              tags: draft.tags,
              sources: draft.sources,
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}
