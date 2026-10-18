import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/note.dart';
import '../model/task_order.dart';
import '../state/notes_controller.dart';
import 'tag_bar.dart';
import 'task_manager_screen.dart';
import 'theme.dart';

/// Sistema i task di [queue] nel task manager, uno alla volta, a domande.
///
/// Prima si sceglie la fascia, poi si risponde a "Quale viene prima?" fra il
/// task nuovo e uno già nella fascia: ogni risposta dimezza i posti
/// possibili (vedi [BinaryInsertion]), così anche con molti task bastano
/// poche domande. Confrontare due cose alla volta è più affidabile che dare
/// a ciascuna un voto.
///
/// "Salta" lascia il task fra quelli da ordinare e passa al prossimo;
/// chiudendo la schermata quello in corso resta dov'era.
class TaskCompareScreen extends StatefulWidget {
  const TaskCompareScreen({
    super.key,
    required this.notes,
    required this.queue,
  });

  final NotesController notes;

  /// Gli id dei task da sistemare, in ordine.
  final List<String> queue;

  @override
  State<TaskCompareScreen> createState() => _TaskCompareScreenState();
}

class _TaskCompareScreenState extends State<TaskCompareScreen> {
  var _next = 0;
  Note? _task;
  TaskBand? _band;
  BinaryInsertion? _insertion;

  @override
  void initState() {
    super.initState();
    _advance();
  }

  /// Passa al prossimo task della coda ancora aperto; chiude a coda finita.
  void _advance() {
    _band = null;
    _insertion = null;
    _task = null;
    while (_next < widget.queue.length) {
      final note = widget.notes.byId(widget.queue[_next++]);
      if (note != null && note.isOpenTask) {
        _task = note;
        return;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  List<Note> _bandList(TaskBand band) => [
    for (final n in TaskBoard.of(widget.notes.notes).bands[band]!)
      if (n.id != _task!.id) n,
  ];

  void _chooseBand(TaskBand band) {
    final list = _bandList(band);
    setState(() {
      _band = band;
      _insertion = BinaryInsertion(list);
    });
    _placeIfDone();
  }

  void _answer({required bool before}) {
    setState(() => _insertion!.answer(before: before));
    _placeIfDone();
  }

  void _placeIfDone() {
    final insertion = _insertion!;
    if (!insertion.isDone) return;
    widget.notes.place(_task!, _band, insertion.list, insertion.index);
    setState(_advance);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final task = _task;
    final insertion = _insertion;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.palette.background,
        title: Text(l.sortByComparing),
        actions: [
          if (task != null)
            TextButton(
              key: const Key('compare-skip'),
              onPressed: () => setState(_advance),
              child: Text(l.compareSkip),
            ),
        ],
      ),
      body: task == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(LeviathanSpacing.lg),
                child: insertion == null || insertion.isDone
                    ? _BandChoice(task: task, onChosen: _chooseBand)
                    : _Question(
                        task: task,
                        pivot: insertion.pivot!,
                        band: _band!,
                        remaining: insertion.remaining,
                        onAnswer: _answer,
                      ),
              ),
            ),
    );
  }
}

class _BandChoice extends StatelessWidget {
  const _BandChoice({required this.task, required this.onChosen});

  final Note task;
  final ValueChanged<TaskBand> onChosen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(note: task, label: l.compareNewTask),
        const SizedBox(height: LeviathanSpacing.xl),
        Text(
          l.compareChooseBand,
          style: LeviathanText.title.copyWith(color: context.palette.text),
        ),
        const SizedBox(height: LeviathanSpacing.md),
        for (final band in TaskBand.values)
          Padding(
            padding: const EdgeInsets.only(bottom: LeviathanSpacing.sm),
            child: OutlinedButton(
              key: Key('choose-${band.key}'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(LeviathanSizes.button),
              ),
              onPressed: () => onChosen(band),
              child: Text(bandLabel(l, band)),
            ),
          ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.task,
    required this.pivot,
    required this.band,
    required this.remaining,
    required this.onAnswer,
  });

  final Note task;
  final Note pivot;
  final TaskBand band;
  final int remaining;
  final void Function({required bool before}) onAnswer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.compareQuestion,
          style: LeviathanText.heading.copyWith(color: palette.text),
        ),
        const SizedBox(height: LeviathanSpacing.xs),
        Text(
          '${bandLabel(l, band)} · ${l.compareQuestionsLeft(remaining)}',
          style: LeviathanText.meta.copyWith(color: palette.muted),
        ),
        const SizedBox(height: LeviathanSpacing.xl),
        _Card(
          key: const Key('compare-new'),
          note: task,
          label: l.compareNewTask,
          onTap: () => onAnswer(before: true),
        ),
        const SizedBox(height: LeviathanSpacing.md),
        _Card(
          key: const Key('compare-pivot'),
          note: pivot,
          label: bandLabel(l, band),
          onTap: () => onAnswer(before: false),
        ),
      ],
    );
  }
}

/// Un task da confrontare: la barretta del tag, un'etichetta e il titolo.
class _Card extends StatelessWidget {
  const _Card({super.key, required this.note, required this.label, this.onTap});

  final Note note;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(LeviathanRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: onTap == null ? 0 : LeviathanSizes.compareCard,
          ),
          child: Padding(
            padding: const EdgeInsets.all(LeviathanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: LeviathanText.caption.copyWith(color: palette.muted),
                ),
                const SizedBox(height: LeviathanSpacing.sm),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TagBar(note: note, height: LeviathanSizes.tagBarCompact),
                      const SizedBox(width: LeviathanSpacing.md),
                      Expanded(
                        child: Text(
                          note.displayTitle(l.untitled),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: LeviathanText.title.copyWith(
                            color: palette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
