import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/brain_dump.dart';
import '../state/notes_controller.dart';
import 'chip_input.dart';
import 'tag_color_sheet.dart';
import 'theme.dart';

/// "Svuota la testa": si scrive di getto tutto quello che c'è da fare, una
/// riga per cosa, e ogni riga diventa un task in "Da ordinare".
///
/// Le cose lasciate a metà continuano a tornare in mente finché non hanno un
/// posto; metterle tutte per iscritto in un colpo solo libera la testa, e
/// l'ordine si decide dopo con i confronti del task manager. I tag scelti
/// sotto valgono per tutti i task.
///
/// Restituisce quanti task ha creato; null se si chiude senza aggiungere.
class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final _text = TextEditingController();
  final _pendingTag = TextEditingController();
  List<String> _tags = [];

  List<String> get _titles => brainDumpTitles(_text.text);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _pendingTag.dispose();
    super.dispose();
  }

  void _add() {
    final titles = _titles;
    if (titles.isEmpty) return;
    final tags = ChipKind.tags.withValue(
      _tags,
      _pendingTag.text,
      widget.notes.tagCounts.keys,
    );
    widget.notes.createTasks(titles, tags: tags);
    Navigator.pop(context, titles.length);
  }

  /// Chiudendo con del testo scritto si chiede prima di buttarlo.
  Future<void> _confirmDiscard() async {
    final l = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.brainDumpDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('brain-dump-discard'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.brainDumpDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final count = _titles.length;
    return PopScope(
      canPop: _text.text.trim().isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: palette.background,
          title: Text(l.brainDump),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: LeviathanSpacing.sm),
              child: FilledButton(
                key: const Key('brain-dump-add'),
                onPressed: count == 0 ? null : _add,
                child: Text(l.brainDumpAddCount(count)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LeviathanSpacing.lg,
              LeviathanSpacing.xs,
              LeviathanSpacing.lg,
              LeviathanSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.brainDumpHelp,
                  style: LeviathanText.meta.copyWith(color: palette.muted),
                ),
                const SizedBox(height: LeviathanSpacing.md),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(LeviathanRadii.lg),
                      border: Border.all(color: palette.outline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LeviathanSpacing.lg,
                      ),
                      child: TextField(
                        key: const Key('brain-dump-field'),
                        controller: _text,
                        autofocus: true,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: LeviathanText.reading.copyWith(
                          color: palette.text,
                        ),
                        decoration: InputDecoration(
                          hintText: l.brainDumpHint,
                          hintMaxLines: 4,
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: LeviathanSpacing.md,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LeviathanSpacing.md),
                ChipInput(
                  kind: ChipKind.tags,
                  fieldKey: const Key('brain-dump-tags'),
                  values: _tags,
                  onChanged: (tags) => setState(() => _tags = tags),
                  counts: widget.notes.tagCounts,
                  pending: _pendingTag,
                  onLongPress: (tag) =>
                      showTagColorSheet(context, widget.notes, tag),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
