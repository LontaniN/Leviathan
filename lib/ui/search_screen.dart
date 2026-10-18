import 'package:flutter/material.dart';

import '../model/dates.dart';
import '../model/note.dart';
import '../model/search.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'chip_input.dart';
import 'note_screen.dart';
import 'task_check.dart';
import 'theme.dart';

/// Ricerca in stile Discord: si scrive il testo da cercare e si aggiungono
/// filtri con `tag:` / `#`, `da:` / `@` e `stato:`. Testo e filtri sono
/// facoltativi e si combinano liberamente.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.notes,
    this.initialTags = const [],
    this.initialSources = const [],
  });

  final NotesController notes;
  final List<String> initialTags;
  final List<String> initialSources;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  late List<String> _tags = [...widget.initialTags];
  late List<String> _sources = [...widget.initialSources];
  TaskFilter? _task;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onText);
    _focus.addListener(() => setState(() {}));
    // Anche partendo da un tag o una fonte si viene qui per scrivere.
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    final text = _input.text;
    // Spazio dopo un tag o virgola dopo una fonte: il filtro è confermato.
    if (text.endsWith(' ') || text.endsWith(',')) {
      final before = SearchInput.parse(text.substring(0, text.length - 1));
      final closesTag =
          before.activeKind == FilterKind.tag ||
          before.activeKind == FilterKind.status;
      final closesSource =
          before.activeKind == FilterKind.source && text.endsWith(',');
      if ((closesTag || closesSource) && before.activeValue.trim().isNotEmpty) {
        _commit(before, before.activeValue);
        return;
      }
    }
    setState(() {});
  }

  void _commit(SearchInput parsed, String value) {
    final kind = parsed.activeKind!;
    setState(() {
      switch (kind) {
        case FilterKind.tag:
          final tag = Tags.normalize(value);
          if (tag.isNotEmpty && !_tags.contains(tag)) _tags = [..._tags, tag];
        case FilterKind.source:
          final source = Sources.canonical(
            value,
            widget.notes.sourceCounts.keys,
          );
          if (source.isNotEmpty && !_sources.contains(source)) {
            _sources = [..._sources, source];
          }
        case FilterKind.status:
          // Un solo filtro di stato alla volta: il nuovo sostituisce il vecchio.
          _task = TaskFilter.parse(value) ?? _task;
      }
    });
    final rest = parsed.freeText;
    _input.value = TextEditingValue(
      text: rest.isEmpty ? '' : '$rest ',
      selection: TextSelection.collapsed(
        offset: rest.isEmpty ? 0 : rest.length + 1,
      ),
    );
    _focus.requestFocus();
  }

  void _insertMarker(String marker) {
    final text = _input.text;
    final glue = text.isEmpty || text.endsWith(' ') ? '' : ' ';
    final next = '$text$glue$marker';
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _focus.requestFocus();
  }

  List<String> _suggestions(SearchInput parsed) => switch (parsed.activeKind) {
    FilterKind.tag => Tags.suggest(
      parsed.activeValue,
      widget.notes.tagCounts,
      exclude: _tags,
      limit: 8,
    ),
    FilterKind.source => Sources.suggest(
      parsed.activeValue,
      widget.notes.sourceCounts,
      exclude: _sources,
      limit: 8,
    ),
    FilterKind.status => [
      for (final f in TaskFilter.suggest(parsed.activeValue)) f.label,
    ],
    null => const [],
  };

  /// Quante note corrispondono a ogni filtro di stato.
  Map<String, int> get _statusCounts => {
    for (final f in TaskFilter.values)
      f.label: widget.notes.notes.where(f.matches).length,
  };

  void _submit(SearchInput parsed) {
    if (parsed.activeKind == null) {
      _focus.unfocus();
      return;
    }
    final suggestions = _suggestions(parsed);
    final value = suggestions.isNotEmpty
        ? suggestions.first
        : parsed.activeValue;
    if (value.trim().isNotEmpty) _commit(parsed, value);
  }

  void _clear() {
    _input.clear();
    setState(() {
      _tags = [];
      _sources = [];
      _task = null;
    });
    _focus.requestFocus();
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
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        final parsed = SearchInput.parse(_input.text);
        final query = SearchQuery(
          text: parsed.freeText,
          tags: _tags,
          sources: _sources,
          task: _task,
        );
        final hasAnything =
            _input.text.trim().isNotEmpty ||
            _tags.isNotEmpty ||
            _sources.isNotEmpty ||
            _task != null;
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBar(
                  input: _input,
                  focus: _focus,
                  tags: _tags,
                  sources: _sources,
                  task: _task,
                  onRemoveTag: (t) => setState(
                    () => _tags = _tags.where((x) => x != t).toList(),
                  ),
                  onRemoveSource: (s) => setState(
                    () => _sources = _sources.where((x) => x != s).toList(),
                  ),
                  onRemoveTask: () => setState(() => _task = null),
                  onSubmitted: () => _submit(parsed),
                  onClear: hasAnything ? _clear : null,
                ),
                Expanded(
                  child: _focus.hasFocus && parsed.activeKind != null
                      ? _FilterSuggestions(
                          kind: parsed.activeKind!,
                          values: _suggestions(parsed),
                          counts: switch (parsed.activeKind!) {
                            FilterKind.tag => widget.notes.tagCounts,
                            FilterKind.source => widget.notes.sourceCounts,
                            FilterKind.status => _statusCounts,
                          },
                          onPick: (v) => _commit(parsed, v),
                        )
                      : query.isEmpty
                      ? _FilterOptions(
                          onPick: _insertMarker,
                          tagCounts: widget.notes.tagCounts,
                          sourceCounts: widget.notes.sourceCounts,
                          onAddTag: (t) =>
                              setState(() => _tags = [..._tags, t]),
                          onAddSource: (s) =>
                              setState(() => _sources = [..._sources, s]),
                        )
                      : _Results(
                          hits: searchNotes(widget.notes.notes, query),
                          terms: query.terms,
                          onOpen: _open,
                          onToggleDone: widget.notes.setDone,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.input,
    required this.focus,
    required this.tags,
    required this.sources,
    required this.task,
    required this.onRemoveTag,
    required this.onRemoveSource,
    required this.onRemoveTask,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController input;
  final FocusNode focus;
  final List<String> tags;
  final List<String> sources;
  final TaskFilter? task;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onRemoveSource;
  final VoidCallback onRemoveTask;
  final VoidCallback onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.xs,
        LeviathanSpacing.xs,
        LeviathanSpacing.md,
        LeviathanSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackButton(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(LeviathanRadii.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LeviathanSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (tags.isNotEmpty || sources.isNotEmpty || task != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: LeviathanSpacing.sm,
                        ),
                        child: Wrap(
                          spacing: LeviathanSpacing.sm,
                          runSpacing: LeviathanSpacing.sm,
                          children: [
                            if (task != null)
                              StatusChip(task!, onDeleted: onRemoveTask),
                            for (final tag in tags)
                              TagChip(tag, onDeleted: () => onRemoveTag(tag)),
                            for (final source in sources)
                              SourceChip(
                                source,
                                onDeleted: () => onRemoveSource(source),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: LeviathanIconSize.md,
                          color: context.palette.muted,
                        ),
                        Expanded(
                          child: TextField(
                            key: const Key('search-field'),
                            controller: input,
                            focusNode: focus,
                            autocorrect: false,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Cerca, oppure tag: / da:',
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: LeviathanSpacing.sm,
                                vertical: LeviathanSpacing.md,
                              ),
                            ),
                            onSubmitted: (_) => onSubmitted(),
                          ),
                        ),
                        if (onClear != null)
                          IconButton(
                            tooltip: 'Svuota',
                            icon: const Icon(
                              Icons.close,
                              size: LeviathanIconSize.md,
                            ),
                            onPressed: onClear,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ricerca vuota: i tag e le fonti più usati, che toccati diventano subito
/// filtri, e sotto la spiegazione dei filtri, che toccati si inseriscono.
class _FilterOptions extends StatelessWidget {
  const _FilterOptions({
    required this.onPick,
    required this.tagCounts,
    required this.sourceCounts,
    required this.onAddTag,
    required this.onAddSource,
  });

  final ValueChanged<String> onPick;
  final Map<String, int> tagCounts;
  final Map<String, int> sourceCounts;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onAddSource;

  /// Quanti tag e quante fonti frequenti mostrare.
  static const _frequent = 12;

  @override
  Widget build(BuildContext context) {
    final tags = Tags.suggest('', tagCounts, limit: _frequent);
    final sources = Sources.suggest('', sourceCounts, limit: _frequent);
    Widget chips(List<Widget> children) => Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        LeviathanSpacing.xs,
        LeviathanSpacing.lg,
        LeviathanSpacing.md,
      ),
      child: Wrap(
        spacing: LeviathanSpacing.sm,
        runSpacing: LeviathanSpacing.sm,
        children: children,
      ),
    );
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (tags.isNotEmpty) ...[
          const SectionTitle('Tag frequenti'),
          chips([
            for (final t in tags)
              ActionChip(
                key: Key('frequent-tag-$t'),
                avatar: CircleAvatar(
                  backgroundColor: Tags.colorOf(t),
                  radius: LeviathanSizes.tagDot,
                ),
                label: _counted(context, t, tagCounts[t]),
                visualDensity: VisualDensity.compact,
                onPressed: () => onAddTag(t),
              ),
          ]),
        ],
        if (sources.isNotEmpty) ...[
          const SectionTitle('Fonti frequenti'),
          chips([
            for (final s in sources)
              ActionChip(
                avatar: Icon(
                  Icons.person_outline,
                  size: LeviathanIconSize.sm,
                  color: context.palette.muted,
                ),
                label: _counted(context, s, sourceCounts[s]),
                visualDensity: VisualDensity.compact,
                onPressed: () => onAddSource(s),
              ),
          ]),
        ],
        const SectionTitle('Filtri di ricerca'),
        ListTile(
          leading: const Icon(Icons.sell_outlined),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'tag: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: 'note con un tag',
                  style: TextStyle(color: context.palette.muted),
                ),
              ],
            ),
          ),
          subtitle: const Text('scorciatoia: #'),
          onTap: () => onPick('tag:'),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'da: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: 'note da una fonte (persona)',
                  style: TextStyle(color: context.palette.muted),
                ),
              ],
            ),
          ),
          subtitle: const Text('scorciatoia: @'),
          onTap: () => onPick('da:'),
        ),
        ListTile(
          leading: const Icon(Icons.check_box_outlined),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'stato: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: 'task da fare o fatti',
                  style: TextStyle(color: context.palette.muted),
                ),
              ],
            ),
          ),
          subtitle: const Text('aperto · fatto · task'),
          onTap: () => onPick('stato:'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.lg,
            LeviathanSpacing.lg,
            LeviathanSpacing.lg,
            0,
          ),
          child: Text(
            'Testo e filtri si combinano: per esempio '
            '"esposizione tag:fotografia da:Mario Rossi" oppure '
            '"stato:aperto tag:università".',
            style: LeviathanText.body.copyWith(color: context.palette.muted),
          ),
        ),
      ],
    );
  }
}

/// Nome e, attenuato, quante note lo usano: come i suggerimenti dell'editor.
Widget _counted(BuildContext context, String name, int? count) => Text.rich(
  TextSpan(
    text: name,
    children: [
      TextSpan(
        text: '  ${count ?? 0}',
        style: TextStyle(color: context.palette.muted),
      ),
    ],
  ),
);

/// Mentre si scrive un filtro: i tag o le fonti che corrispondono.
class _FilterSuggestions extends StatelessWidget {
  const _FilterSuggestions({
    required this.kind,
    required this.values,
    required this.counts,
    required this.onPick,
  });

  final FilterKind kind;
  final List<String> values;
  final Map<String, int> counts;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionTitle(switch (kind) {
          FilterKind.tag => 'Tag',
          FilterKind.source => 'Fonti',
          FilterKind.status => 'Stato dei task',
        }),
        if (values.isEmpty)
          Padding(
            padding: const EdgeInsets.all(LeviathanSpacing.lg),
            child: Text(switch (kind) {
              FilterKind.tag => 'Nessun tag corrispondente',
              FilterKind.source => 'Nessuna fonte corrispondente',
              FilterKind.status => 'Scrivi aperto, fatto o task',
            }, style: TextStyle(color: context.palette.muted)),
          ),
        for (final value in values)
          ListTile(
            leading: switch (kind) {
              FilterKind.tag => CircleAvatar(
                backgroundColor: Tags.colorOf(value),
                radius: LeviathanSpacing.xs,
              ),
              FilterKind.source => Icon(
                Icons.person_outline,
                color: context.palette.muted,
              ),
              FilterKind.status => Icon(
                Icons.check_box_outlined,
                color: context.palette.muted,
              ),
            },
            title: Text(value),
            subtitle: kind == FilterKind.status
                ? Text(TaskFilter.parse(value)!.description)
                : null,
            trailing: Text(
              '${counts[value] ?? 0}',
              style: TextStyle(color: context.palette.muted),
            ),
            onTap: () => onPick(value),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.hits,
    required this.terms,
    required this.onOpen,
    required this.onToggleDone,
  });

  final List<SearchHit> hits;
  final List<String> terms;
  final ValueChanged<Note> onOpen;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: LeviathanIconSize.xl,
              color: context.palette.muted,
            ),
            const SizedBox(height: LeviathanSpacing.md),
            Text(
              'Nessuna nota trovata',
              style: TextStyle(color: context.palette.muted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
      itemCount: hits.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return SectionTitle(
            hits.length == 1 ? '1 risultato' : '${hits.length} risultati',
          );
        }
        final hit = hits[i - 1];
        return NoteResultTile(
          hit: hit,
          terms: terms,
          onTap: onOpen,
          onToggleDone: onToggleDone,
        );
      },
    );
  }
}

/// Una nota in un elenco di risultati: titolo, data, estratto, tag e fonti.
/// I task hanno la casella, che si spunta se c'è [onToggleDone].
class NoteResultTile extends StatelessWidget {
  const NoteResultTile({
    super.key,
    required this.hit,
    required this.terms,
    required this.onTap,
    this.onToggleDone,
    this.dateLabel,
  });

  final SearchHit hit;

  /// Cosa scrivere a destra del titolo; di default la data di creazione.
  final String? dateLabel;
  final List<String> terms;
  final ValueChanged<Note> onTap;
  final void Function(Note note, bool done)? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final note = hit.note;
    return InkWell(
      onTap: () => onTap(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LeviathanSpacing.lg,
          vertical: LeviathanSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.isTask)
                  Padding(
                    padding: const EdgeInsets.only(right: LeviathanSpacing.xs),
                    child: TaskCheck(
                      note: note,
                      onChanged: onToggleDone == null
                          ? null
                          : (done) => onToggleDone!(note, done),
                    ),
                  ),
                Expanded(
                  child: HighlightText(
                    note.displayTitle,
                    terms: terms,
                    maxLines: 1,
                    style: taskTitleStyle(context, note, LeviathanText.title),
                  ),
                ),
                const SizedBox(width: LeviathanSpacing.sm),
                Text(
                  dateLabel ?? formatDate(note.created),
                  style: LeviathanText.meta.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              ],
            ),
            if (hit.snippet.isNotEmpty && note.title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: LeviathanSpacing.xxs),
                child: HighlightText(
                  hit.snippet,
                  terms: terms,
                  maxLines: 3,
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
                    for (final tag in note.tags) TagChip(tag, dense: true),
                    for (final source in note.sources)
                      SourceChip(source, dense: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Testo con le parole cercate evidenziate.
class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    required this.terms,
    this.style,
    this.maxLines,
  });

  final String text;
  final List<String> terms;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final ranges = matchRanges(text, terms);
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: TextStyle(
            color: context.palette.onAccent,
            backgroundColor: context.palette.accent,
          ),
        ),
      );
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// Intestazione di sezione in maiuscoletto grigio.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        LeviathanSpacing.sm,
        LeviathanSpacing.lg,
        LeviathanSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: LeviathanText.caption.copyWith(color: context.palette.muted),
      ),
    );
  }
}
