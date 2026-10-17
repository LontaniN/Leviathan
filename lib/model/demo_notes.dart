import 'dart:math' as math;

import 'note.dart';

/// Note finte per provare il calendario quando i dati veri sono pochi.
///
/// Restano in memoria: non vengono mai scritte nel workspace. Con lo stesso
/// [seed] escono sempre le stesse note, così le schermate sono confrontabili.
List<Note> demoNotes(int year, {int seed = 2026}) {
  final random = math.Random(seed);
  final notes = <Note>[];
  var day = DateTime(year);
  while (day.year == year) {
    final weekend = day.weekday >= DateTime.saturday;
    final count = random.nextInt(weekend ? 3 : 6);
    for (var i = 0; i < count; i++) {
      final tags = _pickTags(random, day.month);
      final created = day.add(
        Duration(hours: 8 + random.nextInt(14), minutes: random.nextInt(60)),
      );
      notes.add(
        Note(
          id: 'demo-${notes.length}',
          title: 'Nota di prova ${notes.length + 1}',
          body: _demoBody(tags),
          tags: tags,
          sources: const [],
          created: created,
          updated: created,
        ),
      );
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return notes;
}

String _demoBody(List<String> tags) =>
    'Testo di prova per vedere come appare una nota del calendario.\n\n'
    '- argomento: **${tags.first}**\n'
    '- tag: ${tags.join(', ')}\n';

/// Tag con un peso base e i mesi in cui vengono usati di più.
const _pool = <(String, int, Set<int>)>[
  ('studio', 6, {1, 2, 5, 6, 9, 10, 11}),
  ('idee', 5, {}),
  ('lavoro', 5, {3, 4, 10, 11}),
  ('libri', 3, {7, 8, 12}),
  ('esami', 1, {1, 2, 6, 7}),
  ('casa', 3, {}),
  ('sport', 2, {4, 5, 6, 9}),
  ('viaggi', 1, {7, 8}),
  ('salute', 2, {}),
  ('progetti', 3, {3, 9, 10}),
  ('musica', 2, {}),
  ('regali', 1, {12}),
];

List<String> _pickTags(math.Random random, int month) {
  final weights = [
    for (final (_, base, peak) in _pool) peak.contains(month) ? base * 4 : base,
  ];
  final total = weights.fold(0, (a, b) => a + b);
  final howMany = 1 + random.nextInt(3);
  final picked = <String>{};
  while (picked.length < howMany) {
    var roll = random.nextInt(total);
    for (var i = 0; i < _pool.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        picked.add(_pool[i].$1);
        break;
      }
    }
  }
  return picked.toList();
}
