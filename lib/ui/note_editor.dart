import 'package:flutter/material.dart';

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
class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    this.initial,
    required this.tagCounts,
    required this.sourceCounts,
    required this.onSave,
    this.saveLabel = 'Salva nota',
  });

  final Note? initial;
  final Map<String, int> tagCounts;
  final Map<String, int> sourceCounts;
  final void Function(NoteDraft draft) onSave;
  final String saveLabel;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _body.addListener(_onBodyChanged);
    _titleFocus.addListener(() => setState(() {}));
    _bodyFocus.addListener(() => setState(() {}));
  }

  void _onBodyChanged() {
    final next = continueList(_lastBody, _body.value);
    _lastBody = next;
    // Assegnare il valore richiama il listener, che a quel punto non trova
    // più un invio da completare.
    if (next != _body.value) _body.value = next;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scrivi almeno un titolo o un testo')),
      );
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LeviathanSpacing.md,
          LeviathanSpacing.xs,
          LeviathanSpacing.md,
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
                hintText: _isTask ? 'Cosa c\'è da fare?' : 'Titolo',
                filled: false,
                border: InputBorder.none,
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
                decoration: const InputDecoration(
                  hintText: 'Scrivi la nota…',
                  filled: false,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fields(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            key: const Key('kind-toggle'),
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.notes, size: LeviathanIconSize.sm),
                label: Text('Nota'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(
                  Icons.check_box_outlined,
                  size: LeviathanIconSize.sm,
                ),
                label: Text('Task'),
              ),
            ],
            selected: {_isTask},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (s) => setState(() => _isTask = s.first),
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
                    onChanged: (tags) => setState(() => _tags = tags),
                    counts: widget.tagCounts,
                    pending: _pendingTag,
                  ),
                  const SizedBox(height: LeviathanSpacing.md),
                  ChipInput(
                    kind: ChipKind.sources,
                    fieldKey: const Key('source-field'),
                    values: _sources,
                    onChanged: (sources) => setState(() => _sources = sources),
                    counts: widget.sourceCounts,
                    pending: _pendingSource,
                  ),
                  const SizedBox(height: LeviathanSpacing.lg),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      widget.initial == null && _isTask
                          ? 'Salva task'
                          : widget.saveLabel,
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
              'Grassetto',
              Icons.format_bold,
              (v) => wrapSelection(v, '**'),
            ),
            button(
              'Corsivo',
              Icons.format_italic,
              (v) => wrapSelection(v, '_'),
            ),
            button(
              'Titolo',
              Icons.title,
              (v) => toggleLinePrefix(v, LinePrefix.heading),
            ),
            button(
              'Elenco puntato',
              Icons.format_list_bulleted,
              (v) => toggleLinePrefix(v, LinePrefix.bullet),
            ),
            button(
              'Elenco numerato',
              Icons.format_list_numbered,
              (v) => toggleLinePrefix(v, LinePrefix.numbered),
            ),
            button(
              'Checklist',
              Icons.check_box_outlined,
              (v) => toggleLinePrefix(v, LinePrefix.checkbox),
            ),
            button(
              'Citazione',
              Icons.format_quote,
              (v) => toggleLinePrefix(v, LinePrefix.quote),
            ),
            button('Codice', Icons.code, (v) => wrapSelection(v, '`')),
          ],
        ),
      ),
    );
  }
}
