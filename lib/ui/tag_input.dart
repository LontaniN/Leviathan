import 'package:flutter/material.dart';

import '../model/tags.dart';
import 'theme.dart';

/// Pallino colorato + nome: come appare un tag in tutta l'app.
class TagChip extends StatelessWidget {
  const TagChip(this.tag, {super.key, this.onDeleted, this.dense = false});

  final String tag;
  final VoidCallback? onDeleted;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = Tags.colorOf(tag);
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: dense ? 4 : 5),
      label: Text(tag, style: TextStyle(fontSize: dense ? 11 : 13)),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize:
          dense ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
      padding: dense ? EdgeInsets.zero : null,
      labelPadding: dense ? const EdgeInsets.only(left: 2, right: 6) : null,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      backgroundColor: LeviathanColors.surface,
    );
  }
}

/// Campo per i tag: i tag confermati diventano chip, mentre si scrive
/// compaiono i tag esistenti più simili.
///
/// Un tag si conferma con virgola, invio o toccando un suggerimento. Il testo
/// non ancora confermato resta in [pending]: chi salva la nota lo aggiunge.
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    required this.tagCounts,
    required this.pending,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final Map<String, int> tagCounts;
  final TextEditingController pending;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.pending.addListener(_onText);
  }

  @override
  void dispose() {
    widget.pending.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    final text = widget.pending.text;
    if (text.contains(',')) {
      final parts = text.split(',');
      for (final part in parts.take(parts.length - 1)) {
        _add(part, clear: false);
      }
      widget.pending.text = parts.last;
    }
    setState(() {});
  }

  void _add(String raw, {bool clear = true}) {
    final tag = Tags.normalize(raw);
    if (tag.isNotEmpty && !widget.tags.contains(tag)) {
      widget.onChanged([...widget.tags, tag]);
    }
    if (clear) widget.pending.clear();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = Tags.suggest(
      widget.pending.text,
      widget.tagCounts,
      exclude: widget.tags,
    );
    final typed = Tags.normalize(widget.pending.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('tag-field'),
          controller: widget.pending,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Tag (virgola o invio per aggiungere)',
            prefixIcon: const Icon(Icons.sell_outlined, size: 20),
            helperText: typed.isNotEmpty && typed != widget.pending.text.trim()
                ? 'Verrà salvato come: $typed'
                : null,
          ),
          onSubmitted: (value) {
            _add(value);
            _focus.requestFocus();
          },
        ),
        if (_focus.hasFocus && suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in suggestions)
                  ActionChip(
                    avatar: CircleAvatar(
                        backgroundColor: Tags.colorOf(tag), radius: 5),
                    label: Text('$tag  ${widget.tagCounts[tag]}'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _add(tag),
                  ),
              ],
            ),
          ),
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in widget.tags)
                  TagChip(
                    tag,
                    onDeleted: () => widget.onChanged(
                        widget.tags.where((t) => t != tag).toList()),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
