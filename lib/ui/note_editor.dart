import 'package:flutter/material.dart';

import '../model/note.dart';
import '../model/tags.dart';
import 'tag_input.dart';
import 'theme.dart';

/// Quello che l'editor consegna quando si salva.
typedef NoteDraft = ({
  String title,
  String body,
  List<String> tags,
  String source,
});

/// Editor di una nota: titolo e corpo in grande, sotto tag e fonte.
///
/// Senza [initial] scrive una nota nuova e dopo il salvataggio si svuota.
class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    this.initial,
    required this.tagCounts,
    required this.onSave,
    this.saveLabel = 'Salva nota',
  });

  final Note? initial;
  final Map<String, int> tagCounts;
  final void Function(NoteDraft draft) onSave;
  final String saveLabel;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
  late final _source = TextEditingController(text: widget.initial?.source);
  final _pendingTag = TextEditingController();
  late List<String> _tags = [...?widget.initial?.tags];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _source.dispose();
    _pendingTag.dispose();
    super.dispose();
  }

  void _save() {
    // Un tag scritto ma non confermato con virgola/invio vale comunque.
    final pending = Tags.normalize(_pendingTag.text);
    final tags = [
      ..._tags,
      if (pending.isNotEmpty && !_tags.contains(pending)) pending,
    ];
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
      source: _source.text.trim(),
    ));
    if (widget.initial == null) {
      _title.clear();
      _body.clear();
      _source.clear();
      _pendingTag.clear();
      setState(() => _tags = []);
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
        TagInput(
          tags: _tags,
          onChanged: (tags) => setState(() => _tags = tags),
          tagCounts: widget.tagCounts,
          pending: _pendingTag,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('source-field'),
          controller: _source,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'Fonte (facoltativa)',
            prefixIcon: Icon(Icons.link, size: 20),
          ),
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
