import 'note.dart';
import 'search.dart';
import 'tags.dart';

/// Come raggruppare task e note: per tag o per fonte.
enum NoteGrouping { tag, source }

/// I task (o le note) che condividono un tag o una fonte.
class NoteGroup {
  const NoteGroup(this.name, this.notes);

  /// Il tag o la fonte; null per chi non ne ha.
  final String? name;

  /// Dal più recente al più vecchio.
  final List<Note> notes;

  /// Quanti sono task ancora da fare.
  int get openTasks => notes.where((n) => n.isOpenTask).length;
}

/// Un solo tag o una sola fonte: il filtro del task manager.
class GroupFilter {
  const GroupFilter(this.by, this.name);

  final NoteGrouping by;
  final String name;

  bool matches(Note note) => groupsOf(note, by).contains(name);

  @override
  bool operator ==(Object other) =>
      other is GroupFilter && other.by == by && other.name == name;

  @override
  int get hashCode => Object.hash(by, name);
}

/// Vero se [note] sta in almeno uno dei gruppi di [filters]; senza filtri
/// passa tutto.
bool inAnyGroup(Note note, Set<GroupFilter> filters) =>
    filters.isEmpty || filters.any((f) => f.matches(note));

/// I gruppi in cui va [note]: i suoi tag o le sue fonti, oppure null se non
/// ne ha.
List<String?> groupsOf(Note note, NoteGrouping by) {
  final keys = switch (by) {
    NoteGrouping.tag => note.tags,
    NoteGrouping.source => note.sources,
  };
  return keys.isEmpty ? const [null] : keys;
}

/// Raggruppa per tag o per fonte le note di [notes] del tipo [kind]: i task,
/// le note o quelle di conoscenza. Fra i task tiene solo quelli che passano
/// [filter].
///
/// Un elemento con più tag (o fonti) compare in ogni gruppo. In cima i
/// gruppi con più task da fare (per i task; per i soli fatti, con più task)
/// o con più note; a parità, in ordine alfabetico. Con [alphabetical] conta
/// solo l'ordine alfabetico, così i gruppi non cambiano posto. Il gruppo di
/// chi non ha tag (o fonte) va in fondo.
List<NoteGroup> groupNotes(
  List<Note> notes,
  NoteGrouping by, {
  required NoteKind kind,
  TaskFilter filter = TaskFilter.task,
  bool alphabetical = false,
}) {
  final tasks = kind == NoteKind.task;
  final groups = <String?, List<Note>>{};
  for (final note in notes) {
    if (note.kind != kind) continue;
    if (tasks && !filter.matches(note)) continue;
    for (final key in groupsOf(note, by)) {
      (groups[key] ??= []).add(note);
    }
  }

  // Fra i soli task fatti non ce n'è da fare: conta quanti sono.
  int weight(NoteGroup g) =>
      tasks && filter != TaskFilter.fatto ? g.openTasks : g.notes.length;
  return [
    for (final entry in groups.entries)
      NoteGroup(
        entry.key,
        entry.value..sort((a, b) => b.created.compareTo(a.created)),
      ),
  ]..sort((a, b) {
    if (a.name == null || b.name == null) {
      return a.name == null ? (b.name == null ? 0 : 1) : -1;
    }
    if (!alphabetical) {
      final byWeight = weight(b).compareTo(weight(a));
      if (byWeight != 0) return byWeight;
    }
    return foldText(a.name!).compareTo(foldText(b.name!));
  });
}
