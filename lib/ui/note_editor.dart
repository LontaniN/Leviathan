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

class _NoteEditorState extends State<NoteEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
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
    _body.addListener(_onBodyChanged);
    _bodyFocus.addListener(() => setState(() {}));
  }

  void _onBodyChanged() {
    final next = continueList(_lastBody, _body.value);
    _lastBody = next;
    // Assegnare il valore richiama il listener, che a quel punto non trova
    // più un invio da completare.
    if (next != _body.value) _body.value = next;
  }

  void _format(TextEditingValue Function(TextEditingValue) change) {
    _body.value = change(_body.value);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
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

  Widget _form(TextTheme text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.sm,
        LeviathanSpacing.sm,
        LeviathanSpacing.md,
        LeviathanSpacing.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
        DecoratedBox(
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
                TextField(
                  key: const Key('body-field'),
                  controller: _body,
                  focusNode: _bodyFocus,
                  minLines: 10,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi la nota…',
                    filled: false,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            widget.initial == null && _isTask ? 'Salva task' : widget.saveLabel,
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
