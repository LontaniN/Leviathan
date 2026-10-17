import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/demo_notes.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/tag_calendar.dart';

Note _note(String id, DateTime created, List<String> tags) => Note(
  id: id,
  title: id,
  body: '',
  tags: tags,
  sources: const [],
  created: created,
  updated: created,
);

void main() {
  final notes = [
    _note('a', DateTime(2026, 3, 1, 9), ['studio', 'idee']),
    _note('b', DateTime(2026, 3, 1, 22), ['studio']),
    _note('c', DateTime(2026, 3, 2, 10), ['casa']),
    _note('d', DateTime(2026, 3, 2, 11), []),
    _note('e', DateTime(2026, 4, 5), ['casa']),
  ];

  test('per giorno: conta le note per tag, ordinati dal più usato', () {
    final days = tallyByDay(notes);
    expect(days.keys, [
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 2),
      DateTime(2026, 4, 5),
    ]);
    final first = days[DateTime(2026, 3, 1)]!;
    expect(first.notes, 2);
    expect(first.ranked().map((e) => (e.key, e.value)), [
      ('studio', 2),
      ('idee', 1),
    ]);
    // Anche le note senza tag contano come note del giorno.
    expect(days[DateTime(2026, 3, 2)]!.notes, 2);
  });

  test('per mese', () {
    final months = tallyByMonth(notes);
    expect(months.keys, [DateTime(2026, 3), DateTime(2026, 4)]);
    expect(months[DateTime(2026, 3)]!.ranked().map((e) => (e.key, e.value)), [
      ('studio', 2),
      ('casa', 1),
      ('idee', 1),
    ]);
  });

  test('dati di prova: tutto l\'anno, sempre uguali', () {
    final demo = demoNotes(2026);
    expect(demo, isNotEmpty);
    expect(demo.every((n) => n.created.year == 2026), isTrue);
    expect(tallyByMonth(demo).length, 12);
    expect(demoNotes(2026).length, demo.length);
  });
}
