import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/due.dart';
import 'package:leviathan/model/note.dart';

void main() {
  final now = DateTime(2026, 10, 25, 22, 30);

  Note task(String id, DateTime? due, {bool done = false, int created = 0}) =>
      Note(
        id: id,
        title: id,
        body: '',
        tags: const [],
        sources: const [],
        created: DateTime(2026, 1, 1 + created),
        updated: DateTime(2026, 1, 1),
        isTask: true,
        done: done,
        due: due,
      );

  test('giorni che mancano, contati sul calendario', () {
    expect(daysUntil(DateTime(2026, 10, 25), now), 0);
    expect(daysUntil(DateTime(2026, 10, 26), now), 1);
    expect(daysUntil(DateTime(2026, 10, 23), now), -2);
    // Attraverso il cambio dell'ora legale (25 ottobre 2026).
    expect(daysUntil(DateTime(2026, 10, 24), DateTime(2026, 10, 26, 1)), -2);
  });

  test('le intestazioni dalla più urgente', () {
    expect(dueSection(-1), DueSection.overdue);
    expect(dueSection(0), DueSection.today);
    expect(dueSection(1), DueSection.tomorrow);
    expect(dueSection(2), DueSection.week);
    expect(dueSection(7), DueSection.week);
    expect(dueSection(8), DueSection.later);
  });

  test('solo i task da fare con scadenza, dalla più vicina', () {
    final sorted = tasksByDue([
      task('lontano', DateTime(2026, 12, 1)),
      task('senza', null),
      task('fatto', DateTime(2026, 10, 20), done: true),
      task('scaduto', DateTime(2026, 10, 20)),
      task('domani-vecchio', DateTime(2026, 10, 26)),
      task('domani-nuovo', DateTime(2026, 10, 26), created: 5),
      Note(
        id: 'nota',
        title: 'nota',
        body: '',
        tags: const [],
        sources: const [],
        created: DateTime(2026),
        updated: DateTime(2026),
      ),
    ]);
    expect(sorted.map((n) => n.id), [
      'scaduto',
      'domani-nuovo',
      'domani-vecchio',
      'lontano',
    ]);
  });
}
