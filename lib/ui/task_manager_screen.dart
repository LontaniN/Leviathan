import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/note.dart';
import '../model/task_order.dart';
import '../state/notes_controller.dart';
import 'note_screen.dart';
import 'task_check.dart';
import 'tag_bar.dart';
import 'task_compare_screen.dart';
import 'theme.dart';

/// Il task manager: uno spazio dove mettere in ordine i task per priorità,
/// senza badare a tag e fonti. Si apre dalla home, accanto al calendario.
///
/// Nella scheda "Da fare" i task aperti stanno in tre fasce (Ora, Prossimo,
/// Più avanti); la priorità è la posizione, non un'etichetta. Si trascina un
/// task (tenendolo premuto o dalla maniglia) per spostarlo nella fascia o fra
/// le fasce. I task nuovi arrivano in "Da ordinare", in cima, e si possono
/// sistemare rispondendo a qualche "Quale viene prima?" (vedi
/// [TaskCompareScreen]).
///
/// La scheda "Completati" mostra i task fatti, dal più recente.
class TaskManagerScreen extends StatelessWidget {
  const TaskManagerScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: palette.background,
          title: Text(l.taskManager),
          bottom: TabBar(
            labelColor: palette.text,
            unselectedLabelColor: palette.muted,
            indicatorColor: palette.accent,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: l.taskManagerOpenTab),
              Tab(text: l.taskManagerDoneTab),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: notes,
          builder: (context, _) {
            if (notes.error != null) {
              return _Message(icon: Icons.error_outline, text: notes.error!);
            }
            return TabBarView(
              children: [
                _OpenTab(notes: notes),
                _DoneTab(notes: notes),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _openNote(BuildContext context, NotesController notes, Note note) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NoteScreen(noteId: note.id, notes: notes),
    ),
  );
}

/// Una voce della lista "Da fare": l'intestazione di una fascia, un task o
/// il segnaposto di una fascia vuota.
sealed class _Entry {
  const _Entry();
}

class _Header extends _Entry {
  const _Header(this.band);

  /// null per "Da ordinare".
  final TaskBand? band;
}

class _Task extends _Entry {
  const _Task(this.note);
  final Note note;
}

class _Placeholder extends _Entry {
  const _Placeholder(this.band);
  final TaskBand band;
}

class _OpenTab extends StatelessWidget {
  const _OpenTab({required this.notes});

  final NotesController notes;

  List<_Entry> _entries(TaskBoard board) => [
    if (board.unsorted.isNotEmpty) ...[
      const _Header(null),
      for (final note in board.unsorted) _Task(note),
    ],
    for (final band in TaskBand.values) ...[
      _Header(band),
      for (final note in board.bands[band]!) _Task(note),
      if (board.bands[band]!.isEmpty) _Placeholder(band),
    ],
  ];

  /// Dove finisce un task trascinato ([newIndex] conta già senza di lui):
  /// la fascia è quella dell'intestazione
  /// sopra il punto di arrivo, e la posizione è contata fra i suoi task.
  void _onReorder(
    TaskBoard board,
    List<_Entry> entries,
    int oldIndex,
    int newIndex,
  ) {
    final moving = entries[oldIndex];
    if (moving is! _Task) return;
    final rest = [...entries]..removeAt(oldIndex);
    var target = newIndex.clamp(0, rest.length);
    // Sopra la prima intestazione vuol dire in cima alla prima fascia.
    if (target == 0) target = 1;
    TaskBand? band;
    var position = 0;
    for (var i = target - 1; i >= 0; i--) {
      final entry = rest[i];
      if (entry is _Header) {
        band = entry.band;
        break;
      }
      if (entry is _Task) position++;
    }
    final note = moving.note;
    final list = band == null ? board.unsorted : board.bands[band]!;
    // Mollato dove già stava: nessun file da riscrivere.
    if (note.band == band &&
        (band == null || list.indexWhere((n) => n.id == note.id) == position)) {
      return;
    }
    notes.place(note, band, list, position);
  }

  void _complete(BuildContext context, Note note) {
    final l = context.l10n;
    notes.setDone(note, true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.taskCompleted(note.displayTitle(l.untitled))),
          persist: false,
          duration: LeviathanDurations.undoSnackBar,
          action: SnackBarAction(
            label: l.undo,
            // Ripresa aggiornata: nel frattempo può essere cambiata.
            onPressed: () {
              final current = notes.byId(note.id);
              if (current != null) notes.setDone(current, false);
            },
          ),
        ),
      );
  }

  void _compare(BuildContext context, List<Note> queue) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TaskCompareScreen(
          notes: notes,
          queue: [for (final n in queue) n.id],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = TaskBoard.of(notes.notes);
    if (board.isEmpty) {
      return _Message(
        icon: Icons.low_priority,
        text: context.l10n.taskManagerEmpty,
      );
    }
    final entries = _entries(board);
    return ReorderableListView.builder(
      key: const Key('task-manager-list'),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xxxl),
      itemCount: entries.length,
      onReorderItem: (from, to) => _onReorder(board, entries, from, to),
      itemBuilder: (context, i) => switch (entries[i]) {
        _Header(:final band) => _BandHeader(
          key: ValueKey('band-${band?.key ?? 'unsorted'}'),
          band: band,
          count: band == null
              ? board.unsorted.length
              : board.bands[band]!.length,
          onSortAll: band == null && board.unsorted.length > 1
              ? () => _compare(context, board.unsorted)
              : null,
        ),
        _Placeholder(:final band) => _BandPlaceholder(
          key: ValueKey('band-empty-${band.key}'),
        ),
        _Task(:final note) => ReorderableDelayedDragStartListener(
          key: ValueKey(note.id),
          index: i,
          child: _TaskRow(
            note: note,
            onTap: () => _openNote(context, notes, note),
            onDone: () => _complete(context, note),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.band == null)
                  IconButton(
                    key: Key('compare-${note.id}'),
                    tooltip: context.l10n.sortByComparing,
                    icon: const Icon(Icons.compare_arrows),
                    color: context.palette.accent,
                    onPressed: () => _compare(context, [note]),
                  ),
                ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    label: context.l10n.dragToReorder,
                    child: Padding(
                      padding: const EdgeInsets.all(LeviathanSpacing.md),
                      child: Icon(
                        Icons.drag_handle,
                        key: Key('drag-${note.id}'),
                        size: LeviathanIconSize.md,
                        color: context.palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      },
    );
  }
}

String bandLabel(AppLocalizations l, TaskBand? band) => switch (band) {
  null => l.bandUnsorted,
  TaskBand.now => l.bandNow,
  TaskBand.next => l.bandNext,
  TaskBand.later => l.bandLater,
};

class _BandHeader extends StatelessWidget {
  const _BandHeader({
    super.key,
    required this.band,
    required this.count,
    this.onSortAll,
  });

  final TaskBand? band;
  final int count;
  final VoidCallback? onSortAll;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final over = band == TaskBand.now && count > nowLimit;
    final load = band == TaskBand.now
        ? l.bandLoad(count, nowLimit)
        : count > 0
        ? '$count'
        : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.lg,
        LeviathanSpacing.lg,
        LeviathanSpacing.sm,
        LeviathanSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                bandLabel(l, band).toUpperCase(),
                style: LeviathanText.caption.copyWith(
                  color: band == TaskBand.now ? palette.text : palette.muted,
                ),
              ),
              const SizedBox(width: LeviathanSpacing.sm),
              Text(
                load,
                key: band == TaskBand.now ? const Key('now-load') : null,
                style: LeviathanText.caption.copyWith(
                  color: over ? palette.accent : palette.muted,
                ),
              ),
              const Spacer(),
              if (onSortAll != null)
                TextButton.icon(
                  key: const Key('sort-all'),
                  onPressed: onSortAll,
                  icon: const Icon(
                    Icons.compare_arrows,
                    size: LeviathanIconSize.sm,
                  ),
                  label: Text(l.sortAll),
                ),
            ],
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: LeviathanSpacing.xs),
              child: Text(
                l.nowOverLimit(nowLimit),
                key: const Key('now-over-limit'),
                style: LeviathanText.meta.copyWith(color: palette.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _BandPlaceholder extends StatelessWidget {
  const _BandPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LeviathanSpacing.lg,
        vertical: LeviathanSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(LeviathanSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LeviathanRadii.cell),
          border: Border.all(
            color: muted.withValues(alpha: LeviathanOpacity.untagged),
          ),
        ),
        child: Text(
          context.l10n.bandEmpty,
          textAlign: TextAlign.center,
          style: LeviathanText.meta.copyWith(color: muted),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDone,
    this.meta,
    this.trailing,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Material(
      color: palette.background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: LeviathanSpacing.lg,
            right: LeviathanSpacing.xs,
          ),
          child: Row(
            children: [
              TagBar(note: note, height: LeviathanSizes.tagBarCompact),
              const SizedBox(width: LeviathanSpacing.sm),
              TaskCheck(note: note, onChanged: (_) => onDone()),
              const SizedBox(width: LeviathanSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: LeviathanSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.displayTitle(l.untitled),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: taskTitleStyle(
                          context,
                          note,
                          LeviathanText.title.copyWith(color: palette.text),
                        ),
                      ),
                      if (meta != null)
                        Text(
                          meta!,
                          style: LeviathanText.meta.copyWith(
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneTab extends StatelessWidget {
  const _DoneTab({required this.notes});

  final NotesController notes;

  static DateTime _when(Note note) => note.doneAt ?? note.updated;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = notes.notes.where((n) => n.isTask && n.done).toList()
      ..sort((a, b) => _when(b).compareTo(_when(a)));
    if (done.isEmpty) {
      return _Message(icon: Icons.task_alt, text: l.taskManagerDoneEmpty);
    }
    final now = DateTime.now();
    final items = <Object>[];
    String? section;
    for (final note in done) {
      final s = dateSection(l, _when(note), now);
      if (s != section) items.add(section = s);
      items.add(note);
    }
    return ListView.builder(
      key: const Key('task-manager-done'),
      padding: const EdgeInsets.only(bottom: LeviathanSpacing.xxxl),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        final String title => Padding(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.lg,
            LeviathanSpacing.lg,
            LeviathanSpacing.lg,
            LeviathanSpacing.xs,
          ),
          child: Text(
            title.toUpperCase(),
            style: LeviathanText.caption.copyWith(color: context.palette.muted),
          ),
        ),
        final Note note => _TaskRow(
          key: ValueKey(note.id),
          note: note,
          meta: formatRelative(l, _when(note), now),
          onTap: () => _openNote(context, notes, note),
          // Tolta la spunta torna nella sua fascia, al suo posto.
          onDone: () => notes.setDone(note, false),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.muted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: LeviathanIconSize.xl, color: muted),
            const SizedBox(height: LeviathanSpacing.lg),
            Text(
              text,
              textAlign: TextAlign.center,
              style: LeviathanText.body.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
