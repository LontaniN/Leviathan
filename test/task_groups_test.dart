import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/task_groups.dart';

Note _task(
  String id, {
  List<String> tags = const [],
  List<String> sources = const [],
  bool done = false,
  int day = 1,
}) => Note(
  id: id,
  title: id,
  body: '',
  tags: tags,
  sources: sources,
  created: DateTime(2026, 1, day),
  updated: DateTime(2026, 1, day),
  isTask: true,
  done: done,
  doneAt: done ? DateTime(2026, 2, day) : null,
);

void main() {
  final notes = [
    _task('a', tags: ['studio'], sources: ['Anna'], day: 1),
    _task('b', tags: ['studio', 'casa'], day: 2),
    _task('c', tags: ['casa'], sources: ['Anna'], done: true, day: 3),
    _task('d', day: 4),
    // Le note normali non compaiono.
    Note(
      id: 'n',
      title: 'nota',
      body: '',
      tags: const ['studio'],
      sources: const [],
      created: DateTime(2026),
      updated: DateTime(2026),
    ),
  ];

  List<String> ids(List<Note> list) => list.map((n) => n.id).toList();

  test('per tag: più task da fare in cima, senza tag in fondo', () {
    final groups = groupTasks(notes, TaskGrouping.tag);
    expect(groups.map((g) => g.name), ['studio', 'casa', null]);
    expect(ids(groups[0].open), ['b', 'a']);
    expect(ids(groups[1].open), ['b']);
    expect(ids(groups[1].done), ['c']);
    expect(ids(groups[2].open), ['d']);
  });

  test('per fonte', () {
    final groups = groupTasks(notes, TaskGrouping.source);
    expect(groups.map((g) => g.name), ['Anna', null]);
    expect(ids(groups[0].open), ['a']);
    expect(ids(groups[0].done), ['c']);
    expect(ids(groups[1].open), ['d', 'b']);
  });

  test('senza task: nessun gruppo', () {
    expect(groupTasks(const [], TaskGrouping.tag), isEmpty);
  });
}
