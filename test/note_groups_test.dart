import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/note_groups.dart';
import 'package:leviathan/model/search.dart';

Note _note(
  String id, {
  List<String> tags = const [],
  List<String> sources = const [],
  bool isTask = false,
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
  isTask: isTask,
  done: done,
  doneAt: done ? DateTime(2026, 2, day) : null,
);

void main() {
  final notes = [
    _note('a', tags: ['studio'], sources: ['Anna'], isTask: true, day: 1),
    _note('b', tags: ['studio', 'casa'], isTask: true, day: 2),
    _note(
      'c',
      tags: ['casa'],
      sources: ['Anna'],
      isTask: true,
      done: true,
      day: 3,
    ),
    _note('d', isTask: true, day: 4),
    _note('n', tags: ['studio'], sources: ['Anna'], day: 5),
    _note('m', tags: ['studio', 'viaggi'], day: 6),
    _note('o', tags: ['viaggi'], sources: ['Bruno'], day: 7),
    _note('p', day: 8),
  ];

  List<String> ids(List<Note> list) => list.map((n) => n.id).toList();

  group('task', () {
    test('per tag: più task da fare in cima, senza tag in fondo', () {
      final groups = groupNotes(notes, NoteGrouping.tag, tasks: true);
      expect(groups.map((g) => g.name), ['studio', 'casa', null]);
      // Dal più recente, da fare o eseguito che sia.
      expect(ids(groups[0].notes), ['b', 'a']);
      expect(ids(groups[1].notes), ['c', 'b']);
      expect(groups[1].openTasks, 1);
      expect(ids(groups[2].notes), ['d']);
    });

    test('per fonte', () {
      final groups = groupNotes(notes, NoteGrouping.source, tasks: true);
      expect(groups.map((g) => g.name), ['Anna', null]);
      expect(ids(groups[0].notes), ['c', 'a']);
      expect(ids(groups[1].notes), ['d', 'b']);
    });

    test('solo da fare: i gruppi con soli task fatti spariscono', () {
      final groups = groupNotes(
        notes,
        NoteGrouping.source,
        tasks: true,
        filter: TaskFilter.aperto,
      );
      expect(groups.map((g) => g.name), ['Anna', null]);
      expect(ids(groups[0].notes), ['a']);
      expect(ids(groups[1].notes), ['d', 'b']);
    });

    test('solo fatti', () {
      final groups = groupNotes(
        notes,
        NoteGrouping.tag,
        tasks: true,
        filter: TaskFilter.fatto,
      );
      expect(groups.map((g) => g.name), ['casa']);
      expect(ids(groups[0].notes), ['c']);
    });

    test('senza task: nessun gruppo', () {
      expect(groupNotes(const [], NoteGrouping.tag, tasks: true), isEmpty);
    });
  });

  group('note', () {
    test('per tag: i task non compaiono, a parità in ordine alfabetico', () {
      final groups = groupNotes(notes, NoteGrouping.tag, tasks: false);
      expect(groups.map((g) => g.name), ['studio', 'viaggi', null]);
      expect(ids(groups[0].notes), ['m', 'n']);
      expect(ids(groups[1].notes), ['o', 'm']);
      expect(ids(groups[2].notes), ['p']);
    });

    test('per fonte', () {
      final groups = groupNotes(notes, NoteGrouping.source, tasks: false);
      expect(groups.map((g) => g.name), ['Anna', 'Bruno', null]);
      expect(ids(groups[2].notes), ['p', 'm']);
    });
  });
}
