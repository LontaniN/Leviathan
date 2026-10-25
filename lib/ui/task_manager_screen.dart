import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/note.dart';
import '../model/note_groups.dart';
import '../model/tags.dart';
import '../model/task_order.dart';
import '../state/notes_controller.dart';
import '../state/settings.dart';
import 'brain_dump_screen.dart';
import 'note_screen.dart';
import 'task_check.dart';
import 'tag_bar.dart';
import 'task_compare_screen.dart';
import 'theme.dart';

/// Il task manager: uno spazio dove mettere in ordine i task per priorità,
/// senza badare a tag e fonti. Si apre dalla home, accanto al calendario.
///
/// Nella scheda "Da fare" i task aperti stanno in tre fasce (Ora, Prossimo,
/// Più avanti); la priorità è la posizione, non un'etichetta. Si trascina un
/// task (tenendolo premuto o dalla maniglia) per spostarlo nella fascia o fra
/// le fasce. I task nuovi arrivano in "Da ordinare", in cima, e si possono
/// sistemare rispondendo a qualche "Quale viene prima?" (vedi
/// [TaskCompareScreen]).
///
/// La scheda "Completati" mostra i task fatti, dal più recente.
///
/// Il filtro in alto restringe entrambe le schede ai task di uno o più tag e
/// fonti (basta averne uno), con le stesse fasce e lo stesso ordine: serve a
/// vedere le priorità di una o più liste. Filtrata, la vista è in sola lettura: l'ordine vale per
/// tutti i task, e spostarne uno fra pochi lo metterebbe a caso fra gli altri.
class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Vuoto: tutti i task.
  Set<GroupFilter> _filter = const {};

  NotesController get notes => widget.notes;

  /// Apre "Svuota la testa"; i task scritti finiscono in "Da ordinare".
  Future<void> _brainDump() async {
    final added = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BrainDumpScreen(notes: notes),
      ),
    );
    if (added == null || added == 0 || !mounted) return;
    // I task nuovi stanno in cima a "Da fare": la si mostra.
    _tabs.animateTo(0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.brainDumpAdded(added))),
      );
  }

  Future<void> _pickFilter() async {
    final picked = await showModalBottomSheet<Set<GroupFilter>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      builder: (_) => _FilterSheet(notes: notes.notes, selected: _filter),
    );
    if (picked == null || !mounted) return;
    setState(() => _filter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final filter = _filter;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text(l.taskManager),
        actions: [
          IconButton(
            key: const Key('brain-dump-button'),
            tooltip: l.brainDump,
            icon: const Icon(Icons.playlist_add),
            onPressed: _brainDump,
          ),
          IconButton(
            key: const Key('task-manager-filter'),
            tooltip: l.taskFilterTooltip,
            icon: Icon(
              filter.isEmpty ? Icons.filter_list : Icons.filter_list_alt,
            ),
            color: filter.isEmpty ? palette.text : palette.accent,
            onPressed: _pickFilter,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: palette.text,
          unselectedLabelColor: palette.muted,
          indicatorColor: palette.accent,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l.taskManagerOpenTab),
            Tab(text: l.taskManagerDoneTab),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: notes,
        builder: (context, _) {
          if (notes.error != null) {
            return _Message(icon: Icons.error_outline, text: notes.error!);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (filter.isNotEmpty)
                _FilterBanner(
                  filter: filter,
                  onClear: () => setState(() => _filter = const {}),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _OpenTab(notes: notes, filter: filter),
                    _DoneTab(notes: notes, filter: filter),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _openNote(BuildContext context, NotesController notes, Note note) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NoteScreen(noteId: note.id, notes: notes),
    ),
  );
}

/// Una voce della lista "Da fare": l'intestazione di una fascia, un task o
/// il segnaposto di una fascia vuota.
sealed class _Entry {
  const _Entry();
}

class _Header extends _Entry {
  const _Header(this.band);

  /// null per "Da ordinare".
  final TaskBand? band;
}

class _Task extends _Entry {
  const _Task(this.note);
  final Note note;
}

class _Placeholder extends _Entry {
  const _Placeholder(this.band);
  final TaskBand band;
}

class _OpenTab extends StatelessWidget {
  const _OpenTab({required this.notes, required this.filter});

  final NotesController notes;

  /// Con un filtro la lista non si riordina.
  final Set<GroupFilter> filter;

  List<_Entry> _entries(TaskBoard board) => [
    if (board.unsorted.isNotEmpty) ...[
      const _Header(null),
      for (final note in board.unsorted) _Task(note),
    ],
    for (final band in TaskBand.values) ...[
      _Header(band),
      for (final note in board.bands[band]!) _Task(note),
      if (board.bands[band]!.isEmpty) _Placeholder(band),
    ],
  ];

  /// Dove finisce un task trascinato ([newIndex] conta già senza di lui):
  /// la fascia è quella dell'intestazione
  /// sopra il punto di arrivo, e la posizione è contata fra i suoi task.
  void _onReorder(
    TaskBoard board,
    List<_Entry> entries,
    int oldIndex,
    int newIndex,
  ) {
    final moving = entries[oldIndex];
    if (moving is! _Task) return;
    final rest = [...entries]..removeAt(oldIndex);
    var target = newIndex.clamp(0, rest.length);
    // Sopra la prima intestazione vuol dire in cima alla prima fascia.
    if (target == 0) target = 1;
    TaskBand? band;
    var position = 0;
    for (var i = target - 1; i >= 0; i--) {
      final entry = rest[i];
      if (entry is _Header) {
        band = entry.band;
        break;
      }
      if (entry is _Task) position++;
    }
    final note = moving.note;
    final list = band == null ? board.unsorted : board.bands[band]!;
    // Mollato dove già stava: nessun file da riscrivere.
    if (note.band == band &&
        (band == null || list.indexWhere((n) => n.id == note.id) == position)) {
      return;
    }
    notes.place(note, band, list, position);
  }

  void _complete(BuildContext context, Note note) {
    final l = context.l10n;
    notes.setDone(note, true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.taskCompleted(note.displayTitle(l.untitled))),
          persist: false,
          duration: LeviathanDurations.undoSnackBar,
          action: SnackBarAction(
            label: l.undo,
            // Ripresa aggiornata: nel frattempo può essere cambiata.
            onPressed: () {
              final current = notes.byId(note.id);
              if (current != null) notes.setDone(current, false);
            },
          ),
        ),
      );
  }

  void _compare(BuildContext context, List<Note> queue) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TaskCompareScreen(
          notes: notes,
          queue: [for (final n in queue) n.id],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = TaskBoard.of(notes.notes.where((n) => inAnyGroup(n, filter)));
    if (board.isEmpty) {
      return _Message(
        icon: Icons.low_priority,
        text: filter.isEmpty
            ? context.l10n.taskManagerEmpty
            : context.l10n.taskManagerFilteredEmpty,
      );
    }
    final entries = _entries(board);
    if (filter.isNotEmpty) return _readOnly(context, board, entries);
    return ReorderableListView.builder(
      key: const Key('task-manager-list'),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xxxl),
      itemCount: entries.length,
      onReorderItem: (from, to) => _onReorder(board, entries, from, to),
      itemBuilder: (context, i) => switch (entries[i]) {
        _Header(:final band) => _BandHeader(
          key: ValueKey('band-${band?.key ?? 'unsorted'}'),
          band: band,
          count: band == null
              ? board.unsorted.length
              : board.bands[band]!.length,
          onSortAll: band == null && board.unsorted.length > 1
              ? () => _compare(context, board.unsorted)
              : null,
        ),
        _Placeholder(:final band) => _BandPlaceholder(
          key: ValueKey('band-empty-${band.key}'),
        ),
        _Task(:final note) => ReorderableDelayedDragStartListener(
          key: ValueKey(note.id),
          index: i,
          child: _TaskRow(
            note: note,
            onTap: () => _openNote(context, notes, note),
            onDone: () => _complete(context, note),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.band == null)
                  IconButton(
                    key: Key('compare-${note.id}'),
                    tooltip: context.l10n.sortByComparing,
                    icon: const Icon(Icons.compare_arrows),
                    color: context.palette.accent,
                    onPressed: () => _compare(context, [note]),
                  ),
                ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    label: context.l10n.dragToReorder,
                    child: Padding(
                      padding: const EdgeInsets.all(LeviathanSpacing.md),
                      child: Icon(
                        Icons.drag_handle,
                        key: Key('drag-${note.id}'),
                        size: LeviathanIconSize.md,
                        color: context.palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      },
    );
  }

  /// La stessa lista senza trascinamenti né confronti: con il filtro
  /// l'ordine si guarda soltanto.
  Widget _readOnly(
    BuildContext context,
    TaskBoard board,
    List<_Entry> entries,
  ) => ListView.builder(
    key: const Key('task-manager-list-filtered'),
    padding: const EdgeInsets.only(bottom: LeviathanSpacing.xxxl),
    itemCount: entries.length,
    itemBuilder: (context, i) => switch (entries[i]) {
      _Header(:final band) => _BandHeader(
        key: ValueKey('band-${band?.key ?? 'unsorted'}'),
        band: band,
        count: band == null ? board.unsorted.length : board.bands[band]!.length,
        // Il limite di "Ora" vale per tutti i task, non per una parte.
        showLimit: false,
      ),
      _Placeholder(:final band) => _BandPlaceholder(
        key: ValueKey('band-empty-${band.key}'),
        text: context.l10n.bandEmptyFiltered,
      ),
      _Task(:final note) => _TaskRow(
        key: ValueKey(note.id),
        note: note,
        onTap: () => _openNote(context, notes, note),
        onDone: () => _complete(context, note),
      ),
    },
  );
}

String bandLabel(AppLocalizations l, TaskBand? band) => switch (band) {
  null => l.bandUnsorted,
  TaskBand.now => l.bandNow,
  TaskBand.next => l.bandNext,
  TaskBand.later => l.bandLater,
};

class _BandHeader extends StatelessWidget {
  const _BandHeader({
    super.key,
    required this.band,
    required this.count,
    this.onSortAll,
    this.showLimit = true,
  });

  final TaskBand? band;
  final int count;
  final VoidCallback? onSortAll;

  /// Se mostrare il carico di "Ora" rispetto al limite consigliato.
  final bool showLimit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final limited = showLimit && band == TaskBand.now;
    final over = limited && count > nowLimit;
    final load = limited
        ? l.bandLoad(count, nowLimit)
        : count > 0
        ? '$count'
        : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        LeviathanSpacing.lg,
        LeviathanSpacing.sm,
        LeviathanSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                bandLabel(l, band).toUpperCase(),
                style: LeviathanText.caption.copyWith(
                  color: band == TaskBand.now ? palette.text : palette.muted,
                ),
              ),
              const SizedBox(width: LeviathanSpacing.sm),
              Text(
                load,
                key: limited ? const Key('now-load') : null,
                style: LeviathanText.caption.copyWith(
                  color: over ? palette.accent : palette.muted,
                ),
              ),
              const Spacer(),
              if (onSortAll != null)
                TextButton.icon(
                  key: const Key('sort-all'),
                  onPressed: onSortAll,
                  icon: const Icon(
                    Icons.compare_arrows,
                    size: LeviathanIconSize.sm,
                  ),
                  label: Text(l.sortAll),
                ),
            ],
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: LeviathanSpacing.xs),
              child: Text(
                l.nowOverLimit(nowLimit),
                key: const Key('now-over-limit'),
                style: LeviathanText.meta.copyWith(color: palette.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _BandPlaceholder extends StatelessWidget {
  const _BandPlaceholder({super.key, this.text});

  /// Di solito l'invito a trascinarci un task.
  final String? text;

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LeviathanSpacing.lg,
        vertical: LeviathanSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(LeviathanSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LeviathanRadii.cell),
          border: Border.all(
            color: muted.withValues(alpha: LeviathanOpacity.untagged),
          ),
        ),
        child: Text(
          text ?? context.l10n.bandEmpty,
          textAlign: TextAlign.center,
          style: LeviathanText.meta.copyWith(color: muted),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDone,
    this.meta,
    this.trailing,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Material(
      color: palette.background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: LeviathanSpacing.lg,
            right: LeviathanSpacing.xs,
          ),
          child: Row(
            children: [
              TagBar(note: note, height: LeviathanSizes.tagBarCompact),
              const SizedBox(width: LeviathanSpacing.sm),
              TaskCheck(note: note, onChanged: (_) => onDone()),
              const SizedBox(width: LeviathanSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: LeviathanSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.displayTitle(l.untitled),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: taskTitleStyle(
                          context,
                          note,
                          LeviathanText.title.copyWith(color: palette.text),
                        ),
                      ),
                      if (meta != null)
                        Text(
                          meta!,
                          style: LeviathanText.meta.copyWith(
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneTab extends StatelessWidget {
  const _DoneTab({required this.notes, required this.filter});

  final NotesController notes;
  final Set<GroupFilter> filter;

  static DateTime _when(Note note) => note.doneAt ?? note.updated;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = [
      for (final n in notes.notes)
        if (n.isTask && n.done && inAnyGroup(n, filter)) n,
    ]..sort((a, b) => _when(b).compareTo(_when(a)));
    if (done.isEmpty) {
      return _Message(
        icon: Icons.task_alt,
        text: filter.isEmpty
            ? l.taskManagerDoneEmpty
            : l.taskManagerFilteredDoneEmpty,
      );
    }
    final now = DateTime.now();
    final items = <Object>[];
    String? section;
    for (final note in done) {
      final s = dateSection(l, _when(note), now);
      if (s != section) items.add(section = s);
      items.add(note);
    }
    return ListView.builder(
      key: const Key('task-manager-done'),
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xxxl),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        final String title => Padding(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.lg,
            LeviathanSpacing.lg,
            LeviathanSpacing.lg,
            LeviathanSpacing.xs,
          ),
          child: Text(
            title.toUpperCase(),
            style: LeviathanText.caption.copyWith(color: context.palette.muted),
          ),
        ),
        final Note note => _TaskRow(
          key: ValueKey(note.id),
          note: note,
          meta: formatRelative(l, _when(note), now),
          onTap: () => _openNote(context, notes, note),
          // Tolta la spunta torna nella sua fascia, al suo posto.
          onDone: () => notes.setDone(note, false),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.muted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: LeviathanIconSize.xl, color: muted),
            const SizedBox(height: LeviathanSpacing.lg),
            Text(
              text,
              textAlign: TextAlign.center,
              style: LeviathanText.body.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il segno di un filtro: il pallino del tag o l'omino della fonte.
class _FilterMarker extends StatelessWidget {
  const _FilterMarker(this.filter);

  final GroupFilter filter;

  @override
  Widget build(BuildContext context) => switch (filter.by) {
    NoteGrouping.tag => CircleAvatar(
      backgroundColor: Tags.colorOf(filter.name),
      radius: LeviathanSpacing.xs,
    ),
    NoteGrouping.source => Icon(
      Icons.person_outline,
      size: LeviathanIconSize.sm,
      color: context.palette.muted,
    ),
  };
}

/// La striscia sopra le liste quando c'è un filtro: cosa si sta guardando,
/// che l'ordine è in sola lettura e come tornare a tutti i task.
class _FilterBanner extends StatelessWidget {
  const _FilterBanner({required this.filter, required this.onClear});

  final Set<GroupFilter> filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Container(
      key: const Key('task-filter-banner'),
      color: palette.surface,
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        LeviathanSpacing.xs,
        LeviathanSpacing.xs,
        LeviathanSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: LeviathanSpacing.md,
                  runSpacing: LeviathanSpacing.xxs,
                  children: [
                    for (final f in _sorted(filter))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FilterMarker(f),
                          const SizedBox(width: LeviathanSpacing.xs),
                          Text(
                            f.name,
                            style: LeviathanText.meta.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.text,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: LeviathanSpacing.xxs),
                Text(
                  l.taskFilterReadOnly,
                  style: LeviathanText.tiny.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('task-filter-clear'),
            tooltip: l.taskFilterClear,
            icon: const Icon(Icons.close, size: LeviathanIconSize.md),
            color: palette.muted,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

/// Prima i tag e poi le fonti, ognuno in ordine alfabetico.
List<GroupFilter> _sorted(Set<GroupFilter> filter) => [...filter]
  ..sort((a, b) {
    final byKind = a.by.index.compareTo(b.by.index);
    if (byKind != 0) return byKind;
    return foldText(a.name).compareTo(foldText(b.name));
  });

/// Il foglio che sceglie il filtro: i tag e le fonti dei task, con quanti ce
/// ne sono da fare (in cima chi ne ha di più). Se ne possono spuntare quanti
/// si vuole; restituisce la scelta con "Applica", un insieme vuoto con
/// "Togli il filtro", null se lo si chiude senza scegliere.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.notes, required this.selected});

  final List<Note> notes;
  final Set<GroupFilter> selected;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<GroupFilter> _chosen = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    List<NoteGroup> named(NoteGrouping by) => [
      for (final g in groupNotes(
        widget.notes,
        by,
        kind: NoteKind.task,
        alphabetical: SettingsScope.alphabeticalGroups(context),
      ))
        if (g.name != null) g,
    ];
    final tags = named(NoteGrouping.tag);
    final sources = named(NoteGrouping.source);

    Widget title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        LeviathanSpacing.lg,
        LeviathanSpacing.lg,
        LeviathanSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: LeviathanText.caption.copyWith(color: palette.muted),
      ),
    );

    Widget option(NoteGroup g, NoteGrouping by) {
      final filter = GroupFilter(by, g.name!);
      final chosen = _chosen.contains(filter);
      final open = g.openTasks;
      return ListTile(
        key: Key('task-filter-${by.name}-${g.name}'),
        leading: SizedBox(
          width: LeviathanIconSize.md,
          child: Center(child: _FilterMarker(filter)),
        ),
        title: Text(
          g.name!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LeviathanText.body.copyWith(
            color: palette.text,
            fontWeight: chosen ? FontWeight.w600 : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              open == 0 ? l.allDone : l.openCount(open),
              style: LeviathanText.meta.copyWith(
                color: open > 0 ? palette.accent : palette.muted,
              ),
            ),
            const SizedBox(width: LeviathanSpacing.sm),
            Icon(
              chosen ? Icons.check_box : Icons.check_box_outline_blank,
              size: LeviathanIconSize.md,
              color: chosen ? palette.accent : palette.muted,
            ),
          ],
        ),
        onTap: () => setState(
          () => chosen ? _chosen.remove(filter) : _chosen.add(filter),
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * LeviathanSizes.sheetHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (tags.isEmpty && sources.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(LeviathanSpacing.lg),
                      child: Text(
                        l.taskFilterNoGroups,
                        style: LeviathanText.meta.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ),
                  if (tags.isNotEmpty) ...[
                    title(l.byTag),
                    for (final g in tags) option(g, NoteGrouping.tag),
                  ],
                  if (sources.isNotEmpty) ...[
                    title(l.bySource),
                    for (final g in sources) option(g, NoteGrouping.source),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LeviathanSpacing.lg,
                LeviathanSpacing.sm,
                LeviathanSpacing.lg,
                LeviathanSpacing.md,
              ),
              child: Row(
                children: [
                  // Con caratteri grandi si accorcia invece di sforare.
                  Flexible(
                    child: TextButton(
                      key: const Key('task-filter-none'),
                      onPressed: () =>
                          Navigator.pop(context, const <GroupFilter>{}),
                      child: Text(
                        l.taskFilterClear,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: LeviathanSpacing.sm),
                  const Spacer(),
                  FilledButton(
                    key: const Key('task-filter-apply'),
                    onPressed: () => Navigator.pop(context, {..._chosen}),
                    child: Text(l.apply),
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
