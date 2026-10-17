import 'package:flutter/material.dart';

import '../model/search.dart';
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
    return _BaseChip(
      label: tag,
      avatar: CircleAvatar(backgroundColor: color, radius: dense ? 4 : 5),
      borderColor: color.withValues(alpha: 0.5),
      onDeleted: onDeleted,
      dense: dense,
    );
  }
}

/// Icona persona + nome, in grigio: le fonti non hanno colori.
class SourceChip extends StatelessWidget {
  const SourceChip(
    this.source, {
    super.key,
    this.onDeleted,
    this.dense = false,
  });

  final String source;
  final VoidCallback? onDeleted;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return _BaseChip(
      label: source,
      avatar: Icon(
        Icons.person_outline,
        size: dense ? 12 : 16,
        color: context.palette.muted,
      ),
      borderColor: context.palette.muted.withValues(alpha: 0.4),
      onDeleted: onDeleted,
      dense: dense,
    );
  }
}

/// Casella + stato: il filtro `stato:` della ricerca.
class StatusChip extends StatelessWidget {
  const StatusChip(this.filter, {super.key, this.onDeleted});

  final TaskFilter filter;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.accent;
    return _BaseChip(
      label: filter.label,
      avatar: Icon(
        Icons.check_box_outlined,
        size: LeviathanIconSize.sm,
        color: color,
      ),
      borderColor: color.withValues(alpha: 0.5),
      onDeleted: onDeleted,
      dense: false,
    );
  }
}

class _BaseChip extends StatelessWidget {
  const _BaseChip({
    required this.label,
    required this.avatar,
    required this.borderColor,
    required this.onDeleted,
    required this.dense,
  });

  final String label;
  final Widget avatar;
  final Color borderColor;
  final VoidCallback? onDeleted;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: avatar,
      label: Text(label, style: TextStyle(fontSize: dense ? 11 : 13)),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: dense
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      padding: dense ? EdgeInsets.zero : null,
      labelPadding: dense ? const EdgeInsets.only(left: 2, right: 6) : null,
      side: BorderSide(color: borderColor),
      backgroundColor: context.palette.surface,
    );
  }
}

/// Come si comporta un [ChipInput]: tag e fonti differiscono solo in questo.
class ChipKind {
  const ChipKind({
    required this.hint,
    required this.icon,
    required this.canonical,
    required this.suggest,
    required this.chip,
    required this.suggestionAvatar,
  });

  final String hint;
  final IconData icon;

  /// Trasforma il testo scritto nella voce da salvare ('' = scarta).
  final String Function(String raw, Iterable<String> known) canonical;
  final List<String> Function(
    String input,
    Map<String, int> counts,
    Iterable<String> exclude,
  )
  suggest;
  final Widget Function(String value, VoidCallback onDeleted) chip;
  final Widget Function(String value) suggestionAvatar;

  /// [values] con in più la voce scritta in [raw], se valida e nuova.
  /// [known] sono le voci già usate nel workspace, per riusarne la grafia.
  List<String> withValue(
    List<String> values,
    String raw,
    Iterable<String> known,
  ) {
    final value = canonical(raw, [...values, ...known]);
    if (value.isEmpty || values.contains(value)) return values;
    return [...values, value];
  }

  static final tags = ChipKind(
    hint: 'Tag (virgola o invio per aggiungere)',
    icon: Icons.sell_outlined,
    canonical: (raw, _) => Tags.normalize(raw),
    suggest: (input, counts, exclude) =>
        Tags.suggest(input, counts, exclude: exclude),
    chip: (value, onDeleted) => TagChip(value, onDeleted: onDeleted),
    suggestionAvatar: (value) =>
        CircleAvatar(backgroundColor: Tags.colorOf(value), radius: 5),
  );

  static final sources = ChipKind(
    hint: 'Fonti, es. persone (virgola o invio)',
    icon: Icons.person_outline,
    canonical: Sources.canonical,
    suggest: (input, counts, exclude) =>
        Sources.suggest(input, counts, exclude: exclude),
    chip: (value, onDeleted) => SourceChip(value, onDeleted: onDeleted),
    suggestionAvatar: (_) => Builder(
      builder: (context) =>
          Icon(Icons.person_outline, size: 16, color: context.palette.muted),
    ),
  );
}

/// Campo a chip: le voci confermate diventano chip, mentre si scrive
/// compaiono le voci esistenti più simili.
///
/// Una voce si conferma con virgola, invio o toccando un suggerimento. Il
/// testo non ancora confermato resta in [pending]: chi salva la nota lo
/// aggiunge con [ChipKind.canonical].
class ChipInput extends StatefulWidget {
  const ChipInput({
    super.key,
    required this.kind,
    required this.values,
    required this.onChanged,
    required this.counts,
    required this.pending,
    this.fieldKey,
  });

  final ChipKind kind;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final Map<String, int> counts;
  final TextEditingController pending;
  final Key? fieldKey;

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
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
      var values = widget.values;
      for (final part in parts.take(parts.length - 1)) {
        values = _with(values, part);
      }
      if (values != widget.values) widget.onChanged(values);
      widget.pending.text = parts.last;
    }
    setState(() {});
  }

  List<String> _with(List<String> values, String raw) =>
      widget.kind.withValue(values, raw, widget.counts.keys);

  void _add(String raw) {
    final values = _with(widget.values, raw);
    if (values != widget.values) widget.onChanged(values);
    widget.pending.clear();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final suggestions = kind.suggest(
      widget.pending.text,
      widget.counts,
      widget.values,
    );
    final typed = kind.canonical(widget.pending.text, widget.counts.keys);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: widget.pending,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          textCapitalization: kind == ChipKind.sources
              ? TextCapitalization.words
              : TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: kind.hint,
            prefixIcon: Icon(kind.icon, size: 20),
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
                for (final value in suggestions)
                  ActionChip(
                    avatar: kind.suggestionAvatar(value),
                    label: Text('$value  ${widget.counts[value]}'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _add(value),
                  ),
              ],
            ),
          ),
        if (widget.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in widget.values)
                  kind.chip(
                    value,
                    () => widget.onChanged(
                      widget.values.where((v) => v != value).toList(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
