import 'dart:async';

import 'package:flutter/material.dart';

import '../data/draft_store.dart';
import '../l10n/l10n.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import 'chip_input.dart';
import 'theme.dart';

/// Quello che l'editor consegna quando si salva.
typedef NoteDraft = ({
  String title,
  String body,
  List<String> tags,
  List<String> sources,
  bool isTask,
});

/// Editor di una nota: titolo e corpo in grande, sotto tag e fonti.
///
/// In cima si sceglie se è una nota o un task da spuntare. Il corpo è
/// Markdown: mentre lo si scrive compare una barra di formattazione sopra la
/// tastiera, e un invio in un elenco lo continua. Senza [initial] scrive una
/// nota nuova e dopo il salvataggio si svuota.
///
/// Con [draft] quello che si scrive viene tenuto da parte poco dopo ogni
/// modifica (e subito se l'app va in secondo piano): riaprendo l'app la nota
/// non salvata è ancora lì. Senza [saveLabel] il pulsante dice "Salva nota".
class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    this.initial,
    required this.tagCounts,
    required this.sourceCounts,
    required this.onSave,
    this.saveLabel,
    this.draft,
  });

  final Note? initial;
  final Map<String, int> tagCounts;
  final Map<String, int> sourceCounts;
  final void Function(NoteDraft draft) onSave;
  final String? saveLabel;
  final DraftStore? draft;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> with WidgetsBindingObserver {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  late TextEditingValue _lastBody = _body.value;
  final _pendingTag = TextEditingController();
  final _pendingSource = TextEditingController();
  late List<String> _tags = [...?widget.initial?.tags];
  late List<String> _sources = [...?widget.initial?.sources];
  late bool _isTask = widget.initial?.isTask ?? false;

  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initial == null) _restoreDraft();
    _body.addListener(_onBodyChanged);
    _title.addListener(_scheduleDraft);
    _titleFocus.addListener(() => setState(() {}));
    _bodyFocus.addListener(() => setState(() {}));
  }

  void _restoreDraft() {
    final draft = widget.draft?.read();
    if (draft == null) return;
    _title.text = draft.title;
    _body.text = draft.body;
    _lastBody = _body.value;
    _tags = [...draft.tags];
    _sources = [...draft.sources];
    _isTask = draft.isTask;
  }

  /// La bozza si scrive poco dopo l'ultima modifica, non a ogni lettera.
  void _scheduleDraft() {
    if (widget.draft == null || widget.initial != null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(LeviathanDurations.draftSave, _writeDraft);
  }

  void _writeDraft() {
    _draftTimer?.cancel();
    _draftTimer = null;
    widget.draft?.write((
      title: _title.text,
      body: _body.text,
      tags: _tags,
      sources: _sources,
      isTask: _isTask,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android può chiudere l'app in secondo piano senza avvisare.
    if (state != AppLifecycleState.resumed && _draftTimer != null) {
      _writeDraft();
    }
  }

  void _onBodyChanged() {
    final next = continueList(_lastBody, _body.value);
    _lastBody = next;
    // Assegnare il valore richiama il listener, che a quel punto non trova
    // più un invio da completare.
    if (next != _body.value) _body.value = next;
    _scheduleDraft();
  }

  /// Si sta scrivendo titolo o corpo con la tastiera aperta: tag, fonti e
  /// pulsante scivolano via e resta solo il riquadro del testo, così mentre
  /// si sceglie il titolo si vede tutto il corpo. Chiudendo la tastiera col
  /// tasto indietro il campo resta attivo, ma tag, fonti e pulsante devono
  /// tornare visibili.
  ///
  /// L'altezza della tastiera si legge dalla finestra: lo Scaffold la toglie
  /// dal MediaQuery del suo contenuto.
  bool get _writingText =>
      (_titleFocus.hasFocus || _bodyFocus.hasFocus) &&
      View.of(context).viewInsets.bottom > 0;

  /// Il fuoco è su tag o fonti.
  bool _chipsFocused = false;

  /// Si scrivono tag o fonti con la tastiera aperta: il riquadro di titolo e
  /// corpo sparisce, così campi e suggerimenti hanno spazio. Il testo si
  /// scrive prima, quindi qui non serve vederlo.
  bool get _writingChips =>
      _chipsFocused && View.of(context).viewInsets.bottom > 0;

  /// Se c'era la tastiera all'ultimo controllo.
  bool _keyboardWasOpen = false;

  /// La tastiera si è aperta o chiusa. Le misure della finestra si leggono
  /// al frame successivo, quando sono definitive.
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final open = View.of(context).viewInsets.bottom > 0;
      // Chiusa in qualunque modo (freccia, tasto indietro): titolo e corpo
      // smettono di essere attivi, così tornano tag, fonti e pulsante e
      // sparisce la barra di formattazione.
      if (_keyboardWasOpen && !open) {
        _titleFocus.unfocus();
        _bodyFocus.unfocus();
      }
      _keyboardWasOpen = open;
      setState(() {});
    });
  }

  void _format(TextEditingValue Function(TextEditingValue) change) {
    _body.value = change(_body.value);
  }

  @override
  void dispose() {
    if (_draftTimer != null) _writeDraft();
    _title.dispose();
    _body.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _pendingTag.dispose();
    _pendingSource.dispose();
    super.dispose();
  }

  void _save() {
    // Una voce scritta ma non confermata con virgola/invio vale comunque.
    final tags = ChipKind.tags.withValue(
      _tags,
      _pendingTag.text,
      widget.tagCounts.keys,
    );
    final sources = ChipKind.sources.withValue(
      _sources,
      _pendingSource.text,
      widget.sourceCounts.keys,
    );
    final title = _title.text.trim();
    final body = _body.text.trimRight();
    if (title.isEmpty && body.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.writeSomething)));
      return;
    }
    widget.onSave((
      title: title,
      body: body,
      tags: tags,
      sources: sources,
      isTask: _isTask,
    ));
    if (widget.initial == null) {
      _title.clear();
      _body.clear();
      _pendingTag.clear();
      _pendingSource.clear();
      setState(() {
        _tags = [];
        _sources = [];
        _isTask = false;
      });
      _draftTimer?.cancel();
      _draftTimer = null;
      widget.draft?.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _form(text)),
        if (_bodyFocus.hasFocus) _FormatBar(onFormat: _format),
      ],
    );
  }

  /// Il modulo è fermo e riempie tutta l'altezza: il riquadro del corpo si
  /// allunga (o si accorcia con la tastiera) e il pulsante di salvataggio
  /// sta in fondo. Scorre solo il testo dentro il corpo.
  Widget _form(TextTheme text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.sm,
        LeviathanSpacing.sm,
        LeviathanSpacing.md,
        LeviathanSpacing.lg,
      ),
      child: _fields(text),
    );
  }

  Widget _textCard(TextTheme text) {
    final palette = context.palette;
    final focused = _titleFocus.hasFocus || _bodyFocus.hasFocus;
    return AnimatedContainer(
      duration: LeviathanDurations.quick,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(LeviathanRadii.lg),
        // Il bordo si accende mentre si scrive: si vede dove va il testo.
        border: Border.all(
          color: focused
              ? palette.accent.withValues(alpha: LeviathanOpacity.selection)
              : palette.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LeviathanSpacing.lg,
          LeviathanSpacing.xs,
          LeviathanSpacing.lg,
          LeviathanSpacing.sm,
        ),
        child: Column(
          children: [
            TextField(
              key: const Key('title-field'),
              focusNode: _titleFocus,
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              style: text.titleLarge,
              decoration: InputDecoration(
                hintText: _isTask
                    ? context.l10n.taskTitleHint
                    : context.l10n.titleHint,
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: LeviathanSpacing.md,
                ),
              ),
            ),
            const Divider(height: 1),
            // Il corpo occupa tutto il riquadro, così lo si tocca ovunque.
            Expanded(
              child: TextField(
                key: const Key('body-field'),
                controller: _body,
                focusNode: _bodyFocus,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: LeviathanText.reading.copyWith(color: palette.text),
                decoration: InputDecoration(
                  hintText: context.l10n.bodyHint,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: LeviathanSpacing.md,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fields(TextTheme text) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            key: const Key('kind-toggle'),
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.notes, size: LeviathanIconSize.sm),
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
            onSelectionChanged: (s) {
              setState(() => _isTask = s.first);
              _scheduleDraft();
            },
          ),
        ),
        const SizedBox(height: LeviathanSpacing.sm),
        if (_writingChips)
          const SizedBox.shrink()
        else
          Expanded(child: _textCard(text)),
        // Mentre si scrive titolo o corpo, tag, fonti e pulsante restano al loro
        // posto ma scivolano sotto la tastiera: non occupano spazio, così il
        // riquadro si allunga fino alla tastiera. Il widget è lo stesso nei
        // due casi, quindi quello che si stava scrivendo nei campi resta.
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _writingText ? 0 : 1,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (focused) =>
                  setState(() => _chipsFocused = focused),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: LeviathanSpacing.md),
                  ChipInput(
                    kind: ChipKind.tags,
                    fieldKey: const Key('tag-field'),
                    values: _tags,
                    onChanged: (tags) {
                      setState(() => _tags = tags);
                      _scheduleDraft();
                    },
                    counts: widget.tagCounts,
                    pending: _pendingTag,
                  ),
                  const SizedBox(height: LeviathanSpacing.md),
                  ChipInput(
                    kind: ChipKind.sources,
                    fieldKey: const Key('source-field'),
                    values: _sources,
                    onChanged: (sources) {
                      setState(() => _sources = sources);
                      _scheduleDraft();
                    },
                    counts: widget.sourceCounts,
                    pending: _pendingSource,
                  ),
                  const SizedBox(height: LeviathanSpacing.lg),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      widget.initial == null && _isTask
                          ? l.saveTask
                          : widget.saveLabel ?? l.saveNote,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// I pulsanti di formattazione Markdown, sopra la tastiera.
class _FormatBar extends StatelessWidget {
  const _FormatBar({required this.onFormat});

  final void Function(TextEditingValue Function(TextEditingValue)) onFormat;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget button(
      String tooltip,
      IconData icon,
      TextEditingValue Function(TextEditingValue) change,
    ) => IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: LeviathanIconSize.md),
      color: context.palette.text,
      visualDensity: VisualDensity.compact,
      onPressed: () => onFormat(change),
    );

    return DecoratedBox(
      key: const Key('format-bar'),
      decoration: BoxDecoration(color: context.palette.surface),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: LeviathanSpacing.xs),
        child: Row(
          children: [
            button(
              l.formatBold,
              Icons.format_bold,
              (v) => wrapSelection(v, '**'),
            ),
            button(
              l.formatItalic,
              Icons.format_italic,
              (v) => wrapSelection(v, '_'),
            ),
            button(
              l.formatHeading,
              Icons.title,
              (v) => toggleLinePrefix(v, LinePrefix.heading),
            ),
            button(
              l.formatBullets,
              Icons.format_list_bulleted,
              (v) => toggleLinePrefix(v, LinePrefix.bullet),
            ),
            button(
              l.formatNumbered,
              Icons.format_list_numbered,
              (v) => toggleLinePrefix(v, LinePrefix.numbered),
            ),
            button(
              l.formatChecklist,
              Icons.check_box_outlined,
              (v) => toggleLinePrefix(v, LinePrefix.checkbox),
            ),
            button(
              l.formatQuote,
              Icons.format_quote,
              (v) => toggleLinePrefix(v, LinePrefix.quote),
            ),
            button(l.formatCode, Icons.code, (v) => wrapSelection(v, '`')),
          ],
        ),
      ),
    );
  }
}
