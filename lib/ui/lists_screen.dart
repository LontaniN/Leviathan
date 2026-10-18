import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import '../model/note_groups.dart';
import '../model/search.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'tag_color_sheet.dart';
import 'theme.dart';

/// Task, note e conoscenza del workspace in un'unica schermata: in alto si
/// sceglie quale elenco vedere, sotto se raggrupparlo per tag o per fonte.
/// Le note di conoscenza non stanno fra le note: ogni elenco risponde a una
/// domanda diversa (cosa c'è da fare, cos'è successo, cosa so). Fra i task la
/// tendina in alto a destra mostra tutti, solo quelli da fare o solo i fatti.
///
/// Ogni tag (o fonte) è un riquadro, come le caselle del calendario, così
/// anche con molte note la schermata resta corta. Toccando un riquadro si
/// apre l'elenco dei suoi task o delle sue note, dal più recente.
///
/// La barra in cima cerca solo nell'elenco scelto (e, fra i task, solo in
/// quelli mostrati dalla tendina): mentre si scrive i riquadri lasciano il
/// posto ai risultati.
class ListsScreen extends StatefulWidget {
  const ListsScreen({
    super.key,
    required this.notes,
    this.initialView = NoteKind.task,
  });

  final NotesController notes;
  final NoteKind initialView;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late NoteKind _view = widget.initialView;
  NoteGrouping _grouping = NoteGrouping.tag;
  TaskFilter _filter = TaskFilter.aperto;
  final _query = TextEditingController();

  bool get _tasks => _view == NoteKind.task;

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

  void _openNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: note.id, notes: widget.notes),
      ),
    );
  }

  void _openGroup(String? name) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupScreen(
          notes: widget.notes,
          name: name,
          grouping: _grouping,
          initialView: _view,
          initialFilter: _filter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        final all = widget.notes.notes;
        final groups = groupNotes(all, _grouping, kind: _view, filter: _filter);
        final l = context.l10n;
        final hasTasks = all.any((n) => n.isTask);
        final summary = _tasks
            ? _taskSummary(l, all.where((n) => n.isTask), _filter)
            : l.noteCount(all.where((n) => n.kind == _view).length);
        final query = SearchQuery(text: _query.text);
        final searching = query.terms.isNotEmpty;
        final where = switch (_view) {
          NoteKind.task => l.whereTasks,
          NoteKind.note => l.whereNotes,
          NoteKind.knowledge => l.whereKnowledge,
        };
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.palette.background,
            title: Text(l.tasksAndNotes),
            actions: [
              if (_tasks)
                _TaskFilterMenu(
                  filter: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContextSearchField(
                controller: _query,
                hint: l.searchWhere(where),
              ),
              // Sotto la barra e a tutta larghezza: tre voci non ci stanno
              // accanto alla tendina dei task.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LeviathanSpacing.lg,
                  0,
                  LeviathanSpacing.lg,
                  LeviathanSpacing.sm,
                ),
                child: _ViewToggle(
                  view: _view,
                  onChanged: (v) => setState(() => _view = v),
                ),
              ),
              // Con la ricerca i risultati sono un elenco unico: raggruppare
              // non serve.
              if (!searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LeviathanSpacing.lg,
                    0,
                    LeviathanSpacing.lg,
                    LeviathanSpacing.sm,
                  ),
                  // A tutta larghezza: ogni metà ha il suo spazio anche con
                  // caratteri grandi.
                  child: SegmentedButton<NoteGrouping>(
                    key: const Key('grouping-toggle'),
                    segments: [
                      ButtonSegment(
                        value: NoteGrouping.tag,
                        icon: const Icon(
                          Icons.sell_outlined,
                          size: LeviathanIconSize.sm,
                        ),
                        label: Text(l.byTag),
                      ),
                      ButtonSegment(
                        value: NoteGrouping.source,
                        icon: const Icon(
                          Icons.person_outline,
                          size: LeviathanIconSize.sm,
                        ),
                        label: Text(l.bySource),
                      ),
                    ],
                    selected: {_grouping},
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelectionChanged: (s) =>
                        setState(() => _grouping = s.first),
                  ),
                ),
              Expanded(
                child: searching
                    ? _SearchResults(
                        notes: widget.notes,
                        hits: searchNotes([
                          for (final n in all)
                            if (n.kind == _view &&
                                (!_tasks || _filter.matches(n)))
                              n,
                        ], query),
                        query: query,
                        tasks: _tasks,
                        filter: _filter,
                        empty: l.noResultsWhere(where),
                        onOpen: _openNote,
                      )
                    : groups.isEmpty
                    ? _Empty(
                        _view == NoteKind.note
                            ? l.listsNoNotes
                            : _view == NoteKind.knowledge
                            ? l.listsNoKnowledge
                            : hasTasks
                            ? _emptyFiltered(l, _filter)
                            : l.listsNoTasks,
                      )
                    : _GroupGrid(
                        key: Key('${_view.name}-grid'),
                        summary: summary,
                        groups: groups,
                        grouping: _grouping,
                        tasks: _tasks,
                        filter: _filter,
                        onOpen: _openGroup,
                        onTagLongPress: (tag) =>
                            showTagColorSheet(context, widget.notes, tag),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// La barra di ricerca semplificata: solo testo, senza filtri, dentro
/// l'elenco scelto.
class _ContextSearchField extends StatelessWidget {
  const _ContextSearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        0,
        LeviathanSpacing.lg,
        LeviathanSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(LeviathanRadii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: LeviathanSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: LeviathanIconSize.md,
                color: palette.muted,
              ),
              Expanded(
                child: TextField(
                  key: const Key('lists-search'),
                  controller: controller,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: LeviathanSpacing.sm,
                      vertical: LeviathanSpacing.md,
                    ),
                  ),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  key: const Key('lists-search-clear'),
                  tooltip: context.l10n.clear,
                  icon: const Icon(Icons.close, size: LeviathanIconSize.md),
                  onPressed: controller.clear,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// I risultati della ricerca nell'elenco scelto, dai più pertinenti.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.notes,
    required this.hits,
    required this.query,
    required this.tasks,
    required this.filter,
    required this.empty,
    required this.onOpen,
  });

  final NotesController notes;
  final List<SearchHit> hits;
  final SearchQuery query;
  final bool tasks;
  final TaskFilter filter;

  /// Il testo da mostrare se non si trova niente.
  final String empty;
  final ValueChanged<Note> onOpen;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) return _Empty(empty);
    final l = context.l10n;
    final summary = tasks
        ? _taskSummary(l, hits.map((h) => h.note), filter)
        : l.noteCount(hits.length);
    return ListView.builder(
      key: const Key('lists-search-results'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
      itemCount: hits.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return SectionTitle(summary);
        return NoteResultTile(
          hit: hits[i - 1],
          terms: query.terms,
          onTap: onOpen,
          onToggleDone: notes.setDone,
          onTogglePin: notes.setPinned,
          divider: i < hits.length,
        );
      },
    );
  }
}

/// Il totale in cima e sotto un riquadro per tag (o fonte).
class _GroupGrid extends StatelessWidget {
  const _GroupGrid({
    super.key,
    required this.summary,
    required this.groups,
    required this.grouping,
    required this.tasks,
    required this.filter,
    required this.onOpen,
    required this.onTagLongPress,
  });

  final String summary;
  final List<NoteGroup> groups;
  final NoteGrouping grouping;
  final bool tasks;
  final TaskFilter filter;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String> onTagLongPress;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: LeviathanSpacing.lg,
            vertical: LeviathanSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              summary,
              style: LeviathanText.meta.copyWith(color: context.palette.muted),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.sm,
            LeviathanSpacing.xs,
            LeviathanSpacing.sm,
            LeviathanSpacing.xl,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              childAspectRatio: LeviathanSizes.groupTileAspect,
            ),
            itemCount: groups.length,
            itemBuilder: (context, i) => _GroupTile(
              group: groups[i],
              grouping: grouping,
              tasks: tasks,
              filter: filter,
              onTap: () => onOpen(groups[i].name),
              onLongPress: switch (groups[i].name) {
                final name? when grouping == NoteGrouping.tag =>
                  () => onTagLongPress(name),
                _ => null,
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Il segno di un gruppo: il pallino del tag o l'omino della fonte.
class _GroupMarker extends StatelessWidget {
  const _GroupMarker({required this.name, required this.grouping});

  final String? name;
  final NoteGrouping grouping;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    final isTag = grouping == NoteGrouping.tag;
    if (name != null && isTag) {
      return CircleAvatar(
        backgroundColor: Tags.colorOf(name),
        radius: LeviathanSpacing.xs,
      );
    }
    return Icon(
      name == null
          ? (isTag ? Icons.label_off_outlined : Icons.person_off_outlined)
          : Icons.person_outline,
      size: LeviathanIconSize.sm,
      color: context.palette.muted,
    );
  }
}

String _groupName(AppLocalizations l, String? name, NoteGrouping grouping) =>
    name ?? (grouping == NoteGrouping.tag ? l.noTag : l.noSource);

/// Il riquadro di un tag (o fonte): nome, quanti elementi ha e i titoli più
/// recenti, quanti ne stanno.
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.grouping,
    required this.tasks,
    required this.filter,
    required this.onTap,
    this.onLongPress,
  });

  final NoteGroup group;
  final NoteGrouping grouping;
  final bool tasks;

  /// Il filtro già applicato a [group]: decide il conteggio in alto.
  final TaskFilter filter;
  final VoidCallback onTap;

  /// Sui tag apre la scelta del colore.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = context.l10n;
    final radius = BorderRadius.circular(LeviathanRadii.md);
    final open = group.openTasks;
    // Con tutti i task, prima quelli da fare e poi i fatti.
    final shown = tasks && filter == TaskFilter.task
        ? [
            ...group.notes.where((n) => n.isOpenTask),
            ...group.notes.where((n) => !n.isOpenTask),
          ]
        : group.notes;
    final count = switch (filter) {
      _ when !tasks => '${group.notes.length}',
      TaskFilter.fatto => l.doneCount(group.notes.length),
      _ => open == 0 ? l.allDone : l.openCount(open),
    };
    return Padding(
      padding: const EdgeInsets.all(LeviathanSpacing.xxs),
      child: Material(
        // Un velo del colore del tag: i riquadri si riconoscono a colpo
        // d'occhio, come le barrette accanto alle note.
        color: group.name != null && grouping == NoteGrouping.tag
            ? Color.alphaBlend(
                Tags.colorOf(group.name!)
                    .withValues(alpha: LeviathanOpacity.groupTint),
                palette.surface,
              )
            : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(LeviathanSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _GroupMarker(name: group.name, grouping: grouping),
                    const SizedBox(width: LeviathanSpacing.xs),
                    // Con caratteri grandi si accorcia invece di sforare.
                    Expanded(
                      child: Text(
                        count,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LeviathanText.tiny.copyWith(
                          color: tasks && open > 0
                              ? palette.accent
                              : palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LeviathanSpacing.xs),
                Text(
                  _groupName(l, group.name, grouping),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LeviathanText.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: group.name == null ? palette.muted : palette.text,
                  ),
                ),
                const SizedBox(height: LeviathanSpacing.xxs),
                Expanded(
                  child: _Titles([
                    for (final n in shown) n.displayTitle(l.untitled),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// I titoli, uno per riga, quanti ne stanno nello spazio dato.
class _Titles extends StatelessWidget {
  const _Titles(this.titles);

  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    // Come fa Text: lo stile eredita quello di default (interlinea compresa),
    // altrimenti la riga misurata è più bassa di quella disegnata.
    final style = DefaultTextStyle.of(context).style
        .merge(LeviathanText.tiny)
        .copyWith(color: context.palette.muted);
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final lineHeight = painter.height;
    painter.dispose();
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = (constraints.maxHeight / lineHeight).floor();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final title in titles.take(fits))
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: style,
              ),
          ],
        );
      },
    );
  }
}

/// La schermata di un tag o di una fonte: i suoi task o le sue note, dal
/// più recente al più vecchio. In alto si passa dagli uni alle altre; la
/// lente cerca solo dentro questo tag (o fonte), anche in "Senza tag".
///
/// Si apre dai riquadri di [ListsScreen] e toccando un tag o una fonte in
/// una nota.
class GroupScreen extends StatefulWidget {
  const GroupScreen({
    super.key,
    required this.notes,
    required this.name,
    required this.grouping,
    this.initialView = NoteKind.note,
    this.initialFilter = TaskFilter.aperto,
  });

  final NotesController notes;

  /// Il tag o la fonte; null per chi non ne ha.
  final String? name;
  final NoteGrouping grouping;
  final NoteKind initialView;
  final TaskFilter initialFilter;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late NoteKind _view = widget.initialView;
  late TaskFilter _filter = widget.initialFilter;

  bool _searching = false;
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

  void _closeSearch() {
    _query.clear();
    setState(() => _searching = false);
  }

  void _open(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: note.id, notes: widget.notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final grouping = widget.grouping;
    final tasks = _view == NoteKind.task;
    final query = SearchQuery(text: _query.text);
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        // Ricalcolato a ogni modifica: una nota che perde il tag esce.
        final items = widget.notes.notes
            .where(
              (n) =>
                  n.kind == _view &&
                  (!tasks || _filter.matches(n)) &&
                  groupsOf(n, grouping).contains(name),
            )
            .toList();
        // La ricerca resta dentro il gruppo, così vale anche per "Senza
        // tag" e "Senza fonte".
        final hits = query.terms.isEmpty
            ? [
                for (final n in items)
                  SearchHit(n, 0, () => plainText(n.body.trim())),
              ]
            : searchNotes(items, query);
        hits.sort((a, b) => b.note.created.compareTo(a.note.created));
        final found = hits.map((h) => h.note);
        final l = context.l10n;
        final summary = tasks
            ? _taskSummary(l, found, _filter)
            : l.noteCount(hits.length);
        final where = grouping == NoteGrouping.tag
            ? (name == null ? l.whereUntagged : l.whereTag)
            : (name == null ? l.whereUnsourced : l.whereSource);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.palette.background,
            title: _searching
                ? TextField(
                    key: const Key('group-search'),
                    controller: _query,
                    autofocus: true,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.searchWhere(where),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  )
                : Row(
                    children: [
                      _GroupMarker(name: name, grouping: grouping),
                      const SizedBox(width: LeviathanSpacing.sm),
                      Expanded(
                        child: Text(
                          _groupName(l, name, grouping),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
            actions: [
              if (tasks && !_searching)
                _TaskFilterMenu(
                  filter: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              _searching
                  ? IconButton(
                      key: const Key('group-search-close'),
                      tooltip: l.closeSearch,
                      icon: const Icon(Icons.close),
                      onPressed: _closeSearch,
                    )
                  : IconButton(
                      key: const Key('group-search-button'),
                      tooltip: l.searchWhere(where),
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(() => _searching = true),
                    ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LeviathanSpacing.lg,
                  0,
                  LeviathanSpacing.lg,
                  LeviathanSpacing.sm,
                ),
                child: _ViewToggle(
                  view: _view,
                  onChanged: (v) => setState(() => _view = v),
                ),
              ),
              Expanded(
                child: hits.isEmpty
                    ? _Empty(
                        items.isNotEmpty
                            ? l.noResultsWhere(where)
                            : _view == NoteKind.note
                            ? l.noNotesHere
                            : _view == NoteKind.knowledge
                            ? l.noKnowledgeHere
                            : _filter == TaskFilter.task
                            ? l.noTasksHere
                            : _emptyFiltered(l, _filter),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(
                          bottom: LeviathanSpacing.xl,
                        ),
                        itemCount: hits.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) return SectionTitle(summary);
                          return NoteResultTile(
                            hit: hits[i - 1],
                            terms: query.terms,
                            onTap: _open,
                            onToggleDone: widget.notes.setDone,
                            onTogglePin: widget.notes.setPinned,
                            divider: i < hits.length,
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

/// Il riassunto in cima a un elenco di [tasks], secondo il filtro.
String _taskSummary(
  AppLocalizations l,
  Iterable<Note> tasks,
  TaskFilter filter,
) {
  final open = tasks.where((n) => n.isOpenTask).length;
  return switch (filter) {
    TaskFilter.task => l.taskSummary(tasks.length, open),
    TaskFilter.aperto => l.openTaskCount(open),
    TaskFilter.fatto => l.doneTaskCount(tasks.length),
  };
}

String _emptyFiltered(AppLocalizations l, TaskFilter filter) =>
    switch (filter) {
      TaskFilter.task => l.noTasks,
      TaskFilter.aperto => l.noOpenTasks,
      TaskFilter.fatto => l.noDoneTasks,
    };

/// La tendina in alto a destra che sceglie quali task mostrare.
class _TaskFilterMenu extends StatelessWidget {
  const _TaskFilterMenu({required this.filter, required this.onChanged});

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: LeviathanSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskFilter>(
          key: const Key('task-filter'),
          value: filter,
          isDense: true,
          dropdownColor: context.palette.surface,
          borderRadius: BorderRadius.circular(LeviathanRadii.md),
          icon: Icon(
            Icons.expand_more,
            size: LeviathanIconSize.md,
            color: context.palette.muted,
          ),
          style: LeviathanText.meta.copyWith(color: context.palette.text),
          items: [
            for (final f in TaskFilter.values)
              DropdownMenuItem(
                value: f,
                child: Text(switch (f) {
                  TaskFilter.task => context.l10n.filterAll,
                  TaskFilter.aperto => context.l10n.filterOpen,
                  TaskFilter.fatto => context.l10n.filterDone,
                }),
              ),
          ],
          onChanged: (f) {
            if (f != null) onChanged(f);
          },
        ),
      ),
    );
  }
}

/// La scelta fra task, note e conoscenza.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final NoteKind view;
  final ValueChanged<NoteKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<NoteKind>(
      key: const Key('view-toggle'),
      segments: [
        ButtonSegment(
          value: NoteKind.task,
          icon: const Icon(Icons.checklist, size: LeviathanIconSize.sm),
          label: Text(context.l10n.viewTasks),
        ),
        ButtonSegment(
          value: NoteKind.note,
          icon: const Icon(
            Icons.description_outlined,
            size: LeviathanIconSize.sm,
          ),
          label: Text(context.l10n.viewNotes),
        ),
        ButtonSegment(
          value: NoteKind.knowledge,
          icon: const Icon(Icons.lightbulb_outline, size: LeviathanIconSize.sm),
          label: Text(context.l10n.viewKnowledge),
        ),
      ],
      selected: {view},
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelectionChanged: (s) => onChanged(s.first),
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
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted),
        ),
      ),
    );
  }
}
