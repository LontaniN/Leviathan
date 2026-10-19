import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'theme.dart';

/// Il foglio per scegliere il colore di [tag] o rinominarlo, aperto tenendo
/// premuto il tag. Colore e nome valgono per tutto il workspace.
///
/// Restituisce il nuovo nome se il tag è stato rinominato, così chi tiene
/// il tag in un filtro o in una bozza può aggiornarlo.
Future<String?> showTagColorSheet(
  BuildContext context,
  NotesController notes,
  String tag,
) async {
  final l = context.l10n;
  final rename = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final palette = sheetContext.palette;
      final current = Tags.colorOf(tag);
      final custom = Tags.custom.containsKey(tag);
      void pick(Color? color) {
        Navigator.pop(sheetContext);
        notes.setTagColor(tag, color);
      }

      return _Sheet(
        children: [
          Text(l.tagColorTitle(tag), style: LeviathanText.title),
          const SizedBox(height: LeviathanSpacing.lg),
          Wrap(
            spacing: LeviathanSpacing.md,
            runSpacing: LeviathanSpacing.md,
            children: [
              for (final color in Tags.palette)
                InkResponse(
                  key: Key('tag-color-${color.toARGB32()}'),
                  onTap: () => pick(color),
                  radius: LeviathanSizes.tagSwatch / 2,
                  child: Container(
                    width: LeviathanSizes.tagSwatch,
                    height: LeviathanSizes.tagSwatch,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: color == current
                          ? Border.all(
                              color: palette.text,
                              width: LeviathanSizes.selectedOutline,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LeviathanSpacing.md),
          if (custom)
            ListTile(
              key: const Key('tag-color-auto'),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Tags.autoColorOf(tag),
                radius: LeviathanSizes.tagDot,
              ),
              title: Text(l.tagColorAuto),
              onTap: () => pick(null),
            ),
          _RenameTile(key: const Key('tag-rename'), sheetContext: sheetContext),
        ],
      );
    },
  );
  if (rename != true || !context.mounted) return null;
  final name = await _askName(
    context,
    title: l.renameTagTitle(tag),
    initial: tag,
    canonical: (raw) => Tags.normalize(raw),
    existing: notes.tagCounts.keys,
  );
  if (name == null || name == tag) return null;
  notes.renameTag(tag, name);
  return name;
}

/// Il foglio di una fonte, aperto tenendo premuta la fonte: per ora serve a
/// rinominarla in tutto il workspace. Restituisce il nuovo nome, come
/// [showTagColorSheet].
Future<String?> showSourceSheet(
  BuildContext context,
  NotesController notes,
  String source,
) async {
  final l = context.l10n;
  final rename = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _Sheet(
      children: [
        Text(source, style: LeviathanText.title),
        const SizedBox(height: LeviathanSpacing.sm),
        _RenameTile(
          key: const Key('source-rename'),
          sheetContext: sheetContext,
        ),
      ],
    ),
  );
  if (rename != true || !context.mounted) return null;
  final others = notes.sourceCounts.keys.where((s) => s != source);
  final name = await _askName(
    context,
    title: l.renameSourceTitle(source),
    initial: source,
    canonical: (raw) => Sources.canonical(raw, others),
    existing: others,
  );
  if (name == null || name == source) return null;
  notes.renameSource(source, name);
  return name;
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LeviathanSpacing.xl,
          0,
          LeviathanSpacing.xl,
          LeviathanSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Chiude il foglio chiedendo di rinominare.
class _RenameTile extends StatelessWidget {
  const _RenameTile({super.key, required this.sheetContext});

  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_outlined, size: LeviathanIconSize.md),
      title: Text(context.l10n.rename),
      onTap: () => Navigator.pop(sheetContext, true),
    );
  }
}

/// Chiede il nuovo nome; null se si annulla o il nome non è valido.
/// [canonical] dà la forma salvata, [existing] le voci con cui si unirebbe.
Future<String?> _askName(
  BuildContext context, {
  required String title,
  required String initial,
  required String Function(String raw) canonical,
  required Iterable<String> existing,
}) => showDialog<String>(
  context: context,
  builder: (_) => _RenameDialog(
    title: title,
    initial: initial,
    canonical: canonical,
    existing: existing,
  ),
);

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({
    required this.title,
    required this.initial,
    required this.canonical,
    required this.existing,
  });

  final String title;
  final String initial;
  final String Function(String raw) canonical;
  final Iterable<String> existing;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = widget.canonical(_controller.text);
    final valid = name.isNotEmpty;
    void submit() {
      if (valid) Navigator.pop(context, name);
    }

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('rename-field'),
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => submit(),
        decoration: InputDecoration(
          helperText: !valid || name == widget.initial
              ? null
              : widget.existing.contains(name)
              ? l.renameMerges(name)
              : name != _controller.text.trim()
              ? l.savedAs(name)
              : null,
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('rename-confirm'),
          onPressed: valid ? submit : null,
          child: Text(l.rename),
        ),
      ],
    );
  }
}
