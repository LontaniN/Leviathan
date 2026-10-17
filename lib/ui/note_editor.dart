import 'package:flutter/material.dart';

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
/// In cima si sceglie se è una nota o un task da spuntare. Senza [initial]
/// scrive una nota nuova e dopo il salvataggio si svuota.
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
  final _pendingTag = TextEditingController();
  final _pendingSource = TextEditingController();
  late List<String> _tags = [...?widget.initial?.tags];
  late List<String> _sources = [...?widget.initial?.sources];
  late bool _isTask = widget.initial?.isTask ?? false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
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
