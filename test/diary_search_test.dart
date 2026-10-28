import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/diary_search.dart';
import 'package:leviathan/model/search.dart';

List<String> _terms(String text) => SearchQuery(text: text).terms;

void main() {
  final days = {
    '2026-03-07': 'Cena da Anna, poi cinema.',
    '2026-10-25': 'Pioggia tutto il giorno. Telefonata con Anna.',
    '2026-10-26': 'Caffè al bar.',
    'extracts': 'non è un giorno: Anna',
  };

  test('trova i giorni con tutte le parole, dal più recente', () {
    final hits = searchDiary(days, _terms('anna'));
    expect([for (final h in hits) h.key], ['2026-10-25', '2026-03-07']);
    expect(hits.first.day, DateTime(2026, 10, 25));

    expect(
      [for (final h in searchDiary(days, _terms('anna cinema'))) h.key],
      ['2026-03-07'],
    );
  });

  test('senza badare a maiuscole e accenti', () {
    expect(
      [for (final h in searchDiary(days, _terms('CAFFE'))) h.key],
      ['2026-10-26'],
    );
  });

  test('nessuna parola, nessun risultato', () {
    expect(searchDiary(days, _terms('  ')), isEmpty);
    expect(searchDiary(days, _terms('neve')), isEmpty);
  });

  test("l'estratto comincia vicino alla parola, su una riga", () {
    final long = '${List.filled(20, 'parola').join(' ')}\n\nil gatto dorme';
    final hit = searchDiary({'2026-10-25': long}, _terms('gatto')).single;
    expect(hit.snippet, startsWith('…'));
    expect(hit.snippet, contains('il gatto dorme'));
    expect(hit.snippet, isNot(contains('\n')));
    // Non si comincia a metà parola.
    expect(hit.snippet.substring(1).split(' ').first, 'parola');
  });
}
