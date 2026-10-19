import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import '../model/shared_text.dart';
import '../state/app_state.dart';
import '../state/notes_controller.dart';
import '../state/settings.dart';
import '../state/share_inbox.dart';
import 'app_tour.dart';
import 'calendar_screen.dart';
import 'chip_input.dart';
import 'graph_screen.dart';
import 'lists_screen.dart';
import 'note_actions.dart';
import 'note_editor.dart';
import 'note_screen.dart';
import 'pinned_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tag_bar.dart';
import 'tag_color_sheet.dart';
import 'task_manager_screen.dart';
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
///
/// Con [startTour] sopra la home parte il tour guidato delle funzioni
/// principali (vedi [AppTour]); si può rivedere dalle impostazioni.
///
/// Il testo condiviso da altre app ([shares]) finisce nella bozza
/// dell'editor: con più workspace si sceglie prima in quale.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.settings,
    required this.shares,
    this.startTour = false,
  });

  final AppState state;
  final Settings settings;
  final ShareInbox shares;
  final bool startTour;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final NotesController _notes = NotesController(
    widget.state.notesOf(widget.state.currentWorkspace!),
    tagColors: widget.state.tagColorsOf(widget.state.currentWorkspace!),
  );
  bool _listExpanded = false;

  /// Il tour guidato è aperto; [_tourWelcome] se parte dal benvenuto (la
  /// prima volta, non quando lo si rivede dalle impostazioni).
  late bool _touring = widget.startTour;
  late bool _tourWelcome = widget.startTour;

  /// Gli elementi che il tour illumina.
  final _editorKey = GlobalKey();
  final _tagsKey = GlobalKey();
  final _listKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _taskManagerKey = GlobalKey();
  final _viewsKey = GlobalKey();

  /// La nota appena salvata, la cui voce nella lista si illumina; [_flashSeq]
  /// cambia a ogni salvataggio, così il bagliore riparte anche sulla stessa.
  String? _flashId;
  int _flashSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.shares.addListener(_onShare);
    // Aperta da una condivisione, o arrivata mentre la home non c'era.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onShare());
    // Arrivando dall'onboarding la tastiera del nome può essere ancora
    // aperta e nasconderebbe parte della home.
    if (_touring) FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    widget.shares.removeListener(_onShare);
    WidgetsBinding.instance.removeObserver(this);
    _notes.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Mentre l'app era in secondo piano le note possono essere cambiate da
    // fuori (Obsidian, sincronizzazione, file manager).
    if (lifecycle == AppLifecycleState.resumed) _notes.reloadIfChanged();
  }

  /// Una condivisione alla volta: la scelta del workspace aspetta l'utente.
  bool _receivingShares = false;

  void _onShare() {
    if (mounted && !_receivingShares && widget.shares.hasPending) {
      _receiveShares();
    }
  }

  Future<void> _receiveShares() async {
    _receivingShares = true;
    try {
      // Cambiando workspace questa home sparisce: le condivisioni rimaste le
      // prende la nuova.
      while (mounted) {
        final share = widget.shares.take();
        if (share == null) break;
        await _receiveShare(share);
      }
    } finally {
      _receivingShares = false;
    }
  }

  /// Mette [share] nella bozza di un workspace e la mostra.
  ///
  /// Si torna alla home chiudendo quello che c'è sopra, ma non la modifica
  /// di una nota già salvata: lì il testo va nella bozza senza perdere le
  /// modifiche, e un avviso dice dove.
  Future<void> _receiveShare(SharedText share) async {
    final state = widget.state;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    var editing = false;
    Navigator.of(context).popUntil((route) {
      editing = route.settings.name == NoteEditor.editRouteName;
      return route.isFirst || editing;
    });
    var target = state.currentWorkspace!;
    if (state.workspaces.length > 1) {
      final picked = await _pickWorkspace();
      if (picked == null || !mounted) return;
      target = picked;
    }
    void notify(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message)));

    if (target == state.currentWorkspace) {
      if (_editorKey.currentState case final SharedTextReceiver editor) {
        final appended = editor.receiveShared(share);
        if (editing) {
          notify(l.sharedSavedToDraft(target));
        } else if (appended) {
          notify(l.sharedAppended);
        }
        return;
      }
      // Lista espansa: l'editor non c'è. Si scrive la bozza e lo si riapre,
      // così la rilegge.
      final appended = _addToDraft(target, share);
      setState(() => _listExpanded = false);
      if (appended) notify(l.sharedAppended);
      return;
    }
    final appended = _addToDraft(target, share);
    if (editing) {
      // Una nota di questo workspace è aperta in modifica: si resta qui.
      notify(l.sharedSavedToDraft(target));
      return;
    }
    await state.switchTo(target);
    if (appended) notify(l.sharedAppended);
  }

  /// Aggiunge [share] alla bozza salvata del workspace [name]; true se la
  /// bozza aveva già qualcosa.
  bool _addToDraft(String name, SharedText share) {
    final store = widget.state.draftOf(name);
    final draft = store.read();
    final merged = mergeShared(draft?.title ?? '', draft?.body ?? '', share);
    store.write((
      title: merged.title,
      body: merged.body,
      tags: draft?.tags ?? const [],
      sources: draft?.sources ?? const [],
      isTask: draft?.isTask ?? false,
      knowledge: draft?.knowledge ?? false,
      nextStep: draft?.nextStep ?? '',
      date: draft?.date,
    ));
    return merged.appended;
  }

  Future<String?> _pickWorkspace() {
    final state = widget.state;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(dialogContext.l10n.shareToWorkspace),
        children: [
          for (final name in state.workspaces)
            SimpleDialogOption(
              key: ValueKey('share-to-$name'),
              onPressed: () => Navigator.pop(dialogContext, name),
              child: Row(
                children: [
                  Icon(
                    name == state.currentWorkspace
                        ? Icons.folder
                        : Icons.folder_outlined,
                    size: LeviathanIconSize.md,
                    color: dialogContext.palette.accent,
                  ),
                  const SizedBox(width: LeviathanSpacing.md),
                  Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Riapre il tour dalle impostazioni: senza benvenuto, con la lista
  /// stretta così l'editor si vede.
  void _replayTour() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _listExpanded = false;
      _tourWelcome = false;
      _touring = true;
    });
  }

  void _endTour() {
    widget.settings.markTourSeen();
    widget.state.firstWorkspaceCreated = false;
    setState(() => _touring = false);
  }

  List<TourStep> _tourSteps(AppLocalizations l) => [
    (target: _editorKey, title: l.tourEditorTitle, body: l.tourEditorBody),
    (target: _tagsKey, title: l.tourTagsTitle, body: l.tourTagsBody),
    (target: _listKey, title: l.tourListTitle, body: l.tourListBody),
    (target: _searchKey, title: l.tourSearchTitle, body: l.tourSearchBody),
    (
      target: _taskManagerKey,
      title: l.tourTaskManagerTitle,
      body: l.tourTaskManagerBody,
    ),
    (target: _viewsKey, title: l.tourViewsTitle, body: l.tourViewsBody),
  ];

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
    final l = context.l10n;
    // Durante il tour il tasto indietro lo chiude invece di uscire dall'app.
    return PopScope(
      canPop: !_touring,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _touring) _endTour();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _scaffold(writing),
          if (_touring)
            Positioned.fill(
              child: AppTour(
                steps: _tourSteps(l),
                welcome: _tourWelcome
                    ? (
                        title: l.tourWelcomeTitle(
                          widget.state.currentWorkspace ?? '',
                        ),
                        body: l.tourWelcomeBody,
                      )
                    : null,
                onDone: _endTour,
              ),
            ),
        ],
      ),
    );
  }

  Widget _scaffold(bool writing) {
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
                viewsKey: _viewsKey,
                taskManagerKey: _taskManagerKey,
                onPinned: () => _push(PinnedScreen(notes: _notes)),
                onGraph: _openGraph,
                onLists: () => _push(ListsScreen(notes: _notes)),
                onCalendar: () => _push(CalendarScreen(notes: _notes)),
                onTaskManager: () => _push(TaskManagerScreen(notes: _notes)),
                onSettings: () => _push(
                  SettingsScreen(
                    settings: widget.settings,
                    onReplayTour: _replayTour,
                  ),
                ),
              ),
              AnimatedSize(
                duration: LeviathanDurations.panel,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: writing
                    ? const SizedBox(width: double.infinity)
                    : _SearchPill(
                        key: _searchKey,
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
              key: _listKey,
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
                  key: _editorKey,
                  tagsKey: _tagsKey,
                  tagCounts: _notes.tagCounts,
                  sourceCounts: _notes.sourceCounts,
                  draft: widget.state.draftOf(widget.state.currentWorkspace!),
                  onTagLongPress: (tag) =>
                      showTagColorSheet(context, _notes, tag),
                  onSourceLongPress: (source) =>
                      showSourceSheet(context, _notes, source),
                  onSave: (draft) => _flash(
                    _notes.create(
                      title: draft.title,
                      body: draft.body,
                      tags: draft.tags,
                      sources: draft.sources,
                      isTask: draft.isTask,
                      knowledge: draft.knowledge,
                      nextStep: draft.nextStep,
                      created: draft.date == null
                          ? null
                          : onDay(draft.date!, DateTime.now()),
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
    required this.viewsKey,
    required this.taskManagerKey,
    required this.onPinned,
    required this.onGraph,
    required this.onLists,
    required this.onCalendar,
    required this.onTaskManager,
    required this.onSettings,
  });

  final AppState state;
  final List<Note> notes;

  /// Chiavi del gruppo di icone delle altre viste e del pulsante del task
  /// manager, per il tour.
  final GlobalKey viewsKey;
  final GlobalKey taskManagerKey;
  final VoidCallback onPinned;
  final VoidCallback onGraph;
  final VoidCallback onLists;
  final VoidCallback onCalendar;
  final VoidCallback onTaskManager;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final open = notes.where((n) => n.isOpenTask).length;
    final summary = [
      l.noteCount(notes.length),
      if (open > 0) l.openCount(open),
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
          Row(
            key: viewsKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('pinned-button'),
                tooltip: l.pinned,
                icon: const Icon(Icons.push_pin_outlined),
                onPressed: onPinned,
              ),
              IconButton(
                key: const Key('graph-button'),
                tooltip: l.graph,
                icon: const Icon(Icons.hub_outlined),
                onPressed: onGraph,
              ),
              IconButton(
                key: const Key('lists-button'),
                tooltip: l.tasksAndNotes,
                icon: const Icon(Icons.checklist),
                onPressed: onLists,
              ),
              IconButton(
                key: const Key('calendar-button'),
                tooltip: l.calendar,
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: onCalendar,
              ),
              KeyedSubtree(
                key: taskManagerKey,
                child: IconButton(
                  key: const Key('task-manager-button'),
                  tooltip: l.taskManager,
                  icon: const Icon(Icons.low_priority),
                  onPressed: onTaskManager,
                ),
              ),
              IconButton(
                key: const Key('settings-button'),
                tooltip: l.settings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La barra di ricerca della home: una pillola che apre la ricerca vera e
/// ricorda le scorciatoie dei filtri.
class _SearchPill extends StatelessWidget {
  const _SearchPill({super.key, required this.onTap});

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
                      context.l10n.searchNotes,
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
              context.l10n.loadError(message),
              textAlign: TextAlign.center,
              style: LeviathanText.body.copyWith(color: context.palette.muted),
            ),
            const SizedBox(height: LeviathanSpacing.lg),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
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
List<_Entry> _entries(AppLocalizations l, List<Note> notes, DateTime now) {
  final pinned = notes.where((n) => n.pinned).toList();
  final entries = <_Entry>[
    if (pinned.isNotEmpty) ...[
      _SectionEntry(l.pinned),
      for (final n in pinned) _NoteEntry(n),
    ],
  ];
  String? section;
  for (final note in notes) {
    if (note.pinned) continue;
    final label = dateSection(l, note.created, now);
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
    final l = context.l10n;
    final entries = _entries(l, notes, DateTime.now());
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
                    expanded ? l.allNotes(notes.length) : l.recent,
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
                    l.noNotesYet,
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
                      color: noteColor(context, note),
                      seq: note.id == flashId ? flashSeq : null,
                      child: _NoteDivider(
                        // Fra due note una linea sottile le separa; prima di
                        // un'intestazione di sezione non serve.
                        show: _isNote(entries, i + 1),
                        indent: expanded
                            ? LeviathanSpacing.lg
                            : LeviathanSpacing.md,
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
                    ),
                  },
                ),
        ),
      ],
    );
  }
}

/// La riga [i] esiste ed è una nota.
bool _isNote(List<_Entry> entries, int i) =>
    i < entries.length && entries[i] is _NoteEntry;

/// Una voce con, se [show], una linea sottile sotto.
class _NoteDivider extends StatelessWidget {
  const _NoteDivider({
    required this.show,
    required this.indent,
    required this.child,
  });

  final bool show;
  final double indent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        Divider(height: 1, indent: indent, endIndent: indent),
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
        // Nella colonna stretta una data con l'anno e la puntina possono non
        // starci: la data si accorcia invece di sforare.
        Flexible(
          child: Text(
            formatRelative(context.l10n, note.created, DateTime.now()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: LeviathanText.tiny.copyWith(color: muted),
          ),
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
            TagBar(note: note, height: LeviathanSizes.tagBarCompact),
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
                    note.displayTitle(context.l10n.untitled),
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
              child: TagBar(note: note, height: LeviathanSizes.tagBarExpanded),
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
                          note.displayTitle(context.l10n.untitled),
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
                context.l10n.workspace.toUpperCase(),
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
                title: Text(context.l10n.renameWorkspace),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRenameWorkspaceDialog(context, state, current);
                },
              ),
              ListTile(
                key: const Key('delete-workspace'),
                leading: const Icon(Icons.delete_outline),
                title: Text(context.l10n.deleteWorkspace),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteWorkspace(context, state, current);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(context.l10n.newWorkspace),
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
            title: Text(context.l10n.rename),
            onTap: () {
              Navigator.pop(sheetContext);
              _showRenameWorkspaceDialog(context, state, name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(context.l10n.delete),
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
  final l = context.l10n;
  final last = state.workspaces.length == 1;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.deleteWorkspaceTitle(name)),
      content: Text(
        [l.deleteWorkspaceBody, if (last) l.deleteWorkspaceLast].join(' '),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l.delete),
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
    messenger.showSnackBar(SnackBar(content: Text(l.workspaceDeleted(name))));
  } on FileSystemException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.cannotDelete(e.message))));
  }
}

Future<void> _showNewWorkspaceDialog(BuildContext context, AppState state) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.newWorkspace),
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
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.renameWorkspace),
      content: SizedBox(
        width: LeviathanSizes.dialogWidth,
        child: WorkspaceNameForm(
          initialName: oldName,
          buttonLabel: l.rename,
          validate: (name) => state.validateRename(oldName, name),
          onSubmit: (name) async {
            try {
              await state.renameWorkspace(oldName, name);
            } on FileSystemException catch (e) {
              throw ArgumentError(l.cannotRename(e.message));
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    ),
  );
}
