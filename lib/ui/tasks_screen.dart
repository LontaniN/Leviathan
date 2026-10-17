import 'package:flutter/material.dart';

import '../model/note.dart';
import '../model/tags.dart';
import '../model/task_groups.dart';
import '../state/notes_controller.dart';
import 'home_screen.dart' show formatDate;
import 'note_screen.dart';
import 'task_check.dart';
import 'theme.dart';

/// Tutti i task del workspace, raggruppati per tag o per fonte a scelta.
/// In ogni gruppo prima quelli da fare, poi quelli eseguiti.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskGrouping _grouping = TaskGrouping.tag;

  void _open(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteScreen(noteId: note.id, notes: widget.notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        final groups = groupTasks(widget.notes.notes, _grouping);
        final openCount = widget.notes.notes.where((n) => n.isOpenTask).length;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.palette.background,
            title: const Text('Task'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LeviathanSpacing.lg,
                  0,
                  LeviathanSpacing.lg,
                  LeviathanSpacing.sm,
                ),
                // A tutta larghezza: ogni metà ha il suo spazio anche con
                // caratteri grandi.
                child: SegmentedButton<TaskGrouping>(
                  key: const Key('grouping-toggle'),
                  segments: const [
                    ButtonSegment(
                      value: TaskGrouping.tag,
                      icon: Icon(
                        Icons.sell_outlined,
                        size: LeviathanIconSize.sm,
                      ),
                      label: Text('Per tag'),
                    ),
                    ButtonSegment(
                      value: TaskGrouping.source,
                      icon: Icon(
                        Icons.person_outline,
                        size: LeviathanIconSize.sm,
                      ),
                      label: Text('Per fonte'),
                    ),
                  ],
                  selected: {_grouping},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelectionChanged: (s) =>
                      setState(() => _grouping = s.first),
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? const _Empty(
                        'Nessun task ancora: scrivine uno scegliendo "Task" '
                        'nell\'editor.',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(
                          bottom: LeviathanSpacing.xl,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: LeviathanSpacing.lg,
                              vertical: LeviathanSpacing.xs,
                            ),
                            child: Text(
                              openCount == 1
                                  ? '1 task da fare'
                                  : '$openCount task da fare',
                              style: LeviathanText.meta.copyWith(
                                color: context.palette.muted,
                              ),
                            ),
                          ),
                          for (final group in groups)
                            _GroupSection(
                              group: group,
                              grouping: _grouping,
                              onOpen: _open,
                              onToggleDone: widget.notes.setDone,
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Un gruppo: intestazione con tag o fonte e i suoi task.
class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.grouping,
    required this.onOpen,
    required this.onToggleDone,
  });

  final TaskGroup group;
  final TaskGrouping grouping;
  final ValueChanged<Note> onOpen;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    final name = group.name;
    final isTag = grouping == TaskGrouping.tag;
    final Widget marker = name == null
        ? Icon(
            isTag ? Icons.label_off_outlined : Icons.person_off_outlined,
            size: LeviathanIconSize.sm,
            color: context.palette.muted,
          )
        : isTag
        ? CircleAvatar(
            backgroundColor: Tags.colorOf(name),
            radius: LeviathanSpacing.xs,
          )
        : Icon(
            Icons.person_outline,
            size: LeviathanIconSize.sm,
            color: context.palette.muted,
          );
    final open = group.open.length;
    return Padding(
      padding: const EdgeInsets.only(top: LeviathanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LeviathanSpacing.lg,
              vertical: LeviathanSpacing.sm,
            ),
            child: Row(
              children: [
                marker,
                const SizedBox(width: LeviathanSpacing.sm),
                Expanded(
                  child: Text(
                    name ?? (isTag ? 'Senza tag' : 'Senza fonte'),
                    overflow: TextOverflow.ellipsis,
                    style: LeviathanText.title.copyWith(
                      color: name == null ? context.palette.muted : null,
                    ),
                  ),
                ),
                Text(
                  open == 0 ? 'tutti fatti' : '$open da fare',
                  style: LeviathanText.meta.copyWith(
                    color: open == 0
                        ? context.palette.muted
                        : context.palette.accent,
                  ),
                ),
              ],
            ),
          ),
          for (final note in [...group.open, ...group.done])
            _TaskTile(note: note, onOpen: onOpen, onToggleDone: onToggleDone),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.note,
    required this.onOpen,
    required this.onToggleDone,
  });

  final Note note;
  final ValueChanged<Note> onOpen;
  final void Function(Note note, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    final doneAt = note.doneAt;
    return InkWell(
      onTap: () => onOpen(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LeviathanSpacing.lg,
          vertical: LeviathanSpacing.sm,
        ),
        child: Row(
          children: [
            const SizedBox(width: LeviathanSpacing.lg),
            TaskCheck(
              note: note,
              onChanged: (done) => onToggleDone(note, done),
            ),
            const SizedBox(width: LeviathanSpacing.sm),
            Expanded(
              child: Text(
                note.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: taskTitleStyle(
                  context,
                  note,
                  Theme.of(context).textTheme.bodyLarge!,
                ),
              ),
            ),
            const SizedBox(width: LeviathanSpacing.sm),
            Text(
              note.done && doneAt != null
                  ? 'fatto ${formatDate(doneAt)}'
                  : formatDate(note.created),
              style: LeviathanText.meta.copyWith(color: context.palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted),
        ),
      ),
    );
  }
}
