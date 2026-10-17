import 'package:flutter/material.dart';

import '../model/note.dart';
import '../state/notes_controller.dart';
import 'home_screen.dart' show formatDate;
import 'note_editor.dart';
import 'search_screen.dart';
import 'task_check.dart';
import 'chip_input.dart';
import 'theme.dart';

/// Lettura di una nota a schermo intero, con modifica ed eliminazione.
/// Un task si spunta da qui.
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
            backgroundColor: context.palette.background,
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
              padding: const EdgeInsets.fromLTRB(
                LeviathanSpacing.xl,
                LeviathanSpacing.xs,
                LeviathanSpacing.xl,
                LeviathanSpacing.xxl,
              ),
              children: [
                Text(
                  note.displayTitle,
                  style: taskTitleStyle(context, note, text.headlineSmall!),
                ),
                const SizedBox(height: LeviathanSpacing.sm),
                Text(
                  note.updated.isAfter(note.created)
                      ? '${formatDate(note.created)} · modificata '
                            '${formatDate(note.updated)}'
                      : formatDate(note.created),
                  style: text.bodySmall?.copyWith(color: context.palette.muted),
                ),
                if (note.isTask) ...[
                  const SizedBox(height: LeviathanSpacing.md),
                  _TaskStatus(
                    note: note,
                    onChanged: (done) => notes.setDone(note, done),
                  ),
                ],
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: LeviathanSpacing.md),
                  Wrap(
                    spacing: LeviathanSpacing.sm,
                    runSpacing: LeviathanSpacing.sm,
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
                  const SizedBox(height: LeviathanSpacing.sm),
                  Wrap(
                    spacing: LeviathanSpacing.sm,
                    runSpacing: LeviathanSpacing.sm,
                    children: [
                      for (final source in note.sources)
                        GestureDetector(
                          onTap: () => _search(context, sources: [source]),
                          child: SourceChip(source),
                        ),
                    ],
                  ),
                ],
                const Divider(height: LeviathanSpacing.xxl),
                Text(note.body, style: text.bodyLarge?.copyWith(height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La casella del task con lo stato a parole: "Da fare" o "Fatto il …".
class _TaskStatus extends StatelessWidget {
  const _TaskStatus({required this.note, required this.onChanged});

  final Note note;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final doneAt = note.doneAt;
    final label = !note.done
        ? 'Da fare'
        : doneAt == null
        ? 'Fatto'
        : 'Fatto il ${formatDate(doneAt)}';
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        key: const Key('task-status'),
        onTap: () => onChanged(!note.done),
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LeviathanSpacing.sm,
            vertical: LeviathanSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TaskCheck(note: note),
              const SizedBox(width: LeviathanSpacing.sm),
              Text(
                label,
                style: LeviathanText.title.copyWith(
                  color: note.done
                      ? context.palette.muted
                      : context.palette.accent,
                ),
              ),
            ],
          ),
        ),
      ),
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
        backgroundColor: context.palette.background,
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
              isTask: draft.isTask,
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}
