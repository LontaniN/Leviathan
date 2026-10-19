import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/graph_layout_store.dart';
import '../graph/force_layout.dart';
import '../graph/graph_view.dart';
import '../l10n/l10n.dart';
import '../model/graph.dart';
import '../model/search.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'chip_input.dart';
import 'note_screen.dart';
import 'tag_color_sheet.dart';
import 'theme.dart';

/// Il grafo delle note del workspace: ogni nodo è una nota del colore del
/// suo primo tag; le note con tag in comune sono collegate e si attraggono.
///
/// Pizzico per lo zoom, trascinamento per spostarsi o spostare un nodo.
/// Un tocco seleziona una nota, un secondo tocco la apre.
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key, required this.notes, required this.store});

  final NotesController notes;
  final GraphLayoutStore store;

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  late NoteGraph _graph;
  late ForceLayout _layout;
  late final Ticker _ticker = createTicker(_onTick);

  GraphViewport _view = const GraphViewport(scale: 0.8);
  bool _needsFit = true;
  Size _size = Size.zero;

  int _selected = -1;
  List<String> _filterTags = [];
  List<String> _filterSources = [];
  Set<String>? _matching;

  // Gesti in corso.
  int _dragNode = -1;
  GraphViewport _gestureStart = const GraphViewport();
  Offset _worldAtFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _rebuild(previous: widget.store.read());
    widget.notes.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    widget.notes.removeListener(_onNotesChanged);
    _ticker.dispose();
    _savePositions();
    _layout.dispose();
    super.dispose();
  }

  /// Ricostruisce il grafo dalle note tenendo le posizioni già note.
  void _rebuild({required Map<String, Offset> previous}) {
    _graph = NoteGraph.build(widget.notes.notes);
    final seed = seedPositions(_graph, previous);
    _layout = ForceLayout(
      _graph.nodes.length,
      [for (final e in _graph.edges) (a: e.a, b: e.b, weight: e.weight)],
      x: seed.x,
      y: seed.y,
    );
    final n = _graph.nodes.length;
    // Tutto già al suo posto: basta un assestamento leggero.
    _layout.alpha = n == 0
        ? 0
        : seed.known == n
        ? 0.05
        : seed.known > 0
        ? 0.4
        : 1;
    if (seed.known == 0) {
      // Primo avvio: si fa il grosso del lavoro subito (max ~300 ms), così
      // il grafo non compare come un gomitolo.
      final watch = Stopwatch()..start();
      while (_layout.isRunning && watch.elapsedMilliseconds < 300) {
        _layout.tick();
      }
    }
    _applyFilter();
    _wake();
  }

  void _onNotesChanged() {
    final positions = _currentPositions();
    final selectedId = _selected >= 0 ? _graph.nodes[_selected].note.id : null;
    _ticker.stop();
    // Il vecchio layout si libera dopo che il disegno è passato al nuovo.
    final old = _layout;
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    setState(() {
      _rebuild(previous: positions);
      _selected = selectedId == null
          ? -1
          : _graph.nodes.indexWhere((n) => n.note.id == selectedId);
    });
  }

  Map<String, Offset> _currentPositions() => {
    for (var i = 0; i < _graph.nodes.length; i++)
      _graph.nodes[i].note.id: Offset(_layout.x[i], _layout.y[i]),
  };

  void _savePositions() {
    if (_graph.nodes.isEmpty) return;
    widget.store.write(_currentPositions());
  }

  void _wake() {
    if (_layout.isRunning && !_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration _) {
    if (!_layout.tick()) {
      _ticker.stop();
      _savePositions();
    }
  }

  void _applyFilter() {
    if (_filterTags.isEmpty && _filterSources.isEmpty) {
      _matching = null;
      return;
    }
    final hits = searchNotes(
      widget.notes.notes,
      SearchQuery(tags: _filterTags, sources: _filterSources),
    );
    _matching = {for (final h in hits) h.note.id};
  }

  void _fit() {
    if (_size.isEmpty || _graph.nodes.isEmpty) return;
    final only = _matching == null
        ? null
        : [
            for (var i = 0; i < _graph.nodes.length; i++)
              if (_matching!.contains(_graph.nodes[i].note.id)) i,
          ];
    final bounds = boundsOf(
      _layout.x,
      _layout.y,
      only != null && only.isNotEmpty ? only : null,
    );
    setState(() => _view = GraphViewport.fit(bounds, _size));
  }

  /// Per i test: dove si trova sullo schermo il nodo della nota [noteId].
  @visibleForTesting
  Offset debugNodeScreenPosition(String noteId) {
    final i = _graph.nodes.indexWhere((n) => n.note.id == noteId);
    return _view.toScreen(Offset(_layout.x[i], _layout.y[i]), _size);
  }

  // --- Gesti -------------------------------------------------------------

  void _onScaleStart(ScaleStartDetails d) {
    _gestureStart = _view;
    _worldAtFocal = _view.toWorld(d.localFocalPoint, _size);
    if (d.pointerCount == 1) {
      final hit = hitTestNode(
        _layout.x,
        _layout.y,
        _graph.nodes,
        _worldAtFocal,
        _view.scale,
      );
      if (hit >= 0) {
        _dragNode = hit;
        _layout.pinned = hit;
        setState(() => _selected = hit);
        _layout.reheat();
        _wake();
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_dragNode >= 0) {
      final world = _view.toWorld(d.localFocalPoint, _size);
      _layout.x[_dragNode] = world.dx;
      _layout.y[_dragNode] = world.dy;
      _layout.reheat();
      _wake();
      return;
    }
    setState(() {
      _view = _gestureStart.zoomAround(
        d.localFocalPoint,
        _gestureStart.scale * d.scale,
        _size,
        worldAtFocal: _worldAtFocal,
      );
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_dragNode >= 0) {
      _layout.pinned = -1;
      _dragNode = -1;
    }
  }

  void _onTapUp(TapUpDetails d) {
    final hit = hitTestNode(
      _layout.x,
      _layout.y,
      _graph.nodes,
      _view.toWorld(d.localPosition, _size),
      _view.scale,
    );
    if (hit >= 0 && hit == _selected) {
      _openNote(hit);
    } else {
      setState(() => _selected = hit);
    }
  }

  Future<void> _editTag(String tag) async {
    final renamed = await showTagColorSheet(context, widget.notes, tag);
    if (renamed == null || !mounted || !_filterTags.contains(tag)) return;
    setState(() {
      _filterTags = _renamed(_filterTags, tag, renamed);
      _applyFilter();
    });
  }

  Future<void> _editSource(String source) async {
    final renamed = await showSourceSheet(context, widget.notes, source);
    if (renamed == null || !mounted || !_filterSources.contains(source)) {
      return;
    }
    setState(() {
      _filterSources = _renamed(_filterSources, source, renamed);
      _applyFilter();
    });
  }

  /// Un filtro rinominato resta attivo con il nuovo nome.
  static List<String> _renamed(List<String> values, String from, String to) => [
    ...{for (final v in values) v == from ? to : v},
  ];

  void _openNote(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(
          noteId: _graph.nodes[index].note.id,
          notes: widget.notes,
        ),
      ),
    );
  }

  Future<void> _editFilters() async {
    final result = await showModalBottomSheet<(List<String>, List<String>)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(
        tagCounts: widget.notes.tagCounts,
        sourceCounts: widget.notes.sourceCounts,
        tags: _filterTags,
        sources: _filterSources,
      ),
    );
    if (result == null) return;
    setState(() {
      final (tags, sources) = result;
      _filterTags = tags;
      _filterSources = sources;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final noteCount = _graph.nodes.length;
    final hasFilter = _matching != null;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.palette.background,
        title: Text(
          '${l.noteCount(noteCount)} · ${l.linkCount(_graph.edges.length)}',
          key: const Key('graph-stats'),
          style: LeviathanText.body.copyWith(color: context.palette.muted),
        ),
        actions: [
          IconButton(
            tooltip: l.filter,
            onPressed: _editFilters,
            icon: Badge(
              isLabelVisible: hasFilter,
              backgroundColor: context.palette.accent,
              smallSize: LeviathanSpacing.sm,
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            tooltip: l.center,
            onPressed: _fit,
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasFilter)
            _ActiveFilters(
              tags: _filterTags,
              sources: _filterSources,
              matches: _matching!.length,
              onTagLongPress: _editTag,
              onSourceLongPress: _editSource,
              onRemoveTag: (t) => setState(() {
                _filterTags = _filterTags.where((x) => x != t).toList();
                _applyFilter();
              }),
              onRemoveSource: (s) => setState(() {
                _filterSources = _filterSources.where((x) => x != s).toList();
                _applyFilter();
              }),
            ),
          Expanded(
            child: noteCount == 0
                ? Center(
                    child: Text(
                      l.graphEmpty,
                      style: TextStyle(color: context.palette.muted),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      _size = constraints.biggest;
                      if (_needsFit) {
                        _needsFit = false;
                        final bounds = boundsOf(_layout.x, _layout.y);
                        _view = GraphViewport.fit(bounds, _size);
                      }
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              key: const Key('graph-canvas'),
                              behavior: HitTestBehavior.opaque,
                              onScaleStart: _onScaleStart,
                              onScaleUpdate: _onScaleUpdate,
                              onScaleEnd: _onScaleEnd,
                              onTapUp: _onTapUp,
                              child: CustomPaint(
                                painter: _GraphPainter(
                                  graph: _graph,
                                  layout: _layout,
                                  view: _view,
                                  selected: _selected,
                                  matching: _matching,
                                  palette: context.palette,
                                  untitled: l.untitled,
                                ),
                              ),
                            ),
                          ),
                          if (_selected >= 0)
                            Positioned(
                              left: LeviathanSpacing.md,
                              right: LeviathanSpacing.md,
                              bottom: LeviathanSpacing.md,
                              child: _SelectedCard(
                                node: _graph.nodes[_selected],
                                onOpen: () => _openNote(_selected),
                                onTagLongPress: _editTag,
                                onSourceLongPress: _editSource,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.graph,
    required this.layout,
    required this.view,
    required this.selected,
    required this.matching,
    required this.palette,
    required this.untitled,
  }) : super(repaint: layout);

  final NoteGraph graph;
  final ForceLayout layout;
  final GraphViewport view;
  final int selected;
  final Set<String>? matching;
  final LeviathanPalette palette;

  /// Etichetta delle note senza titolo, nella lingua dell'interfaccia.
  final String untitled;

  static const _labelZoom = 1.3;
  static final Map<String, TextPainter> _labels = {};

  bool _isIn(int i) =>
      matching == null || matching!.contains(graph.nodes[i].note.id);

  @override
  void paint(Canvas canvas, Size size) {
    final xs = layout.x;
    final ys = layout.y;
    canvas.save();
    canvas.translate(
      size.width / 2 + view.pan.dx,
      size.height / 2 + view.pan.dy,
    );
    canvas.scale(view.scale);

    // Collegamenti: un solo Path per quelli normali, uno per gli attenuati.
    final normal = Path();
    final dim = Path();
    final highlight = Path();
    for (final e in graph.edges) {
      final path = (e.a == selected || e.b == selected)
          ? highlight
          : (_isIn(e.a) && _isIn(e.b))
          ? normal
          : dim;
      path
        ..moveTo(xs[e.a], ys[e.a])
        ..lineTo(xs[e.b], ys[e.b]);
    }
    final hairline = 0.8 / view.scale;
    canvas.drawPath(
      dim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hairline
        ..color = palette.link.withValues(alpha: LeviathanOpacity.edgeDim),
    );
    canvas.drawPath(
      normal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hairline
        ..color = palette.link.withValues(alpha: LeviathanOpacity.edge),
    );
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hairline * 1.8
        ..color = palette.accent.withValues(
          alpha: LeviathanOpacity.edgeHighlight,
        ),
    );

    // Nodi. I task eseguiti restano al loro posto ma sbiaditi.
    final fill = Paint();
    for (var i = 0; i < graph.nodes.length; i++) {
      final node = graph.nodes[i];
      final done = node.note.isTask && node.note.done;
      fill.color = !_isIn(i)
          ? node.color.withValues(alpha: LeviathanOpacity.nodeDim)
          : done
          ? node.color.withValues(alpha: LeviathanOpacity.nodeDone)
          : node.color;
      canvas.drawCircle(Offset(xs[i], ys[i]), nodeRadius(node.degree), fill);
    }
    if (selected >= 0) {
      final node = graph.nodes[selected];
      canvas.drawCircle(
        Offset(xs[selected], ys[selected]),
        nodeRadius(node.degree) + 3 / view.scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / view.scale
          ..color = palette.text,
      );
    }
    canvas.restore();

    // Etichette in coordinate dello schermo (dimensione fissa del testo).
    final showAll = view.scale >= _labelZoom;
    for (var i = 0; i < graph.nodes.length; i++) {
      if (!(showAll && _isIn(i)) && i != selected) continue;
      final node = graph.nodes[i];
      final p = view.toScreen(Offset(xs[i], ys[i]), size);
      if (p.dx < -80 ||
          p.dy < -20 ||
          p.dx > size.width + 80 ||
          p.dy > size.height + 20) {
        continue;
      }
      final title = node.note.displayTitle(untitled);
      final label = _labels.putIfAbsent(
        '${node.note.id}|$title|${palette.id}',
        () => TextPainter(
          text: TextSpan(
            text: title,
            style: LeviathanText.tiny.copyWith(
              color: palette.text.withValues(
                alpha: LeviathanOpacity.graphLabel,
              ),
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: LeviathanSizes.graphLabelWidth),
      );
      final r = nodeRadius(node.degree) * view.scale;
      label.paint(canvas, p + Offset(-label.width / 2, r + 3));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.view != view ||
      old.selected != selected ||
      old.matching != matching ||
      old.palette != palette ||
      old.untitled != untitled ||
      old.graph != graph ||
      old.layout != layout;
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({
    required this.node,
    required this.onOpen,
    required this.onTagLongPress,
    required this.onSourceLongPress,
  });

  final GraphNode node;
  final VoidCallback onOpen;
  final ValueChanged<String> onTagLongPress;
  final ValueChanged<String> onSourceLongPress;

  @override
  Widget build(BuildContext context) {
    final note = node.note;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(LeviathanRadii.lg),
      child: InkWell(
        key: const Key('graph-card'),
        borderRadius: BorderRadius.circular(LeviathanRadii.lg),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.lg,
            LeviathanSpacing.md,
            LeviathanSpacing.sm,
            LeviathanSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      note.displayTitle(context.l10n.untitled),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LeviathanText.title,
                    ),
                    const SizedBox(height: LeviathanSpacing.xxs),
                    Text(
                      context.l10n.linkedNotes(node.degree),
                      style: LeviathanText.meta.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                    if (note.tags.isNotEmpty || note.sources.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: LeviathanSpacing.sm,
                        ),
                        child: Wrap(
                          spacing: LeviathanSpacing.xs,
                          runSpacing: LeviathanSpacing.xs,
                          children: [
                            for (final t in note.tags)
                              TagChip(
                                t,
                                dense: true,
                                onLongPress: () => onTagLongPress(t),
                              ),
                            for (final s in note.sources)
                              SourceChip(
                                s,
                                dense: true,
                                onLongPress: () => onSourceLongPress(s),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.tags,
    required this.sources,
    required this.matches,
    required this.onRemoveTag,
    required this.onRemoveSource,
    required this.onTagLongPress,
    required this.onSourceLongPress,
  });

  final List<String> tags;
  final List<String> sources;
  final int matches;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onRemoveSource;
  final ValueChanged<String> onTagLongPress;
  final ValueChanged<String> onSourceLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.md,
        0,
        LeviathanSpacing.md,
        LeviathanSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: LeviathanSpacing.sm,
              runSpacing: LeviathanSpacing.sm,
              children: [
                for (final t in tags)
                  TagChip(
                    t,
                    onDeleted: () => onRemoveTag(t),
                    onLongPress: () => onTagLongPress(t),
                  ),
                for (final s in sources)
                  SourceChip(
                    s,
                    onDeleted: () => onRemoveSource(s),
                    onLongPress: () => onSourceLongPress(s),
                  ),
              ],
            ),
          ),
          Text('$matches', style: TextStyle(color: context.palette.muted)),
        ],
      ),
    );
  }
}

/// Scelta dei filtri: tag e fonti, in AND come nella ricerca.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.tagCounts,
    required this.sourceCounts,
    required this.tags,
    required this.sources,
  });

  final Map<String, int> tagCounts;
  final Map<String, int> sourceCounts;
  final List<String> tags;
  final List<String> sources;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _tags = {...widget.tags};
  late final Set<String> _sources = {...widget.sources};

  List<String> _byCount(Map<String, int> counts) =>
      counts.keys.toList()..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: LeviathanSpacing.lg,
                ),
                children: [
                  Text(l.tags, style: text.titleSmall),
                  const SizedBox(height: LeviathanSpacing.sm),
                  if (widget.tagCounts.isEmpty)
                    Text(
                      l.noTags,
                      style: TextStyle(color: context.palette.muted),
                    ),
                  Wrap(
                    spacing: LeviathanSpacing.sm,
                    runSpacing: LeviathanSpacing.sm,
                    children: [
                      for (final t in _byCount(widget.tagCounts))
                        FilterChip(
                          avatar: CircleAvatar(
                            backgroundColor: Tags.colorOf(t),
                            radius: LeviathanSizes.tagDot,
                          ),
                          label: Text('$t  ${widget.tagCounts[t]}'),
                          selected: _tags.contains(t),
                          showCheckmark: false,
                          onSelected: (on) => setState(
                            () => on ? _tags.add(t) : _tags.remove(t),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: LeviathanSpacing.xl),
                  Text(l.sources, style: text.titleSmall),
                  const SizedBox(height: LeviathanSpacing.sm),
                  if (widget.sourceCounts.isEmpty)
                    Text(
                      l.noSources,
                      style: TextStyle(color: context.palette.muted),
                    ),
                  Wrap(
                    spacing: LeviathanSpacing.sm,
                    runSpacing: LeviathanSpacing.sm,
                    children: [
                      for (final s in _byCount(widget.sourceCounts))
                        FilterChip(
                          avatar: const Icon(
                            Icons.person_outline,
                            size: LeviathanIconSize.sm,
                          ),
                          label: Text('$s  ${widget.sourceCounts[s]}'),
                          selected: _sources.contains(s),
                          showCheckmark: false,
                          onSelected: (on) => setState(
                            () => on ? _sources.add(s) : _sources.remove(s),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: LeviathanSpacing.lg),
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
                  TextButton(
                    onPressed: () => Navigator.pop(context, (
                      const <String>[],
                      const <String>[],
                    )),
                    child: Text(l.clearFilters),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, (
                      _tags.toList(),
                      _sources.toList(),
                    )),
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
