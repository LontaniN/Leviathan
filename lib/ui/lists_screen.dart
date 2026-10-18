import 'package:flutter/material.dart';

import '../model/markdown.dart';
import '../model/note.dart';
import '../model/note_groups.dart';
import '../model/search.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'note_screen.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Cosa mostra la schermata degli elenchi: i task o le note.
enum ListsView { tasks, notes }

/// Task e note del workspace in un'unica schermata: in alto si sceglie quale
/// elenco vedere, sotto se raggrupparlo per tag o per fonte. Fra i task la
/// tendina in alto a destra mostra tutti, solo quelli da fare o solo i fatti.
///
/// Ogni tag (o fonte) è un riquadro, come le caselle del calendario, così
/// anche con molte note la schermata resta corta. Toccando un riquadro si
/// apre l'elenco dei suoi task o delle sue note, dal più recente.
class ListsScreen extends StatefulWidget {
  const ListsScreen({
    super.key,
    required this.notes,
    this.initialView = ListsView.tasks,
  });

  final NotesController notes;
  final ListsView initialView;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late ListsView _view = widget.initialView;
  NoteGrouping _grouping = NoteGrouping.tag;
  TaskFilter _filter = TaskFilter.task;

  bool get _tasks => _view == ListsView.tasks;

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
        final groups = groupNotes(
          all,
          _grouping,
          tasks: _tasks,
          filter: _filter,
        );
        final hasTasks = all.any((n) => n.isTask);
        final String summary;
        if (_tasks) {
          summary = _taskSummary(all.where((n) => n.isTask), _filter);
        } else {
          final count = all.where((n) => !n.isTask).length;
          summary = count == 1 ? '1 nota' : '$count note';
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.palette.background,
            title: _ViewToggle(
              view: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
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
                  segments: const [
                    ButtonSegment(
                      value: NoteGrouping.tag,
                      icon: Icon(
                        Icons.sell_outlined,
                        size: LeviathanIconSize.sm,
                      ),
                      label: Text('Per tag'),
                    ),
                    ButtonSegment(
                      value: NoteGrouping.source,
                      icon: Icon(
                        Icons.person_outline,
                        size: LeviathanIconSize.sm,
                      ),
                      label: Text('Per fonte'),
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
                child: groups.isEmpty
                    ? _Empty(
                        !_tasks
                            ? 'Nessuna nota ancora: scrivine una dalla home.'
                            : hasTasks
                            ? _emptyFiltered(_filter)
                            : 'Nessun task ancora: scrivine uno scegliendo '
                                  '"Task" nell\'editor.',
                      )
                    : _GroupGrid(
                        key: Key(_tasks ? 'task-grid' : 'note-grid'),
                        summary: summary,
                        groups: groups,
                        grouping: _grouping,
                        tasks: _tasks,
                        filter: _filter,
                        onOpen: _openGroup,
                      ),
              ),
            ],
          ),
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
  });

  final String summary;
  final List<NoteGroup> groups;
  final NoteGrouping grouping;
  final bool tasks;
  final TaskFilter filter;
  final ValueChanged<String?> onOpen;

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

String _groupName(String? name, NoteGrouping grouping) =>
    name ?? (grouping == NoteGrouping.tag ? 'Senza tag' : 'Senza fonte');

/// Il riquadro di un tag (o fonte): nome, quanti elementi ha e i titoli più
/// recenti, quanti ne stanno.
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.grouping,
    required this.tasks,
    required this.filter,
    required this.onTap,
  });

  final NoteGroup group;
  final NoteGrouping grouping;
  final bool tasks;

  /// Il filtro già applicato a [group]: decide il conteggio in alto.
  final TaskFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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
      TaskFilter.fatto => '${group.notes.length} fatti',
      _ => open == 0 ? 'fatti' : '$open da fare',
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
                  _groupName(group.name, grouping),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LeviathanText.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: group.name == null ? palette.muted : palette.text,
                  ),
                ),
                const SizedBox(height: LeviathanSpacing.xxs),
                Expanded(
                  child: _Titles([for (final n in shown) n.displayTitle]),
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
    this.initialView = ListsView.notes,
    this.initialFilter = TaskFilter.task,
  });

  final NotesController notes;

  /// Il tag o la fonte; null per chi non ne ha.
  final String? name;
  final NoteGrouping grouping;
  final ListsView initialView;
  final TaskFilter initialFilter;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late ListsView _view = widget.initialView;
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
    final tasks = _view == ListsView.tasks;
    final query = SearchQuery(text: _query.text);
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        // Ricalcolato a ogni modifica: una nota che perde il tag esce.
        final items = widget.notes.notes
            .where(
              (n) =>
                  n.isTask == tasks &&
                  (!tasks || _filter.matches(n)) &&
                  groupsOf(n, grouping).contains(name),
            )
            .toList();
        // La ricerca resta dentro il gruppo, così vale anche per "Senza
        // tag" e "Senza fonte".
        final hits = query.terms.isEmpty
            ? [for (final n in items) SearchHit(n, 0, plainText(n.body.trim()))]
            : searchNotes(items, query);
        hits.sort((a, b) => b.note.created.compareTo(a.note.created));
        final found = hits.map((h) => h.note);
        final String summary;
        if (tasks) {
          summary = _taskSummary(found, _filter);
        } else {
          summary = hits.length == 1 ? '1 nota' : '${hits.length} note';
        }
        final where = grouping == NoteGrouping.tag
            ? (name == null ? 'fra le note senza tag' : 'in questo tag')
            : (name == null ? 'fra le note senza fonte' : 'in questa fonte');
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
                      hintText: 'Cerca $where',
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
                          _groupName(name, grouping),
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
                      tooltip: 'Chiudi la ricerca',
                      icon: const Icon(Icons.close),
                      onPressed: _closeSearch,
                    )
                  : IconButton(
                      key: const Key('group-search-button'),
                      tooltip: 'Cerca $where',
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
                            ? 'Nessun risultato $where.'
                            : !tasks
                            ? 'Nessuna nota qui.'
                            : _filter == TaskFilter.task
                            ? 'Nessun task qui.'
                            : _emptyFiltered(_filter),
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
String _taskSummary(Iterable<Note> tasks, TaskFilter filter) {
  final open = tasks.where((n) => n.isOpenTask).length;
  return switch (filter) {
    TaskFilter.task => '${tasks.length} task · $open da fare',
    TaskFilter.aperto => open == 1 ? '1 task da fare' : '$open task da fare',
    TaskFilter.fatto =>
      tasks.length == 1 ? '1 task fatto' : '${tasks.length} task fatti',
  };
}

String _emptyFiltered(TaskFilter filter) => switch (filter) {
  TaskFilter.task => 'Nessun task.',
  TaskFilter.aperto => 'Nessun task da fare.',
  TaskFilter.fatto => 'Nessun task fatto.',
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
                  TaskFilter.task => 'Tutte',
                  TaskFilter.aperto => 'Da fare',
                  TaskFilter.fatto => 'Fatte',
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

/// La scelta fra task e note.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final ListsView view;
  final ValueChanged<ListsView> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ListsView>(
      key: const Key('view-toggle'),
      segments: const [
        ButtonSegment(
          value: ListsView.tasks,
          icon: Icon(Icons.checklist, size: LeviathanIconSize.sm),
          label: Text('Task'),
        ),
        ButtonSegment(
          value: ListsView.notes,
          icon: Icon(Icons.description_outlined, size: LeviathanIconSize.sm),
          label: Text('Note'),
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
