import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/draft_store.dart';
import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import '../model/note_groups.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'lists_screen.dart';
import 'note_actions.dart';
import 'note_body.dart';
import 'note_editor.dart';
import 'note_picker_screen.dart';
import 'tag_color_sheet.dart';
import 'task_check.dart';
import 'chip_input.dart';
import 'theme.dart';

/// Apre la modifica di [note]; con [resume] riprende quella rimasta a metà.
void openNoteEditor(
  BuildContext context,
  NotesController notes,
  Note note, {
  EditDraft? resume,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: NoteEditor.editRouteName),
      builder: (_) => _EditNotePage(note: note, notes: notes, resume: resume),
    ),
  );
}

/// Lettura di una nota a schermo intero, con modifica ed eliminazione.
/// Un task si spunta da qui; la puntina la fissa in cima alle recenti.
///
/// Sopra il titolo il primo tag fa da occhiello, nel suo colore. Aprendola
/// la nota entra fra quelle aperte di recente (vedi la ricerca).
class NoteScreen extends StatefulWidget {
  const NoteScreen({
    super.key,
    required this.noteId,
    required this.notes,
    this.preview,
  });

  final String noteId;
  final NotesController notes;

  /// Se c'è, si mostra questa nota in sola lettura invece di cercare
  /// [noteId] nel workspace (es. le note di prova del calendario).
  final Note? preview;

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  String get noteId => widget.noteId;
  NotesController get notes => widget.notes;
  Note? get preview => widget.preview;

  @override
  void initState() {
    super.initState();
    if (preview == null) notes.markOpened(noteId);
  }

  /// Toccando un tag o una fonte si apre la sua schermata, sui task se la
  /// nota è un task, altrimenti sulle note.
  void _openGroup(
    BuildContext context,
    Note note,
    NoteGrouping grouping,
    String name,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupScreen(
          notes: notes,
          name: name,
          grouping: grouping,
          initialView: note.kind,
        ),
      ),
    );
  }

  void _delete(BuildContext context, Note note) {
    // Il messenger è quello dell'app: l'avviso resta anche chiusa la nota.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    deleteWithUndo(messenger, context.l10n, notes, note);
  }

  Future<void> _copy(BuildContext context, Note note) async {
    final title = note.title.trim();
    await Clipboard.setData(
      ClipboardData(
        text: title.isEmpty ? note.body : '# $title\n\n${note.body}',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.textCopied)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        final note = preview ?? notes.byId(noteId);
        if (note == null) return const Scaffold();
        final readOnly = preview != null;
        final palette = context.palette;
        final l = context.l10n;
        final meta = [
          formatDate(l, note.created),
          if (note.updated.isAfter(note.created))
            l.editedOn(formatDate(l, note.updated)),
          l.wordCount(wordCount(note.body)),
        ].join(' · ');
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (!readOnly) ...[
                IconButton(
                  key: const Key('pin-button'),
                  tooltip: note.pinned ? l.unpinFromTop : l.pinToTop,
                  isSelected: note.pinned,
                  icon: const Icon(Icons.push_pin_outlined),
                  selectedIcon: Icon(Icons.push_pin, color: palette.accent),
                  onPressed: () => notes.setPinned(note, !note.pinned),
                ),
                // Acceso sui task: lo si ritocca per tornare a nota.
                IconButton(
                  key: const Key('task-toggle'),
                  tooltip: note.isTask ? l.convertToNote : l.convertToTask,
                  isSelected: note.isTask,
                  icon: const Icon(Icons.add_task),
                  selectedIcon: Icon(Icons.task_alt, color: palette.accent),
                  onPressed: () =>
                      notes.update(note.copyWith(isTask: !note.isTask)),
                ),
                IconButton(
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => openNoteEditor(context, notes, note),
                ),
                PopupMenuButton<VoidCallback>(
                  key: const Key('note-menu'),
                  tooltip: l.more,
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: () => _copy(context, note),
                      child: ListTile(
                        leading: const Icon(Icons.copy_outlined),
                        title: Text(l.copyText),
                      ),
                    ),
                    PopupMenuItem(
                      key: const Key('delete-note'),
                      value: () => _delete(context, note),
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: Text(l.moveToTrash),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                LeviathanSpacing.xl,
                LeviathanSpacing.xs,
                LeviathanSpacing.xl,
                LeviathanSpacing.xxxl,
              ),
              children: [
                if (note.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LeviathanSpacing.sm),
                    child: Text(
                      note.tags.first.toUpperCase(),
                      style: LeviathanText.caption.copyWith(
                        color: Tags.colorOf(note.tags.first),
                      ),
                    ),
                  ),
                Text(
                  note.displayTitle(l.untitled),
                  style: taskTitleStyle(context, note, LeviathanText.heading),
                ),
                const SizedBox(height: LeviathanSpacing.sm),
                Text(
                  meta,
                  style: LeviathanText.meta.copyWith(color: palette.muted),
                ),
                if (note.isTask && note.due != null) ...[
                  const SizedBox(height: LeviathanSpacing.xs),
                  _DueLine(note: note),
                ],
                if (note.isTask) ...[
                  const SizedBox(height: LeviathanSpacing.md),
                  _TaskStatus(
                    note: note,
                    onChanged: readOnly
                        ? null
                        : (done) => notes.setDone(note, done),
                  ),
                ],
                if (note.tags.isNotEmpty || note.sources.isNotEmpty) ...[
                  const SizedBox(height: LeviathanSpacing.lg),
                  Wrap(
                    spacing: LeviathanSpacing.sm,
                    runSpacing: LeviathanSpacing.sm,
                    children: [
                      for (final tag in note.tags)
                        GestureDetector(
                          onTap: readOnly
                              ? null
                              : () => _openGroup(
                                  context,
                                  note,
                                  NoteGrouping.tag,
                                  tag,
                                ),
                          child: TagChip(
                            tag,
                            onLongPress: readOnly
                                ? null
                                : () => showTagColorSheet(context, notes, tag),
                          ),
                        ),
                      for (final source in note.sources)
                        GestureDetector(
                          onTap: readOnly
                              ? null
                              : () => _openGroup(
                                  context,
                                  note,
                                  NoteGrouping.source,
                                  source,
                                ),
                          child: SourceChip(
                            source,
                            onLongPress: readOnly
                                ? null
                                : () => showSourceSheet(context, notes, source),
                          ),
                        ),
                    ],
                  ),
                ],
                const Divider(height: LeviathanSpacing.xxxl),
                if (note.body.trim().isEmpty)
                  Text(
                    l.noText,
                    style: LeviathanText.reading.copyWith(color: palette.muted),
                  )
                else
                  NoteBody(
                    note.body,
                    notes: notes.notes,
                    onOpenNote: readOnly
                        ? null
                        : (linked) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  NoteScreen(noteId: linked.id, notes: notes),
                            ),
                          ),
                    onChanged: readOnly
                        ? null
                        : (body) => notes.update(note.copyWith(body: body)),
                  ),
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

  /// Null in sola lettura: la casella non si tocca.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final doneAt = note.doneAt;
    final label = !note.done
        ? l.taskToDo
        : doneAt == null
        ? l.taskDone
        : l.taskDoneOn(formatDate(l, doneAt));
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        key: const Key('task-status'),
        onTap: onChanged == null ? null : () => onChanged!(!note.done),
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
  const _EditNotePage({required this.note, required this.notes, this.resume});

  final Note note;
  final NotesController notes;
  final EditDraft? resume;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editNote)),
      // Cambiando il colore di un tag i chip si ridisegnano.
      body: ListenableBuilder(
        listenable: notes,
        builder: (context, _) => NoteEditor(
          initial: note,
          editDraft: notes.editDraft,
          resume: resume,
          tagCounts: notes.tagCounts,
          sourceCounts: notes.sourceCounts,
          saveLabel: context.l10n.saveChanges,
          onTagLongPress: (tag) => showTagColorSheet(context, notes, tag),
          onSourceLongPress: (source) =>
              showSourceSheet(context, notes, source),
          onPickNote: () => pickNote(context, notes, exclude: note.id),
          onSave: (draft) {
            notes.update(
              note.copyWith(
                title: draft.title,
                body: draft.body,
                tags: draft.tags,
                sources: draft.sources,
                isTask: draft.isTask,
                knowledge: draft.knowledge,
                due: draft.due,
                clearDue: draft.due == null,
                created: draft.date == null
                    ? null
                    : onDay(draft.date!, note.created),
              ),
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

/// La scadenza di un task sotto il titolo; nel colore d'accento se è
/// passata e il task è ancora da fare.
class _DueLine extends StatelessWidget {
  const _DueLine({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final due = note.due!;
    final now = DateTime.now();
    final late =
        note.isOpenTask && due.isBefore(DateTime(now.year, now.month, now.day));
    final color = late ? palette.accent : palette.muted;
    return Row(
      key: const Key('note-due'),
      children: [
        Icon(Icons.event_outlined, size: LeviathanIconSize.sm, color: color),
        const SizedBox(width: LeviathanSpacing.xs),
        Text(
          l.dueOn(formatDate(l, due)),
          style: LeviathanText.meta.copyWith(
            color: color,
            fontWeight: late ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}
