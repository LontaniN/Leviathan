import 'package:flutter/material.dart';

import '../model/markdown.dart';
import '../model/note.dart';
import '../model/tags.dart';
import '../state/app_state.dart';
import '../state/notes_controller.dart';
import '../state/settings.dart';
import 'graph_screen.dart';
import 'note_editor.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'sources_screen.dart';
import 'task_check.dart';
import 'tasks_screen.dart';
import 'chip_input.dart';
import 'theme.dart';
import 'workspace_name_form.dart';

/// Schermata principale di un workspace: a sinistra le ultime note, a destra
/// l'editor per scriverne una nuova con tag e fonti.
///
/// La freccia in cima alla lista la espande a tutta larghezza, con anteprima,
/// tag e data di ogni nota.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state, required this.settings});

  final AppState state;
  final Settings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NotesController _notes = NotesController(
    widget.state.notesOf(widget.state.currentWorkspace!),
  );
  bool _listExpanded = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _openNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: note.id, notes: _notes),
      ),
    );
  }

  void _openGraph() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GraphScreen(
          notes: _notes,
          store: widget.state.graphLayoutOf(widget.state.currentWorkspace!),
        ),
      ),
    );
  }

  void _openSources() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SourcesScreen(notes: _notes)),
    );
  }

  void _openTasks() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TasksScreen(notes: _notes)));
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SearchScreen(notes: _notes)),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _notes,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LeviathanSpacing.sm,
                  LeviathanSpacing.xs,
                  LeviathanSpacing.sm,
                  0,
                ),
                child: Row(
                  children: [
                    // Tutto lo spazio libero va al nome, che va a capo solo
                    // se davvero non ci sta.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _WorkspaceButton(state: widget.state),
                      ),
                    ),
                    IconButton(
                      key: const Key('graph-button'),
                      tooltip: 'Grafo',
                      icon: const Icon(Icons.hub_outlined),
                      onPressed: _openGraph,
                    ),
                    IconButton(
                      key: const Key('sources-button'),
                      tooltip: 'Fonti',
                      icon: const Icon(Icons.person),
                      onPressed: _openSources,
                    ),
                    IconButton(
                      key: const Key('tasks-button'),
                      tooltip: 'Task',
                      icon: const Icon(Icons.checklist),
                      onPressed: _openTasks,
                    ),
                    IconButton(
                      key: const Key('search-button'),
                      tooltip: 'Cerca',
                      icon: const Icon(Icons.search),
                      onPressed: _openSearch,
                    ),
                    IconButton(
                      key: const Key('settings-button'),
                      tooltip: 'Impostazioni',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final collapsedWidth = (constraints.maxWidth * 0.3).clamp(
                      104.0,
                      220.0,
                    );
                    final listWidth = _listExpanded
                        ? constraints.maxWidth
                        : collapsedWidth;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: listWidth,
                          // Durante l'animazione la lista è già impaginata
                          // alla larghezza finale e viene solo svelata.
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: listWidth,
                              maxWidth: listWidth,
                              child: _NoteList(
                                notes: _notes.notes,
                                expanded: _listExpanded,
                                onToggle: () => setState(
                                  () => _listExpanded = !_listExpanded,
                                ),
                                onOpen: _openNote,
                                onToggleDone: _notes.setDone,
                              ),
                            ),
                          ),
                        ),
                        if (!_listExpanded)
                          Expanded(
                            child: NoteEditor(
                              tagCounts: _notes.tagCounts,
                              sourceCounts: _notes.sourceCounts,
                              onSave: (draft) {
                                _notes.create(
                                  title: draft.title,
                                  body: draft.body,
                                  tags: draft.tags,
                                  sources: draft.sources,
                                  isTask: draft.isTask,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      draft.isTask
                                          ? 'Task salvato'
                                          : 'Nota salvata',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cronologia delle note, dalla più recente.
class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.notes,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    required this.onToggleDone,
  });

  final List<Note> notes;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Note> onOpen;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('list-toggle'),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LeviathanSpacing.md,
              LeviathanSpacing.md,
              LeviathanSpacing.sm,
              LeviathanSpacing.md,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: LeviathanIconSize.md,
                    color: context.palette.accent,
                  ),
                ),
                const SizedBox(width: LeviathanSpacing.xs),
                Expanded(
                  child: Text(
                    expanded ? 'Tutte le note (${notes.length})' : 'Recenti',
                    overflow: TextOverflow.ellipsis,
                    style: LeviathanText.body.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(LeviathanSpacing.md),
                  child: Text(
                    'Nessuna nota',
                    style: TextStyle(color: context.palette.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
                  itemCount: notes.length,
                  itemBuilder: (context, i) => expanded
                      ? _ExpandedTile(
                          note: notes[i],
                          onTap: onOpen,
                          onToggleDone: onToggleDone,
                        )
                      : _CompactTile(
                          note: notes[i],
                          onTap: onOpen,
                          onToggleDone: onToggleDone,
                        ),
                ),
        ),
      ],
    );
  }
}

/// Barra colorata del primo tag (lo stesso colore del nodo nel grafo).
Color _noteColor(BuildContext context, Note note) => note.tags.isEmpty
    ? context.palette.muted.withValues(alpha: 0.4)
    : Tags.colorOf(note.tags.first);

class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.note,
    required this.onTap,
    required this.onToggleDone,
  });

  final Note note;
  final ValueChanged<Note> onTap;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(note),
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(right: LeviathanSpacing.sm),
              decoration: BoxDecoration(
                color: _noteColor(context, note),
                borderRadius: BorderRadius.circular(LeviathanRadii.sm),
              ),
            ),
            if (note.isTask)
              Padding(
                padding: const EdgeInsets.only(right: LeviathanSpacing.xs),
                child: TaskCheck(
                  note: note,
                  onChanged: (done) => onToggleDone(note, done),
                ),
              ),
            Expanded(
              child: Text(
                note.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: taskTitleStyle(context, note, LeviathanText.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedTile extends StatelessWidget {
  const _ExpandedTile({
    required this.note,
    required this.onTap,
    required this.onToggleDone,
  });

  final Note note;
  final ValueChanged<Note> onTap;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    final preview = plainText(note.body).trim().replaceAll(RegExp(r'\s+'), ' ');
    return InkWell(
      onTap: () => onTap(note),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LeviathanSpacing.md,
          LeviathanSpacing.md,
          LeviathanSpacing.lg,
          LeviathanSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 44,
              margin: const EdgeInsets.only(
                right: LeviathanSpacing.md,
                top: LeviathanSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: _noteColor(context, note),
                borderRadius: BorderRadius.circular(LeviathanRadii.sm),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.isTask)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: LeviathanSpacing.xs,
                          ),
                          child: TaskCheck(
                            note: note,
                            onChanged: (done) => onToggleDone(note, done),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          note.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: taskTitleStyle(
                            context,
                            note,
                            LeviathanText.title,
                          ),
                        ),
                      ),
                      Text(
                        formatDate(note.created),
                        style: LeviathanText.meta.copyWith(
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                  if (preview.isNotEmpty && note.title.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: LeviathanSpacing.xxs),
                      child: Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LeviathanText.body.copyWith(
                          color: context.palette.muted,
                        ),
                      ),
                    ),
                  if (note.tags.isNotEmpty || note.sources.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: LeviathanSpacing.sm),
                      child: Wrap(
                        spacing: LeviathanSpacing.xs,
                        runSpacing: LeviathanSpacing.xs,
                        children: [
                          for (final tag in note.tags)
                            TagChip(tag, dense: true),
                          for (final source in note.sources)
                            SourceChip(source, dense: true),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

/// Il nome del workspace in alto, in piccolo: toccandolo si cambia workspace.
class _WorkspaceButton extends StatelessWidget {
  const _WorkspaceButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('workspace-button'),
      onPressed: () => showWorkspaceSwitcher(context, state),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.expand_more, size: LeviathanIconSize.md),
      label: Text(state.currentWorkspace ?? '', style: LeviathanText.title),
      style: TextButton.styleFrom(foregroundColor: context.palette.accent),
    );
  }
}

Future<void> showWorkspaceSwitcher(BuildContext context, AppState state) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
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
                'Workspace',
                style: TextStyle(color: context.palette.muted),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final name in state.workspaces)
                    ListTile(
                      title: Text(name),
                      trailing: name == state.currentWorkspace
                          ? Icon(Icons.check, color: context.palette.accent)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        state.switchTo(name);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nuovo workspace'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showNewWorkspaceDialog(context, state);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showNewWorkspaceDialog(BuildContext context, AppState state) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nuovo workspace'),
      content: SizedBox(
        width: 360,
        child: WorkspaceNameForm(
          validate: state.validateNewName,
          onSubmit: (name) async {
            await state.createWorkspace(name);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    ),
  );
}
