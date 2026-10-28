import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/diary_store.dart';
import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/diary_extract.dart';
import '../model/diary_scrub.dart';
import '../model/tags.dart';
import '../state/diary_extracts.dart';
import '../state/diary_sync.dart';
import '../state/notes_controller.dart';
import 'chip_input.dart';
import 'due_date_row.dart';
import 'note_screen.dart';
import 'theme.dart';

/// Il diario: una casella per giorno, da oggi all'indietro, dove scrivere
/// liberamente quello che è successo. A sinistra di ogni casella il giorno e
/// il mese.
///
/// Selezionando del testo, fra le azioni compare "Crea nota": un foglio in
/// basso chiede titolo, tag e fonti e la nota nasce subito, con quel testo
/// nel corpo e datata a quel giorno, senza lasciare la pagina. Il testo
/// resta colorato col primo tag della nota, così si vede cosa è già una
/// nota; tenendolo premuto se ne apre la nota o si toglie il colore. Un
/// tocco ci porta solo il cursore: il testo si modifica come il resto, e il
/// pezzo segue le modifiche senza perdere la nota (vedi [followEdit]).
///
/// Trascinando il dito su e giù sulla colonna delle date si corre nel
/// tempo: in cima oggi, in fondo il giorno della nota più vecchia (o del
/// giorno scritto più vecchio, se viene prima). Mentre si
/// scorre compaiono un puntino per ogni giorno scritto (il dito ci si
/// aggancia) e una bolla con la data e l'inizio del testo.
///
/// Aperta solo la casella di oggi: gli altri giorni mostrano le prime righe
/// e si aprono toccandoli, o tutti insieme col pulsante in alto. La freccina
/// in fondo a una casella lunga la apre o la richiude da sola.
///
/// Il testo si salva poco dopo ogni modifica (e subito se l'app va in
/// secondo piano), un file per giorno (vedi [DiaryStore]).
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({
    super.key,
    required this.store,
    required this.extracts,
    required this.notes,
  });

  final DiaryStore store;

  /// I pezzi colorati, gli stessi che la home usa per portare nel diario le
  /// note nate altrove (vedi [DiarySync]).
  final DiaryExtracts extracts;
  final NotesController notes;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> with WidgetsBindingObserver {
  /// Il testo di ogni giorno, per [DiaryStore.key]; null finché non lo si è
  /// letto.
  Map<String, String>? _days;
  String? _error;

  /// I giorni cambiati e non ancora scritti su disco.
  final _unsaved = <String, DateTime>{};
  Timer? _saveTimer;

  /// Oggi, fissato all'apertura: la lista parte da qui.
  final _today = DateTime.now();

  /// Tutte le caselle aperte, dal pulsante in alto; altrimenti solo oggi.
  /// In [_opened] i giorni aperti (true) o chiusi (false) uno per uno, che
  /// il pulsante dimentica.
  bool _allOpen = false;
  final _opened = <String, bool>{};

  /// I pezzi del diario diventati note.
  DiaryExtracts get _extracts => widget.extracts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.notes.addListener(_onNotes);
    // Le note cancellate da quando si è aperto il diario l'ultima volta si
    // portano via il loro colore. Se le note non si sono potute leggere non
    // si tocca nulla: sembrerebbero cancellate tutte.
    if (widget.notes.error == null) _extracts.removeOrphans(widget.notes.byId);
    _extracts.addListener(_onExtracts);
    try {
      _days = widget.store.readAll();
    } on FileSystemException catch (e) {
      _error = e.message;
    }
  }

  @override
  void dispose() {
    _save();
    _scroll.dispose();
    _extracts.removeListener(_onExtracts);
    widget.notes.removeListener(_onNotes);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android può chiudere l'app in secondo piano senza avvisare.
    if (state != AppLifecycleState.resumed) _save();
  }

  /// [caret] è il cursore dopo la modifica (vedi [followEdit]).
  void _changed(DateTime day, String text, int caret) {
    final key = DiaryStore.key(day);
    final before = _days![key] ?? '';
    for (final extract in followEdit(
      before,
      text,
      _extracts.ofDay(key),
      caret: caret,
    )) {
      _extracts.update(extract);
    }
    _days![key] = text;
    _unsaved[key] = day;
    _saveTimer?.cancel();
    _saveTimer = Timer(LeviathanDurations.draftSave, _save);
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final days = _days;
    if (days == null) return;
    try {
      for (final MapEntry(:key, value: day) in _unsaved.entries) {
        widget.store.write(day, days[key] ?? '');
      }
      _unsaved.clear();
    } on FileSystemException catch (e) {
      // I giorni non scritti restano in [_unsaved]: si riprova alla
      // prossima modifica.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.diarySaveError(e.message))),
        );
      }
    }
  }

  /// Il giorno [index] contando da oggi all'indietro. Si passa dal
  /// calendario e non dalle ore: l'ora legale sposterebbe il conto.
  DateTime _dayAt(int index) =>
      DateTime(_today.year, _today.month, _today.day - index);

  final _scroll = ScrollController();
  final _centerKey = UniqueKey();

  /// Il giorno (quanti giorni fa) da cui parte la lista: sopra ci sono i più
  /// recenti fino a oggi, sotto i più vecchi. Saltando a un giorno si
  /// cambia questo e si torna in cima, così si arriva subito anche lontano,
  /// con caselle di altezza diversa.
  int _anchor = 0;

  /// Il giorno sotto il dito mentre si scorre la colonna delle date, e dove
  /// è il dito; null se non la si sta scorrendo.
  int? _scrubDay;
  double _scrubY = 0;

  /// I giorni scritti, come quanti giorni fa, in ordine crescente.
  List<int> get _writtenAgo => [
    for (final MapEntry(:key, :value) in _days!.entries)
      if (value.trim().isNotEmpty)
        if (DateTime.tryParse(key) case final day?)
          if (daysAgo(day, _today) case final ago when ago >= 0) ago,
  ]..sort();

  void _scrubTo(double y, double height, List<int> written, int range) {
    final track = height - 2 * LeviathanSpacing.lg;
    final day = scrubDay(
      (y - LeviathanSpacing.lg) / track,
      range,
      written,
      snap: LeviathanSizes.diaryScrubSnap / track,
    );
    final moved = day != _scrubDay;
    // Un piccolo scatto quando si aggancia un giorno scritto.
    if (moved && written.contains(day)) HapticFeedback.selectionClick();
    setState(() {
      _scrubY = y;
      _scrubDay = day;
      _anchor = day;
    });
    if (moved && _scroll.hasClients) _scroll.jumpTo(0);
  }

  void _endScrub() => setState(() => _scrubDay = null);

  void _onExtracts() => setState(() {});

  /// Una nota cancellata (anche dalla sua pagina, aperta dal diario) toglie
  /// subito il colore dal testo; se la si rimette col tasto annulla, il
  /// colore torna.
  void _onNotes() => setState(() {});

  /// I pezzi colorati del giorno [key]: solo quelli la cui nota c'è ancora.
  ///
  /// Il colore segue i tag che la nota ha adesso, non quelli che aveva
  /// quando è nata.
  List<DiaryExtract> _extractsOf(String key) => [
    for (final e in _extracts.ofDay(key))
      if (e.noteId == null)
        e
      else if (widget.notes.byId(e.noteId!) case final note?)
        e.copyWith(tags: note.tags),
  ];

  /// I tag delle note nate dal giorno [key], senza doppioni, nell'ordine in
  /// cui le loro frasi stanno nel testo.
  List<String> _tagsOf(String key, List<DiaryExtract> extracts) => {
    for (final range in extractRanges(_days?[key] ?? '', extracts))
      if (range.extract.noteId != null) ...range.extract.tags,
  }.toList();

  /// "Crea nota" sul testo scelto: titolo, tag e fonti dal foglio, e la nota
  /// nasce subito, datata a quel giorno. Il pezzo resta colorato nel diario.
  /// Con [from] il pezzo era già colorato ma non ancora una nota.
  Future<void> _createNote(
    DateTime day,
    String text,
    int start, {
    DiaryExtract? from,
  }) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showNoteSheet(
      context,
      widget.notes,
      text: text,
      tags: from?.tags ?? const [],
      sources: from?.sources ?? const [],
    );
    if (choice == null || !mounted) return;
    final now = DateTime.now();
    final note = widget.notes.create(
      title: choice.title,
      body: text,
      tags: choice.tags,
      sources: choice.sources,
      isTask: choice.isTask,
      knowledge: choice.knowledge,
      due: choice.due,
      created: sameDay(day, now) ? null : onDay(day, now),
    );
    if (from != null) {
      _extracts.update(
        from.copyWith(tags: note.tags, sources: note.sources, noteId: note.id),
      );
    } else {
      _extracts.add(
        day: DiaryStore.key(day),
        text: text,
        start: start,
        tags: note.tags,
        sources: note.sources,
        noteId: note.id,
      );
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(note.isTask ? l.taskCreated : l.noteCreated),
          persist: false,
          action: SnackBarAction(
            label: l.diaryOpenNote,
            onPressed: () => _openNote(note.id),
          ),
        ),
      );
  }

  void _openNote(String id) {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: id, notes: widget.notes),
      ),
    );
  }

  /// Toglie il colore da un pezzo; la nota, se c'è, resta. Si può
  /// annullare.
  void _removeExtract(DiaryExtract extract) {
    final l = context.l10n;
    _extracts.remove(extract);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.diaryExtractRemoved),
          persist: false,
          duration: LeviathanDurations.undoSnackBar,
          action: SnackBarAction(
            label: l.undo,
            onPressed: () => _extracts.restore(extract),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final days = _days;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text(l.diary),
        actions: [
          IconButton(
            key: const Key('diary-expand-all'),
            tooltip: _allOpen ? l.diaryCollapseAll : l.diaryExpandAll,
            icon: Icon(_allOpen ? Icons.unfold_less : Icons.unfold_more),
            onPressed: () => setState(() {
              _allOpen = !_allOpen;
              _opened.clear();
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: days == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(LeviathanSpacing.xl),
                  child: Text(
                    l.diaryLoadError(_error ?? ''),
                    textAlign: TextAlign.center,
                    style: LeviathanText.body.copyWith(color: palette.muted),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) =>
                    _diary(days, constraints.maxHeight),
              ),
      ),
    );
  }

  Widget _diary(Map<String, String> days, double height) {
    final written = _writtenAgo;
    // La barra arriva al più vecchio fra i giorni scritti e le note.
    final notes = widget.notes.notes;
    final range = scrubRange([
      ...written,
      for (final note in notes) daysAgo(note.created, _today),
    ]);
    Widget dayAt(int index) {
      final day = _dayAt(index);
      final key = DiaryStore.key(day);
      final extracts = _extractsOf(key);
      final expanded = _opened[key] ?? (index == 0 || _allOpen);
      return Padding(
        key: ValueKey(key),
        padding: const EdgeInsets.only(bottom: LeviathanSpacing.md),
        child: _DiaryDay(
          day: day,
          today: index == 0,
          expanded: expanded,
          onToggle: () => setState(() => _opened[key] = !expanded),
          initialText: days[key] ?? '',
          extracts: extracts,
          tags: _tagsOf(key, extracts),
          onChanged: (text, caret) => _changed(day, text, caret),
          onCreateNote: (text, start, from) =>
              _createNote(day, text, start, from: from),
          onOpenNote: _openNote,
          onRemoveExtract: _removeExtract,
        ),
      );
    }

    const sides = EdgeInsets.only(
      left: LeviathanSpacing.sm,
      right: LeviathanSpacing.lg,
    );
    const column = LeviathanSpacing.sm + LeviathanSizes.diaryDateColumn;
    final scrubbing = _scrubDay;
    return Stack(
      children: [
        // Una casella per giorno senza fine: i giorni si costruiscono solo
        // quando arrivano sullo schermo. Sopra [_centerKey] i giorni dopo
        // [_anchor] fino a oggi, che crescono verso l'alto.
        CustomScrollView(
          key: const Key('diary-list'),
          controller: _scroll,
          center: _centerKey,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          slivers: [
            SliverPadding(
              padding: sides.copyWith(top: LeviathanSpacing.xs),
              sliver: SliverList.builder(
                itemCount: _anchor,
                itemBuilder: (_, i) => dayAt(_anchor - 1 - i),
              ),
            ),
            SliverPadding(
              key: _centerKey,
              padding: _anchor == 0
                  ? sides.copyWith(top: LeviathanSpacing.xs)
                  : sides,
              sliver: SliverList.builder(
                itemBuilder: (_, i) => dayAt(_anchor + i),
              ),
            ),
          ],
        ),
        // La colonna delle date: trascinando il dito su e giù si scorre
        // veloce nel tempo, oggi in cima e il giorno più vecchio in fondo.
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: column,
          child: GestureDetector(
            key: const Key('diary-scrubber'),
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (d) {
              FocusManager.instance.primaryFocus?.unfocus();
              _scrubTo(d.localPosition.dy, height, written, range);
            },
            onVerticalDragUpdate: (d) =>
                _scrubTo(d.localPosition.dy, height, written, range),
            onVerticalDragEnd: (_) => _endScrub(),
            onVerticalDragCancel: _endScrub,
            child: scrubbing == null
                ? const SizedBox.expand()
                : CustomPaint(
                    size: Size.infinite,
                    painter: _ScrubTrackPainter(
                      written: written,
                      range: range,
                      day: scrubbing,
                      palette: context.palette,
                    ),
                  ),
          ),
        ),
        if (scrubbing != null)
          Positioned(
            left: column + LeviathanSpacing.xs,
            top: (_scrubY - LeviathanSizes.diaryBubbleHeight / 2).clamp(
              0.0,
              (height - LeviathanSizes.diaryBubbleHeight).clamp(0.0, height),
            ),
            child: IgnorePointer(
              child: _ScrubBubble(
                day: _dayAt(scrubbing),
                text: days[DiaryStore.key(_dayAt(scrubbing))] ?? '',
              ),
            ),
          ),
      ],
    );
  }
}

/// La barra del tempo mentre la si scorre: una linea sottile, un puntino per
/// ogni giorno scritto e il segno del giorno sotto il dito.
class _ScrubTrackPainter extends CustomPainter {
  _ScrubTrackPainter({
    required this.written,
    required this.range,
    required this.day,
    required this.palette,
  });

  final List<int> written;
  final int range;
  final int day;
  final LeviathanPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width - LeviathanSpacing.sm;
    const top = LeviathanSpacing.lg;
    final track = size.height - 2 * top;
    double y(int ago) => top + track * (ago / range).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(x, top),
      Offset(x, top + track),
      Paint()
        ..color = palette.outline
        ..strokeWidth = LeviathanSizes.outline,
    );
    final dot = Paint()..color = palette.muted;
    for (final ago in written) {
      canvas.drawCircle(Offset(x, y(ago)), LeviathanSizes.diaryTrackDot, dot);
    }
    canvas.drawCircle(
      Offset(x, y(day)),
      LeviathanSizes.diaryTrackThumb,
      Paint()..color = palette.accent,
    );
  }

  @override
  bool shouldRepaint(_ScrubTrackPainter old) =>
      old.day != day ||
      old.range != range ||
      old.palette != palette ||
      old.written.length != written.length;
}

/// La bolla accanto al dito: la data del giorno e l'inizio di quello che
/// c'è scritto, per capire al volo se è il giorno che si cerca.
class _ScrubBubble extends StatelessWidget {
  const _ScrubBubble({required this.day, required this.text});

  final DateTime day;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final preview = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return Material(
      key: const Key('diary-scrub-bubble'),
      color: palette.accent,
      elevation: LeviathanSizes.tourCardElevation,
      borderRadius: BorderRadius.circular(LeviathanRadii.md),
      child: Container(
        width: LeviathanSizes.diaryBubbleWidth,
        padding: const EdgeInsets.symmetric(
          horizontal: LeviathanSpacing.md,
          vertical: LeviathanSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${weekdayName(l, day.weekday)} ${formatDate(l, day)}',
              style: LeviathanText.title.copyWith(color: palette.onAccent),
            ),
            Text(
              preview.isEmpty ? l.diaryNothingWritten : preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LeviathanText.body.copyWith(
                color: palette.onAccent,
                fontStyle: preview.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il testo scelto in [value], senza gli spazi ai bordi, e dove comincia;
/// null se non c'è una selezione con del testo.
({String text, int start})? _selectedText(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid || selection.isCollapsed) return null;
  final raw = selection.textInside(value.text);
  final text = raw.trim();
  if (text.isEmpty) return null;
  return (text: text, start: selection.start + raw.indexOf(text));
}

/// Un giorno del diario: giorno e mese a sinistra, la casella in mezzo e a
/// destra una colonna stretta con i tag delle note nate dalle sue frasi.
///
/// I pezzi diventati note ([extracts]) sono colorati col loro primo tag e
/// sottolineati come un collegamento: toccandoli si apre la nota. Tenendo
/// premuto il testo, il menu offre "Crea nota" su quello scelto; su un
/// pezzo colorato offre invece di aprirne la nota o di togliere il colore.
class _DiaryDay extends StatefulWidget {
  const _DiaryDay({
    required this.day,
    required this.today,
    required this.initialText,
    required this.extracts,
    required this.onChanged,
    required this.onCreateNote,
    required this.onOpenNote,
    required this.onRemoveExtract,
    required this.expanded,
    required this.onToggle,
    this.tags = const [],
  });

  final DateTime day;
  final bool today;
  final String initialText;
  final List<DiaryExtract> extracts;

  /// Il testo nuovo e il cursore dopo la modifica.
  final void Function(String text, int caret) onChanged;

  /// "Crea nota" sul testo scelto; [from] se era già un pezzo colorato
  /// senza nota.
  final void Function(String text, int start, DiaryExtract? from) onCreateNote;
  final ValueChanged<String> onOpenNote;
  final ValueChanged<DiaryExtract> onRemoveExtract;

  /// I tag delle note nate dalle frasi del giorno, per la colonna a destra.
  final List<String> tags;

  /// Chiusa, la casella mostra solo le prime righe; toccandola o con la
  /// freccina si apre, e con la freccina si richiude ([onToggle]).
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_DiaryDay> createState() => _DiaryDayState();
}

class _DiaryDayState extends State<_DiaryDay> {
  late final _text = _HighlightController(
    text: widget.initialText,
    extracts: widget.extracts,
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_DiaryDay old) {
    super.didUpdateWidget(old);
    // Il campo si ridisegna subito dopo e rilegge i pezzi.
    _text.extracts = widget.extracts;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Il pezzo colorato toccato dalla selezione (o dal cursore), se c'è.
  ExtractRange? _hit(TextSelection selection) {
    if (!selection.isValid) return null;
    for (final range in extractRanges(_text.text, widget.extracts)) {
      final touches = selection.isCollapsed
          ? selection.baseOffset >= range.start &&
                selection.baseOffset < range.end
          : selection.start < range.end && range.start < selection.end;
      if (touches) return range;
    }
    return null;
  }

  void _run(EditableTextState state, VoidCallback action) {
    state.hideToolbar();
    // Tolta la selezione si vede il colore del pezzo.
    final selection = _text.selection;
    if (selection.isValid) {
      _text.selection = TextSelection.collapsed(offset: selection.start);
    }
    action();
  }

  /// Il menu della selezione. Su un pezzo colorato: "Apri nota" e "Togli
  /// colore" (o "Crea nota" se non è ancora una nota); altrove "Crea nota"
  /// sul testo scelto.
  Widget _menu(BuildContext context, EditableTextState state) {
    final l = context.l10n;
    final value = state.textEditingValue;
    final hit = _hit(value.selection);
    final selected = _selectedText(value);
    final extract = hit?.extract;
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: [
        if (extract == null && selected != null)
          ContextMenuButtonItem(
            label: l.diaryCreateNote,
            onPressed: () => _run(
              state,
              () => widget.onCreateNote(selected.text, selected.start, null),
            ),
          ),
        if (extract?.noteId case final id?)
          ContextMenuButtonItem(
            label: l.diaryOpenNote,
            onPressed: () => _run(state, () => widget.onOpenNote(id)),
          ),
        if (extract != null && extract.pending)
          ContextMenuButtonItem(
            label: l.diaryCreateNote,
            onPressed: () => _run(
              state,
              () => widget.onCreateNote(extract.text, hit!.start, extract),
            ),
          ),
        if (extract != null)
          ContextMenuButtonItem(
            label: l.diaryExtractRemove,
            onPressed: () => _run(state, () => widget.onRemoveExtract(extract)),
          ),
        ...state.contextMenuButtonItems,
      ],
    );
  }

  /// Richiusa una casella lunga, se il suo inizio è finito sopra lo
  /// schermo la lista ci salta, senza scorrere: si riprende a leggere da lì.
  void _showStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  /// Il campo per scrivere o, se la casella è chiusa, le prime righe del
  /// testo con i pezzi colorati, che si aprono toccandole. Se il testo non
  /// sta nelle prime righe, in fondo la freccina che apre o richiude la
  /// casella. Resta aperta mentre ci si scrive.
  Widget _content(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final style = LeviathanText.reading.copyWith(color: palette.text);
    final field = TextField(
      key: ValueKey('diary-field-${DiaryStore.key(widget.day)}'),
      controller: _text,
      focusNode: _focus,
      onChanged: (text) => widget.onChanged(
        text,
        _text.selection.isValid ? _text.selection.extentOffset : -1,
      ),
      contextMenuBuilder: _menu,
      minLines: LeviathanSizes.diaryMinLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: style,
      decoration: InputDecoration(
        hintText: widget.today ? l.diaryTodayHint : null,
        filled: false,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          vertical: LeviathanSpacing.md,
        ),
      ),
    );
    if (_text.text.isEmpty) return field;
    final key = DiaryStore.key(widget.day);
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = _text.buildTextSpan(
          context: context,
          style: style,
          withComposing: false,
        );
        final painter = TextPainter(
          text: span,
          maxLines: LeviathanSizes.diaryCollapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final cut = painter.didExceedMaxLines;
        painter.dispose();
        if (!cut) return field;
        final open = widget.expanded || _focus.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (open)
              field
            else
              GestureDetector(
                key: ValueKey('diary-collapsed-$key'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(top: LeviathanSpacing.md),
                  child: Text.rich(
                    span,
                    maxLines: LeviathanSizes.diaryCollapsedLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: ValueKey('diary-toggle-$key'),
                tooltip: open ? l.diaryCollapseDay : l.diaryExpandDay,
                visualDensity: VisualDensity.compact,
                iconSize: LeviathanIconSize.md,
                color: palette.muted,
                icon: Icon(open ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  if (open) {
                    _focus.unfocus();
                    _showStart();
                  }
                  widget.onToggle();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final dateColor = widget.today ? palette.accent : palette.muted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: LeviathanSizes.diaryDateColumn,
          child: Padding(
            padding: const EdgeInsets.only(top: LeviathanSpacing.md),
            child: Column(
              key: ValueKey('diary-date-${DiaryStore.key(widget.day)}'),
              children: [
                Text(
                  '${widget.day.day}',
                  style: LeviathanText.diaryDay.copyWith(color: dateColor),
                ),
                Text(
                  shortMonth(l, widget.day.month),
                  style: LeviathanText.meta.copyWith(color: dateColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: LeviathanSpacing.xs),
        Expanded(
          child: AnimatedContainer(
            duration: LeviathanDurations.quick,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(LeviathanRadii.lg),
              // Il bordo si accende mentre si scrive: si vede in che giorno.
              border: Border.all(
                color: _focus.hasFocus
                    ? palette.accent.withValues(
                        alpha: LeviathanOpacity.selection,
                      )
                    : palette.outline,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: LeviathanSpacing.lg,
            ),
            child: _content(context),
          ),
        ),
        const SizedBox(width: LeviathanSpacing.xs),
        // La colonna c'è sempre, anche vuota: così le caselle di tutti i
        // giorni hanno la stessa larghezza.
        SizedBox(
          width: LeviathanSizes.diaryTagColumn,
          child: Padding(
            padding: const EdgeInsets.only(top: LeviathanSpacing.md),
            child: Column(
              key: ValueKey('diary-tags-${DiaryStore.key(widget.day)}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final tag in widget.tags) _DiaryTag(tag)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Un tag nella colonna accanto a un giorno: il nome nel colore del tag,
/// troncato se non ci sta.
class _DiaryTag extends StatelessWidget {
  const _DiaryTag(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xs),
      child: Text(
        tag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: LeviathanText.diaryTag.copyWith(color: Tags.colorOf(tag)),
      ),
    );
  }
}

/// Il testo di un giorno con i pezzi diventati note sul fondo del colore del
/// loro primo tag (l'accento se non ne hanno), sottolineati.
class _HighlightController extends TextEditingController {
  _HighlightController({super.text, required this.extracts});

  List<DiaryExtract> extracts;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final ranges = extractRanges(text, extracts);
    if (ranges.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final spans = <TextSpan>[];
    var at = 0;
    for (final range in ranges) {
      if (range.start > at) {
        spans.add(TextSpan(text: text.substring(at, range.start)));
      }
      final tags = range.extract.tags;
      final color = tags.isEmpty
          ? context.palette.accent
          : Tags.colorOf(tags.first);
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: TextStyle(
            backgroundColor: color.withValues(alpha: LeviathanOpacity.extract),
            // Sottolineato come un collegamento: tenendolo premuto si apre
            // la nota.
            decoration: range.extract.noteId == null
                ? null
                : TextDecoration.underline,
            decorationColor: color,
          ),
        ),
      );
      at = range.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: spans);
  }
}

/// Quello che si sceglie nel foglio della nota nuova.
typedef NoteChoice = ({
  String title,
  List<String> tags,
  List<String> sources,
  bool isTask,

  /// Una nota di conoscenza (mai un task).
  bool knowledge,

  /// La scadenza del task; null se non ne ha.
  DateTime? due,
});

/// Il foglio in basso per fare una nota dal testo [text] del diario senza
/// lasciare la pagina: come nell'editor della home si sceglie se è una nota
/// o un task (con la sua scadenza) e se è conoscenza, poi titolo, tag e
/// fonti. Null se lo si chiude.
Future<NoteChoice?> showNoteSheet(
  BuildContext context,
  NotesController notes, {
  required String text,
  List<String> tags = const [],
  List<String> sources = const [],
}) {
  return showModalBottomSheet<NoteChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        _NoteSheet(notes: notes, text: text, tags: tags, sources: sources),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.notes,
    required this.text,
    required this.tags,
    required this.sources,
  });

  final NotesController notes;
  final String text;
  final List<String> tags;
  final List<String> sources;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _title = TextEditingController();
  bool _isTask = false;
  bool _knowledge = false;
  DateTime? _due;
  late List<String> _tags = [...widget.tags];
  late List<String> _sources = [...widget.sources];
  final _pendingTag = TextEditingController();
  final _pendingSource = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _pendingTag.dispose();
    _pendingSource.dispose();
    super.dispose();
  }

  void _done() {
    // Una voce scritta ma non confermata con virgola/invio vale comunque.
    Navigator.pop(context, (
      title: _title.text.trim(),
      tags: ChipKind.tags.withValue(
        _tags,
        _pendingTag.text,
        widget.notes.tagCounts.keys,
      ),
      sources: ChipKind.sources.withValue(
        _sources,
        _pendingSource.text,
        widget.notes.sourceCounts.keys,
      ),
      isTask: _isTask,
      knowledge: !_isTask && _knowledge,
      due: _isTask ? _due : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.xl,
            0,
            LeviathanSpacing.xl,
            LeviathanSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SegmentedButton<bool>(
                    key: const Key('note-sheet-kind'),
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(
                          Icons.notes,
                          size: LeviathanIconSize.sm,
                        ),
                        label: Text(l.kindNote),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(
                          Icons.check_box_outlined,
                          size: LeviathanIconSize.sm,
                        ),
                        label: Text(l.kindTask),
                      ),
                    ],
                    selected: {_isTask},
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelectionChanged: (s) =>
                        setState(() => _isTask = s.first),
                  ),
                  const SizedBox(width: LeviathanSpacing.xs),
                  // Solo le note possono essere conoscenza: con un task è
                  // spenta.
                  IconButton(
                    key: const Key('note-sheet-knowledge'),
                    tooltip: l.knowledge,
                    isSelected: !_isTask && _knowledge,
                    icon: const Icon(Icons.lightbulb_outline),
                    selectedIcon: Icon(Icons.lightbulb, color: palette.accent),
                    visualDensity: VisualDensity.compact,
                    onPressed: _isTask
                        ? null
                        : () => setState(() => _knowledge = !_knowledge),
                  ),
                ],
              ),
              TextField(
                key: const Key('note-sheet-title'),
                controller: _title,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: LeviathanText.editorTitle.copyWith(color: palette.text),
                decoration: InputDecoration(
                  hintText: _isTask
                      ? l.taskTitleHint
                      : _knowledge
                      ? l.knowledgeTitleHint
                      : l.titleHint,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: LeviathanSpacing.sm,
                  ),
                ),
              ),
              // Un task può avere una scadenza, scelta dal calendario.
              if (_isTask)
                DueDateRow(
                  due: _due,
                  onChanged: (due) => setState(() => _due = due),
                ),
              // Il testo scelto, come una citazione: è il corpo della nota.
              Container(
                padding: const EdgeInsets.only(left: LeviathanSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: palette.muted,
                      width: LeviathanSizes.outline,
                    ),
                  ),
                ),
                child: Text(
                  widget.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: LeviathanText.body.copyWith(color: palette.muted),
                ),
              ),
              const SizedBox(height: LeviathanSpacing.lg),
              ChipInput(
                kind: ChipKind.tags,
                fieldKey: const Key('note-sheet-tags'),
                values: _tags,
                onChanged: (tags) => setState(() => _tags = tags),
                counts: widget.notes.tagCounts,
                pending: _pendingTag,
              ),
              const SizedBox(height: LeviathanSpacing.md),
              ChipInput(
                kind: ChipKind.sources,
                fieldKey: const Key('note-sheet-sources'),
                values: _sources,
                onChanged: (sources) => setState(() => _sources = sources),
                counts: widget.notes.sourceCounts,
                pending: _pendingSource,
              ),
              const SizedBox(height: LeviathanSpacing.lg),
              FilledButton.icon(
                key: const Key('note-sheet-save'),
                onPressed: _done,
                icon: const Icon(Icons.check),
                label: Text(_isTask ? l.diaryCreateTask : l.diaryCreateNote),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
