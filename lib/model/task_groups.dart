import 'note.dart';
import 'tags.dart';

/// Come raggruppare i task: per tag o per fonte.
enum TaskGrouping { tag, source }

/// I task che condividono un tag (o una fonte).
class TaskGroup {
  const TaskGroup(this.name, this.open, this.done);

  /// Il tag o la fonte; null per i task che non ne hanno.
  final String? name;

  /// Da fare, dal più recente.
  final List<Note> open;

  /// Eseguiti, dall'ultimo spuntato.
  final List<Note> done;
}

/// Raggruppa i task di [notes] per tag o per fonte.
///
/// Un task con più tag (o fonti) compare in ogni gruppo. In cima i gruppi
/// con più task da fare; a parità, in ordine alfabetico. Il gruppo dei task
/// senza tag (o senza fonte) va in fondo.
List<TaskGroup> groupTasks(List<Note> notes, TaskGrouping by) {
  final open = <String?, List<Note>>{};
  final done = <String?, List<Note>>{};
  for (final note in notes) {
    if (!note.isTask) continue;
    final keys = switch (by) {
      TaskGrouping.tag => note.tags,
      TaskGrouping.source => note.sources,
    };
    final target = note.done ? done : open;
    for (final key in keys.isEmpty ? const <String?>[null] : keys) {
      (target[key] ??= []).add(note);
    }
  }

  final groups = [
    for (final key in {...open.keys, ...done.keys})
      TaskGroup(
        key,
        (open[key] ?? [])..sort((a, b) => b.created.compareTo(a.created)),
        (done[key] ?? [])..sort((a, b) {
          final at = a.doneAt ?? a.updated;
          final bt = b.doneAt ?? b.updated;
          return bt.compareTo(at);
        }),
      ),
  ];
  groups.sort((a, b) {
    if (a.name == null || b.name == null) {
      return a.name == null ? (b.name == null ? 0 : 1) : -1;
    }
    final byOpen = b.open.length.compareTo(a.open.length);
    if (byOpen != 0) return byOpen;
    return foldText(a.name!).compareTo(foldText(b.name!));
  });
  return groups;
}
