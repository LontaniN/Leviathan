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
});

/// Editor di una nota: titolo e corpo in grande, sotto tag e fonti.
///
/// Senza [initial] scrive una nota nuova e dopo il salvataggio si svuota.
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
    final tags = ChipKind.tags.withValue(_tags, _pendingTag.text,
        widget.tagCounts.keys);
    final sources = ChipKind.sources.withValue(_sources,
        _pendingSource.text, widget.sourceCounts.keys);
    final title = _title.text.trim();
    final body = _body.text.trimRight();
    if (title.isEmpty && body.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Scrivi almeno un titolo o un testo'),
      ));
      return;
    }
    widget.onSave((
      title: title,
      body: body,
      tags: tags,
      sources: sources,
    ));
    if (widget.initial == null) {
      _title.clear();
      _body.clear();
      _pendingTag.clear();
      _pendingSource.clear();
      setState(() {
        _tags = [];
        _sources = [];
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: LeviathanColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              children: [
                TextField(
                  key: const Key('title-field'),
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  style: text.titleLarge,
                  decoration: const InputDecoration(
                    hintText: 'Titolo',
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
        const SizedBox(height: 12),
        ChipInput(
          kind: ChipKind.tags,
          fieldKey: const Key('tag-field'),
          values: _tags,
          onChanged: (tags) => setState(() => _tags = tags),
          counts: widget.tagCounts,
          pending: _pendingTag,
        ),
        const SizedBox(height: 12),
        ChipInput(
          kind: ChipKind.sources,
          fieldKey: const Key('source-field'),
          values: _sources,
          onChanged: (sources) => setState(() => _sources = sources),
          counts: widget.sourceCounts,
          pending: _pendingSource,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
