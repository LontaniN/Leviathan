import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/draft_store.dart';
import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/home_buttons.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import '../model/shared_text.dart';
import '../state/app_state.dart';
import '../state/diary_extracts.dart';
import '../state/diary_sync.dart';
import '../state/notes_controller.dart';
import '../state/settings.dart';
import '../state/share_inbox.dart';
import 'app_tour.dart';
import 'calendar_screen.dart';
import 'chip_input.dart';
import 'diary_screen.dart';
import 'graph_screen.dart';
import 'home_buttons_screen.dart';
import 'lists_screen.dart';
import 'note_actions.dart';
import 'note_editor.dart';
import 'note_picker_screen.dart';
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
/// ricerca, sotto, a tutta larghezza, l'editor per scrivere una nota nuova
/// con tag e fonti.
///
/// Il tasto accanto alla ricerca apre l'elenco di tutte le note, con
/// anteprima, tag e data di ognuna (vedi [_AllNotesScreen]). Salvando una
/// nota il tasto si illumina nel suo colore.
///
/// Con [startTour] sopra la home parte il tour guidato delle funzioni
/// principali (vedi [AppTour]); si può rivedere dalle impostazioni.
///
/// Il testo condiviso da altre app ([shares]) finisce nella bozza
/// dell'editor: con più workspace si sceglie prima in quale.
///
/// Ogni nota nuova entra anche nel diario, come riga col suo titolo nel
/// giorno della nota (vedi [DiarySync]).
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
    editDraft: widget.state.editDraftOf(widget.state.currentWorkspace!),
    recent: widget.state.recentOf(widget.state.currentWorkspace!),
  );

  /// Il diario del workspace, con i suoi pezzi colorati: la home ci porta
  /// ogni nota nuova (vedi [DiarySync]) e li passa al diario quando lo apre.
  late final _diaryStore = widget.state.diaryOf(widget.state.currentWorkspace!);
  late final _diaryExtracts = DiaryExtracts(_diaryStore);
  late final _diarySync = DiarySync(_diaryStore, _diaryExtracts, _notes);
  bool _diarySyncQueued = false;

  /// La modifica di una nota rimasta a metà quando Android ha chiuso l'app:
  /// la home propone di riprenderla.
  EditDraft? _resume;

  /// Il tour guidato è aperto; [_tourWelcome] se parte dal benvenuto (la
  /// prima volta, non quando lo si rivede dalle impostazioni).
  late bool _touring = widget.startTour;
  late bool _tourWelcome = widget.startTour;

  /// Gli elementi che il tour illumina.
  final _editorKey = GlobalKey();
  final _tagsKey = GlobalKey();
  final _notesKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _taskManagerKey = GlobalKey();
  final _viewsKey = GlobalKey();
  final _settingsKey = GlobalKey();

  /// La nota appena salvata, nel cui colore si illumina il tasto delle note;
  /// [_flashSeq] cambia a ogni salvataggio, così il bagliore riparte anche
  /// sulla stessa.
  String? _flashId;
  int _flashSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resume = _pendingEdit();
    // Le note che ci sono già e non sono nel diario ci entrano subito.
    _diarySync.run();
    _notes.addListener(_queueDiarySync);
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
    _notes.removeListener(_queueDiarySync);
    _diaryExtracts.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Le note sono cambiate: quelle nuove vanno nel diario. Si aspetta la
  /// fine del lavoro in corso, così una nota creata dal diario ha già il suo
  /// pezzo colorato e non entra una seconda volta.
  void _queueDiarySync() {
    if (_diarySyncQueued) return;
    _diarySyncQueued = true;
    scheduleMicrotask(() {
      _diarySyncQueued = false;
      if (mounted) _diarySync.run();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Mentre l'app era in secondo piano le note possono essere cambiate da
    // fuori (Obsidian, sincronizzazione, file manager).
    if (lifecycle == AppLifecycleState.resumed) _notes.reloadIfChanged();
  }

  /// La modifica rimasta a metà, se la sua nota c'è ancora; altrimenti la
  /// si butta.
  EditDraft? _pendingEdit() {
    final store = _notes.editDraft;
    final edit = store?.read();
    if (edit == null) return null;
    if (_notes.byId(edit.noteId) == null) {
      store!.clear();
      return null;
    }
    return edit;
  }

  void _resumeEdit() {
    final edit = _resume;
    final note = edit == null ? null : _notes.byId(edit.noteId);
    setState(() => _resume = null);
    if (note != null) openNoteEditor(context, _notes, note, resume: edit);
  }

  void _dismissResume() {
    _notes.editDraft?.clear();
    setState(() => _resume = null);
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
      // L'editor non c'è ancora: la bozza la legge quando compare.
      if (_addToDraft(target, share)) notify(l.sharedAppended);
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
      date: draft?.date,
      due: draft?.due,
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

  /// Riapre il tour dalle impostazioni, senza benvenuto.
  void _replayTour() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
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
    (target: _notesKey, title: l.tourListTitle, body: l.tourListBody),
    (target: _searchKey, title: l.tourSearchTitle, body: l.tourSearchBody),
    // Tolto dalla fila in alto, il task manager non ha niente da illuminare.
    if (widget.settings.homeButtons.contains(HomeButton.taskManager))
      (
        target: _taskManagerKey,
        title: l.tourTaskManagerTitle,
        body: l.tourTaskManagerBody,
      ),
    (target: _viewsKey, title: l.tourViewsTitle, body: l.tourViewsBody),
    // Per ultimo l'ingranaggio: da lì si sceglie quali pulsanti stanno in
    // alto e in che ordine.
    (
      target: _settingsKey,
      title: l.tourSettingsTitle,
      body: l.tourSettingsBody,
    ),
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

  void _openNotes() => _push(_AllNotesScreen(notes: _notes));

  void _openGraph() => _push(
    GraphScreen(
      notes: _notes,
      store: widget.state.graphLayoutOf(widget.state.currentWorkspace!),
    ),
  );

  void _openView(HomeButton button) => switch (button) {
    HomeButton.pinned => _push(PinnedScreen(notes: _notes)),
    HomeButton.graph => _openGraph(),
    HomeButton.lists => _push(ListsScreen(notes: _notes)),
    HomeButton.calendar => _push(CalendarScreen(notes: _notes)),
    HomeButton.diary => _push(
      DiaryScreen(store: _diaryStore, extracts: _diaryExtracts, notes: _notes),
    ),
    HomeButton.taskManager => _push(TaskManagerScreen(notes: _notes)),
  };

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
                        body: l.tourWelcomeBody(_tourSteps(l).length),
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
        // Cambiando i pulsanti dalle impostazioni la fila in alto si rifà.
        child: ListenableBuilder(
          listenable: Listenable.merge([_notes, widget.settings]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                state: widget.state,
                notes: _notes.notes,
                buttons: widget.settings.homeButtons,
                viewsKey: _viewsKey,
                settingsKey: _settingsKey,
                taskManagerKey: _taskManagerKey,
                onOpen: _openView,
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
                    : _SearchRow(
                        searchKey: _searchKey,
                        notesKey: _notesKey,
                        onSearch: () => _push(SearchScreen(notes: _notes)),
                        onNotes: _openNotes,
                        flash: _flashId == null ? null : _notes.byId(_flashId!),
                        flashSeq: _flashSeq,
                      ),
              ),
              if (_resume case final edit? when !writing)
                _ResumeBanner(
                  title:
                      _notes
                          .byId(edit.noteId)
                          ?.displayTitle(context.l10n.untitled) ??
                      '',
                  onResume: _resumeEdit,
                  onDismiss: _dismissResume,
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
    return NoteEditor(
      key: _editorKey,
      tagsKey: _tagsKey,
      tagCounts: _notes.tagCounts,
      sourceCounts: _notes.sourceCounts,
      draft: widget.state.draftOf(widget.state.currentWorkspace!),
      onTagLongPress: (tag) => showTagColorSheet(context, _notes, tag),
      onSourceLongPress: (source) => showSourceSheet(context, _notes, source),
      onPickNote: () => pickNote(context, _notes),
      onSave: (draft) => _flash(
        _notes.create(
          title: draft.title,
          body: draft.body,
          tags: draft.tags,
          sources: draft.sources,
          isTask: draft.isTask,
          knowledge: draft.knowledge,
          due: draft.due,
          created: draft.date == null
              ? null
              : onDay(draft.date!, DateTime.now()),
        ),
      ),
    );
  }
}

/// "Stavi modificando …": riprende una modifica rimasta a metà quando
/// Android ha chiuso l'app, col cursore dove era.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.title,
    required this.onResume,
    required this.onDismiss,
  });

  final String title;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.md,
        0,
        LeviathanSpacing.md,
        LeviathanSpacing.sm,
      ),
      child: Material(
        key: const Key('resume-banner'),
        color: palette.surface,
        borderRadius: BorderRadius.circular(LeviathanRadii.lg),
        child: Padding(
          padding: const EdgeInsets.only(left: LeviathanSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.edit_note,
                size: LeviathanIconSize.md,
                color: palette.accent,
              ),
              const SizedBox(width: LeviathanSpacing.md),
              Expanded(
                child: Text(
                  l.resumeEditing(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LeviathanText.meta.copyWith(color: palette.text),
                ),
              ),
              TextButton(
                key: const Key('resume-edit'),
                onPressed: onResume,
                child: Text(l.resume),
              ),
              IconButton(
                key: const Key('resume-dismiss'),
                tooltip: l.discardEdit,
                icon: const Icon(Icons.close, size: LeviathanIconSize.md),
                color: palette.muted,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nome del workspace con il riassunto sotto, e a destra le altre viste.
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.notes,
    required this.buttons,
    required this.viewsKey,
    required this.settingsKey,
    required this.taskManagerKey,
    required this.onOpen,
    required this.onSettings,
  });

  final AppState state;
  final List<Note> notes;

  /// I pulsanti scelti nelle impostazioni, in ordine; le impostazioni
  /// vengono sempre dopo.
  final List<HomeButton> buttons;

  /// Chiavi del gruppo di icone delle altre viste e dei pulsanti del task
  /// manager e delle impostazioni, per il tour.
  final GlobalKey viewsKey;
  final GlobalKey settingsKey;
  final GlobalKey taskManagerKey;
  final ValueChanged<HomeButton> onOpen;
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
          // Il nome prende lo spazio che gli serve, fino a metà riga; il
          // resto va alle icone, che scorrono se non ci stanno tutte.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.sizeOf(context).width *
                  LeviathanSizes.headerNameFraction,
            ),
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
          Expanded(
            child: _ScrollingIcons(
              key: viewsKey,
              children: [
                for (final button in buttons)
                  KeyedSubtree(
                    key: button == HomeButton.taskManager
                        ? taskManagerKey
                        : ValueKey(button),
                    child: IconButton(
                      key: button.homeKey,
                      tooltip: button.label(l),
                      icon: Icon(button.icon),
                      onPressed: () => onOpen(button),
                    ),
                  ),
                KeyedSubtree(
                  key: settingsKey,
                  child: IconButton(
                    key: const Key('settings-button'),
                    tooltip: l.settings,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: onSettings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le icone delle viste in cima alla home: se non ci stanno tutte scorrono
/// in orizzontale. Partono allineate a destra, con le ultime (task manager,
/// impostazioni) in vista; dal lato dove ce ne sono altre nascoste sfumano,
/// così si capisce che si può scorrere.
class _ScrollingIcons extends StatefulWidget {
  const _ScrollingIcons({super.key, required this.children});

  final List<Widget> children;

  @override
  State<_ScrollingIcons> createState() => _ScrollingIconsState();
}

class _ScrollingIconsState extends State<_ScrollingIcons> {
  final _scroll = ScrollController();

  /// Ci sono icone nascoste a sinistra o a destra.
  bool _hiddenLeft = false;
  bool _hiddenRight = false;

  bool _update(ScrollMetrics metrics) {
    // La lista è rovesciata: "dopo" è a sinistra.
    final left = metrics.extentAfter > 0;
    final right = metrics.extentBefore > 0;
    if (left != _hiddenLeft || right != _hiddenRight) {
      setState(() {
        _hiddenLeft = left;
        _hiddenRight = right;
      });
    }
    return false;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fade = LeviathanSizes.headerFade;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _update(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _update(n.metrics),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          // È una maschera, non un colore: conta solo quanto è opaca.
          shaderCallback: (bounds) {
            final edge = bounds.width == 0 ? 0.0 : fade / bounds.width;
            return LinearGradient(
              colors: [
                _hiddenLeft ? Colors.transparent : Colors.black,
                Colors.black,
                Colors.black,
                _hiddenRight ? Colors.transparent : Colors.black,
              ],
              stops: [0, edge, 1 - edge, 1],
            ).createShader(bounds);
          },
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.children,
            ),
          ),
        ),
      ),
    );
  }
}

/// La barra di ricerca della home e, accanto, il tasto che apre tutte le
/// note. Il tasto si illumina nel colore di [flash], la nota appena salvata.
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.searchKey,
    required this.notesKey,
    required this.onSearch,
    required this.onNotes,
    required this.flash,
    required this.flashSeq,
  });

  /// Chiavi della barra e del tasto, per il tour.
  final GlobalKey searchKey;
  final GlobalKey notesKey;
  final VoidCallback onSearch;
  final VoidCallback onNotes;
  final Note? flash;
  final int flashSeq;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.md,
        LeviathanSpacing.sm,
        LeviathanSpacing.md,
        LeviathanSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchPill(key: searchKey, onTap: onSearch),
          ),
          const SizedBox(width: LeviathanSpacing.sm),
          Material(
            key: notesKey,
            color: palette.surface,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: _SaveFlash(
              color: flash == null
                  ? palette.accent
                  : noteColor(context, flash!),
              seq: flash == null ? null : flashSeq,
              child: InkWell(
                key: const Key('notes-button'),
                onTap: onNotes,
                child: Tooltip(
                  message: context.l10n.recent,
                  child: SizedBox.square(
                    dimension: LeviathanSizes.searchBar,
                    child: Icon(
                      Icons.history,
                      size: LeviathanIconSize.md,
                      color: palette.accent,
                    ),
                  ),
                ),
              ),
            ),
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
    return Material(
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

/// Tutte le note, dalla più recente: le fissate in cima, le altre sotto
/// intestazioni per giorno o mese, con anteprima, tag e data. Si apre dal
/// tasto accanto alla ricerca della home. Tenendo premuta una nota si fissa,
/// si spunta o si elimina.
class _AllNotesScreen extends StatelessWidget {
  const _AllNotesScreen({required this.notes});

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
        final palette = context.palette;
        final l = context.l10n;
        final all = notes.notes;
        final entries = _entries(l, all, DateTime.now());
        return Scaffold(
          appBar: AppBar(title: Text(l.allNotes(all.length))),
          body: all.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(LeviathanSpacing.lg),
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
                    ),
                    _NoteEntry(:final note) => _NoteDivider(
                      key: ValueKey(note.id),
                      // Fra due note una linea sottile le separa; prima di
                      // un'intestazione di sezione non serve.
                      show: _isNote(entries, i + 1),
                      child: _NoteTile(
                        note: note,
                        onTap: (n) => _open(context, n),
                        onLongPress: (n) => showNoteActions(context, notes, n),
                        onToggleDone: notes.setDone,
                      ),
                    ),
                  },
                ),
        );
      },
    );
  }
}

/// La riga [i] esiste ed è una nota.
bool _isNote(List<_Entry> entries, int i) =>
    i < entries.length && entries[i] is _NoteEntry;

/// Una voce con, se [show], una linea sottile sotto.
class _NoteDivider extends StatelessWidget {
  const _NoteDivider({super.key, required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const Divider(
          height: 1,
          indent: LeviathanSpacing.lg,
          endIndent: LeviathanSpacing.lg,
        ),
      ],
    );
  }
}

/// Intestazione di una sezione della lista ("Oggi", "Fissate", un mese).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
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

/// Fa illuminare per un attimo il tasto delle note nel colore della nota
/// appena salvata, al posto di un avviso di salvataggio.
///
/// Si accende quando riceve un [seq] nuovo, anche alla prima comparsa.
class _SaveFlash extends StatefulWidget {
  const _SaveFlash({
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
        // Accanto a un titolo lungo una data con l'anno e la puntina possono
        // non starci: la data si accorcia invece di sforare.
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

class _NoteTile extends StatelessWidget {
  const _NoteTile({
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
