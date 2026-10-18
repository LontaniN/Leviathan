import 'dart:io';

import 'package:flutter/material.dart';

import '../model/dates.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import '../model/tags.dart';
import '../state/app_state.dart';
import '../state/notes_controller.dart';
import '../state/settings.dart';
import 'calendar_screen.dart';
import 'chip_input.dart';
import 'graph_screen.dart';
import 'lists_screen.dart';
import 'note_actions.dart';
import 'note_editor.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'task_check.dart';
import 'theme.dart';
import 'workspace_name_form.dart';

/// Schermata principale di un workspace: in alto il nome e la barra di
/// ricerca, a sinistra le ultime note, a destra l'editor per scriverne una
/// nuova con tag e fonti.
///
/// La freccia in cima alla lista la espande a tutta larghezza, con anteprima,
/// tag e data di ogni nota. Le note fissate stanno in cima, le altre sotto
/// intestazioni per giorno o mese. Tenendo premuta una nota si fissa, si
/// spunta o si elimina.
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

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openNote(Note note) =>
      _push(NoteScreen(noteId: note.id, notes: _notes));

  void _openGraph() => _push(
    GraphScreen(
      notes: _notes,
      store: widget.state.graphLayoutOf(widget.state.currentWorkspace!),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Con la tastiera aperta si sta scrivendo: la barra di ricerca si ritira
    // e lascia lo spazio all'editor. Qui, sopra lo Scaffold, il MediaQuery
    // ha ancora l'altezza della tastiera.
    final writing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _notes,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                state: widget.state,
                notes: _notes.notes,
                onGraph: _openGraph,
                onLists: () => _push(ListsScreen(notes: _notes)),
                onCalendar: () => _push(CalendarScreen(notes: _notes)),
                onSettings: () =>
                    _push(SettingsScreen(settings: widget.settings)),
              ),
              AnimatedSize(
                duration: LeviathanDurations.panel,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: writing
                    ? const SizedBox(width: double.infinity)
                    : _SearchPill(
                        onTap: () => _push(SearchScreen(notes: _notes)),
                      ),
              ),
              Expanded(
                child: _notes.error != null
                    ? _LoadError(message: _notes.error!, onRetry: _notes.reload)
                    : _body(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsedWidth =
            (constraints.maxWidth * LeviathanSizes.listFraction).clamp(
              LeviathanSizes.listMin,
              LeviathanSizes.listMax,
            );
        final listWidth = _listExpanded ? constraints.maxWidth : collapsedWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: LeviathanDurations.panel,
              curve: Curves.easeOutCubic,
              width: listWidth,
              // Durante l'animazione la lista è già impaginata alla
              // larghezza finale e viene solo svelata.
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: listWidth,
                  maxWidth: listWidth,
                  child: _NoteList(
                    notes: _notes.notes,
                    expanded: _listExpanded,
                    onToggle: () =>
                        setState(() => _listExpanded = !_listExpanded),
                    onOpen: _openNote,
                    onLongPress: (note) =>
                        showNoteActions(context, _notes, note),
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
                  draft: widget.state.draftOf(widget.state.currentWorkspace!),
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
    );
  }
}

/// Nome del workspace con il riassunto sotto, e a destra le altre viste.
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.notes,
    required this.onGraph,
    required this.onLists,
    required this.onCalendar,
    required this.onSettings,
  });

  final AppState state;
  final List<Note> notes;
  final VoidCallback onGraph;
  final VoidCallback onLists;
  final VoidCallback onCalendar;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final open = notes.where((n) => n.isOpenTask).length;
    final summary = [
      notes.length == 1 ? '1 nota' : '${notes.length} note',
      if (open > 0) '$open da fare',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.xs,
        LeviathanSpacing.xs,
        LeviathanSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          // Tutto lo spazio libero va al nome, che va a capo solo se davvero
          // non ci sta.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkspaceButton(state: state),
                Padding(
                  padding: const EdgeInsets.only(left: LeviathanSpacing.md),
                  child: Text(
                    summary,
                    key: const Key('home-summary'),
                    style: LeviathanText.meta.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('graph-button'),
            tooltip: 'Grafo',
            icon: const Icon(Icons.hub_outlined),
            onPressed: onGraph,
          ),
          IconButton(
            key: const Key('lists-button'),
            tooltip: 'Task e note',
            icon: const Icon(Icons.checklist),
            onPressed: onLists,
          ),
          IconButton(
            key: const Key('calendar-button'),
            tooltip: 'Calendario',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: onCalendar,
          ),
          IconButton(
            key: const Key('settings-button'),
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

/// La barra di ricerca della home: una pillola che apre la ricerca vera e
/// ricorda le scorciatoie dei filtri.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget shortcut(String text) => Container(
      margin: const EdgeInsets.only(left: LeviathanSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: LeviathanSpacing.sm,
        vertical: LeviathanSpacing.xxs,
      ),
      decoration: ShapeDecoration(
        color: palette.surfaceHigh,
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: LeviathanText.meta.copyWith(
          color: palette.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.md,
        LeviathanSpacing.sm,
        LeviathanSpacing.md,
        LeviathanSpacing.xs,
      ),
      child: Material(
        color: palette.surface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('search-button'),
          onTap: onTap,
          child: SizedBox(
            height: LeviathanSizes.searchBar,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LeviathanSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: LeviathanIconSize.md,
                    color: palette.muted,
                  ),
                  const SizedBox(width: LeviathanSpacing.md),
                  Expanded(
                    child: Text(
                      'Cerca nelle note',
                      overflow: TextOverflow.ellipsis,
                      style: LeviathanText.body.copyWith(color: palette.muted),
                    ),
                  ),
                  shortcut('#'),
                  shortcut('@'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le note non si sono potute leggere (es. la cartella è sparita).
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: LeviathanIconSize.xl,
              color: context.palette.muted,
            ),
            const SizedBox(height: LeviathanSpacing.lg),
            Text(
              'Impossibile leggere le note: $message',
              textAlign: TextAlign.center,
              style: LeviathanText.body.copyWith(color: context.palette.muted),
            ),
            const SizedBox(height: LeviathanSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Riprova')),
          ],
        ),
      ),
    );
  }
}

/// Una riga della lista: un'intestazione di sezione o una nota.
sealed class _Entry {}

class _SectionEntry extends _Entry {
  _SectionEntry(this.label);

  final String label;
}

class _NoteEntry extends _Entry {
  _NoteEntry(this.note);

  final Note note;
}

/// Le fissate in cima, poi le altre sotto il loro giorno o mese.
List<_Entry> _entries(List<Note> notes, DateTime now) {
  final pinned = notes.where((n) => n.pinned).toList();
  final entries = <_Entry>[
    if (pinned.isNotEmpty) ...[
      _SectionEntry('Fissate'),
      for (final n in pinned) _NoteEntry(n),
    ],
  ];
  String? section;
  for (final note in notes) {
    if (note.pinned) continue;
    final label = dateSection(note.created, now);
    if (label != section) {
      entries.add(_SectionEntry(label));
      section = label;
    }
    entries.add(_NoteEntry(note));
  }
  return entries;
}

/// Cronologia delle note, dalla più recente.
class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.notes,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    required this.onLongPress,
    required this.onToggleDone,
    this.flashId,
    this.flashSeq = 0,
  });

  final List<Note> notes;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Note> onOpen;
  final ValueChanged<Note> onLongPress;
  final void Function(Note note, bool done) onToggleDone;

  /// La nota da illuminare e il numero del salvataggio (vedi [_SaveFlash]).
  final String? flashId;
  final int flashSeq;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entries = _entries(notes, DateTime.now());
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
              LeviathanSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    expanded ? 'Tutte le note (${notes.length})' : 'Recenti',
                    overflow: TextOverflow.ellipsis,
                    style: LeviathanText.title.copyWith(color: palette.text),
                  ),
                ),
                // Verso destra la lista si allarga, verso sinistra torna
                // stretta.
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: LeviathanDurations.panel,
                  child: Icon(
                    Icons.chevron_right,
                    size: LeviathanIconSize.md,
                    color: palette.accent,
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
                    'Nessuna nota. Quelle che salvi compaiono qui.',
                    style: LeviathanText.body.copyWith(color: palette.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => switch (entries[i]) {
                    _SectionEntry(:final label) => _SectionLabel(
                      key: ValueKey('section-$label'),
                      label: label,
                      expanded: expanded,
                    ),
                    // La chiave tiene lo stato del bagliore attaccato alla
                    // nota quando una nuova entra in cima.
                    _NoteEntry(:final note) => _SaveFlash(
                      key: ValueKey(note.id),
                      color: _noteColor(context, note),
                      seq: note.id == flashId ? flashSeq : null,
                      child: expanded
                          ? _ExpandedTile(
                              note: note,
                              onTap: onOpen,
                              onLongPress: onLongPress,
                              onToggleDone: onToggleDone,
                            )
                          : _CompactTile(
                              note: note,
                              onTap: onOpen,
                              onLongPress: onLongPress,
                              onToggleDone: onToggleDone,
                            ),
                    ),
                  },
                ),
        ),
      ],
    );
  }
}

/// Intestazione di una sezione della lista ("Oggi", "Fissate", un mese).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({super.key, required this.label, required this.expanded});

  final String label;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        expanded ? LeviathanSpacing.lg : LeviathanSpacing.md,
        LeviathanSpacing.md,
        LeviathanSpacing.sm,
        LeviathanSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: LeviathanText.caption.copyWith(color: context.palette.muted),
      ),
    );
  }
}

/// Barra colorata del primo tag (lo stesso colore del nodo nel grafo).
Color _noteColor(BuildContext context, Note note) => note.tags.isEmpty
    ? context.palette.muted.withValues(alpha: LeviathanOpacity.untagged)
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

/// La barretta del primo tag accanto a una voce.
class _TagBar extends StatelessWidget {
  const _TagBar({required this.note, required this.height});

  final Note note;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: LeviathanSizes.tagBar,
      height: height,
      decoration: BoxDecoration(
        color: _noteColor(context, note),
        borderRadius: BorderRadius.circular(LeviathanRadii.sm),
      ),
    );
  }
}

/// La data corta della voce, con la puntina se la nota è fissata.
class _When extends StatelessWidget {
  const _When({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note.pinned) ...[
          Icon(Icons.push_pin, size: LeviathanIconSize.xs, color: muted),
          const SizedBox(width: LeviathanSpacing.xxs),
        ],
        Text(
          formatRelative(note.created, DateTime.now()),
          style: LeviathanText.tiny.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleDone,
  });

  final Note note;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(note),
      onLongPress: () => onLongPress(note),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LeviathanSpacing.md,
          LeviathanSpacing.sm,
          LeviathanSpacing.sm,
          LeviathanSpacing.sm,
        ),
        child: Row(
          children: [
            _TagBar(note: note, height: LeviathanSizes.tagBarCompact),
            const SizedBox(width: LeviathanSpacing.sm),
            if (note.isTask)
              TaskCheck(
                note: note,
                onChanged: (done) => onToggleDone(note, done),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: taskTitleStyle(
                      context,
                      note,
                      LeviathanText.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: LeviathanSpacing.xxs),
                  _When(note: note),
                ],
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
    required this.onLongPress,
    required this.onToggleDone,
  });

  final Note note;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    final preview = plainText(note.body).trim().replaceAll(RegExp(r'\s+'), ' ');
    return InkWell(
      onTap: () => onTap(note),
      onLongPress: () => onLongPress(note),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LeviathanSpacing.lg,
          LeviathanSpacing.md,
          LeviathanSpacing.lg,
          LeviathanSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: LeviathanSpacing.xxs),
              child: _TagBar(note: note, height: LeviathanSizes.tagBarExpanded),
            ),
            const SizedBox(width: LeviathanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.isTask)
                        TaskCheck(
                          note: note,
                          onChanged: (done) => onToggleDone(note, done),
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
                      const SizedBox(width: LeviathanSpacing.sm),
                      _When(note: note),
                    ],
                  ),
                  if (preview.isNotEmpty && note.title.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: LeviathanSpacing.xs),
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

/// Il nome del workspace in alto: toccandolo si cambia workspace.
class _WorkspaceButton extends StatelessWidget {
  const _WorkspaceButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton(
      key: const Key('workspace-button'),
      onPressed: () => showWorkspaceSwitcher(context, state),
      style: TextButton.styleFrom(
        foregroundColor: palette.text,
        padding: const EdgeInsets.symmetric(horizontal: LeviathanSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LeviathanRadii.md),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              state.currentWorkspace ?? '',
              overflow: TextOverflow.ellipsis,
              style: LeviathanText.workspace,
            ),
          ),
          const SizedBox(width: LeviathanSpacing.xs),
          Icon(
            Icons.expand_more,
            size: LeviathanIconSize.md,
            color: palette.accent,
          ),
        ],
      ),
    );
  }
}

Future<void> showWorkspaceSwitcher(BuildContext context, AppState state) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
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
                'WORKSPACE',
                style: LeviathanText.caption.copyWith(
                  color: context.palette.muted,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final name in state.workspaces)
                    ListTile(
                      leading: Icon(
                        name == state.currentWorkspace
                            ? Icons.folder
                            : Icons.folder_outlined,
                      ),
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
            child: Text(
              name,
              style: LeviathanText.title.copyWith(color: context.palette.muted),
            ),
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
