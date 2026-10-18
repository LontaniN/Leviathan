import 'dart:io';

import 'package:flutter/material.dart';

import '../model/markdown.dart';
import '../model/note.dart';
import '../model/tags.dart';
import '../state/app_state.dart';
import '../state/notes_controller.dart';
import '../state/settings.dart';
import 'calendar_screen.dart';
import 'graph_screen.dart';
import 'lists_screen.dart';
import 'note_editor.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'task_check.dart';
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

  /// La nota appena salvata, la cui voce nella lista si illumina; [_flashSeq]
  /// cambia a ogni salvataggio, così il bagliore riparte anche sulla stessa.
  String? _flashId;
  int _flashSeq = 0;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _flash(Note note) {
    final seq = ++_flashSeq;
    setState(() => _flashId = note.id);
    // Finito il bagliore la voce torna normale: scorrendo via e tornando non
    // si riaccende.
    Future<void>.delayed(LeviathanDurations.saveFlash, () {
      if (mounted && _flashSeq == seq) setState(() => _flashId = null);
    });
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

  void _openLists() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ListsScreen(notes: _notes)));
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CalendarScreen(notes: _notes)),
    );
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
                      key: const Key('lists-button'),
                      tooltip: 'Task e note',
                      icon: const Icon(Icons.checklist),
                      onPressed: _openLists,
                    ),
                    IconButton(
                      key: const Key('calendar-button'),
                      tooltip: 'Calendario',
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: _openCalendar,
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
                          duration: LeviathanDurations.panel,
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
                                flashId: _flashId,
                                flashSeq: _flashSeq,
                              ),
                            ),
                          ),
                        ),
                        if (!_listExpanded)
                          Expanded(
                            child: NoteEditor(
                              tagCounts: _notes.tagCounts,
                              sourceCounts: _notes.sourceCounts,
                              onSave: (draft) => _flash(
                                _notes.create(
                                  title: draft.title,
                                  body: draft.body,
                                  tags: draft.tags,
                                  sources: draft.sources,
                                  isTask: draft.isTask,
                                ),
                              ),
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
    this.flashId,
    this.flashSeq = 0,
  });

  final List<Note> notes;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Note> onOpen;
  final void Function(Note note, bool done) onToggleDone;

  /// La nota da illuminare e il numero del salvataggio (vedi [_SaveFlash]).
  final String? flashId;
  final int flashSeq;

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
                  duration: LeviathanDurations.panel,
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
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    // La chiave tiene lo stato del bagliore attaccato alla
                    // nota quando una nuova entra in cima.
                    return _SaveFlash(
                      key: ValueKey(note.id),
                      color: _noteColor(context, note),
                      seq: note.id == flashId ? flashSeq : null,
                      child: expanded
                          ? _ExpandedTile(
                              note: note,
                              onTap: onOpen,
                              onToggleDone: onToggleDone,
                            )
                          : _CompactTile(
                              note: note,
                              onTap: onOpen,
                              onToggleDone: onToggleDone,
                            ),
                    );
                  },
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

/// Fa illuminare per un attimo una voce della lista nel colore della sua
/// nota, al posto di un avviso di salvataggio.
///
/// Si accende quando riceve un [seq] nuovo, anche alla prima comparsa.
class _SaveFlash extends StatefulWidget {
  const _SaveFlash({
    super.key,
    required this.color,
    required this.seq,
    required this.child,
  });

  final Color color;
  final int? seq;
  final Widget child;

  @override
  State<_SaveFlash> createState() => _SaveFlashState();
}

class _SaveFlashState extends State<_SaveFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LeviathanDurations.saveFlash,
  );

  // Si accende in fretta, resta acceso circa un secondo, poi sfuma.
  late final Animation<double> _glow = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 10,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 35,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    if (widget.seq != null) _controller.forward();
  }

  @override
  void didUpdateWidget(_SaveFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seq != null && widget.seq != oldWidget.seq) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      child: widget.child,
      // Il riquadro c'è sempre, trasparente a riposo: se comparisse e
      // sparisse, la voce sotto perderebbe il suo stato.
      builder: (context, child) => DecoratedBox(
        key: const Key('save-flash'),
        decoration: BoxDecoration(
          // L'opacità si sostituisce a quella della barretta, che per le
          // note senza tag è attenuata e renderebbe il bagliore invisibile.
          color: widget.color.withValues(
            alpha: LeviathanOpacity.saveFlash * _glow.value,
          ),
        ),
        child: child,
      ),
    );
  }
}

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
                      // Tenendo premuto si rinomina o elimina anche un
                      // workspace non aperto.
                      onLongPress: () {
                        Navigator.pop(sheetContext);
                        _showWorkspaceActions(context, state, name);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (state.currentWorkspace case final current?) ...[
              ListTile(
                key: const Key('rename-workspace'),
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Rinomina workspace'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRenameWorkspaceDialog(context, state, current);
                },
              ),
              ListTile(
                key: const Key('delete-workspace'),
                leading: const Icon(Icons.delete_outline),
                title: const Text('Elimina workspace'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteWorkspace(context, state, current);
                },
              ),
            ],
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

/// Le azioni su un workspace qualsiasi, aperte tenendo premuta la sua riga.
Future<void> _showWorkspaceActions(
  BuildContext context,
  AppState state,
  String name,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.palette.surface,
    builder: (sheetContext) => SafeArea(
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
            child: Text(name, style: TextStyle(color: context.palette.muted)),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rinomina'),
            onTap: () {
              Navigator.pop(sheetContext);
              _showRenameWorkspaceDialog(context, state, name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Elimina'),
            onTap: () {
              Navigator.pop(sheetContext);
              _confirmDeleteWorkspace(context, state, name);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeleteWorkspace(
  BuildContext context,
  AppState state,
  String name,
) async {
  final last = state.workspaces.length == 1;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Eliminare «$name»?'),
      content: Text(
        'Il workspace, con le sue note e il suo cestino, viene spostato in '
        '.leviathan/eliminati, non cancellato.'
        '${last ? ' È l\'unico workspace: dovrai crearne uno nuovo.' : ''}',
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
  // Se si elimina il workspace aperto la schermata viene ricreata: il
  // messenger va preso prima.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await state.deleteWorkspace(name);
    messenger.showSnackBar(
      SnackBar(content: Text('«$name» spostato in .leviathan/eliminati')),
    );
  } on FileSystemException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Impossibile eliminare: ${e.message}')),
    );
  }
}

Future<void> _showNewWorkspaceDialog(BuildContext context, AppState state) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nuovo workspace'),
      content: SizedBox(
        width: LeviathanSizes.dialogWidth,
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

Future<void> _showRenameWorkspaceDialog(
  BuildContext context,
  AppState state,
  String oldName,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Rinomina workspace'),
      content: SizedBox(
        width: LeviathanSizes.dialogWidth,
        child: WorkspaceNameForm(
          initialName: oldName,
          buttonLabel: 'Rinomina',
          validate: (name) => state.validateRename(oldName, name),
          onSubmit: (name) async {
            try {
              await state.renameWorkspace(oldName, name);
            } on FileSystemException catch (e) {
              throw ArgumentError('Impossibile rinominare: ${e.message}');
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    ),
  );
}
