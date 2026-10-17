import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/search.dart';

Note _note(
  String id,
  String title, {
  String body = '',
  List<String> tags = const [],
  List<String> sources = const [],
  int day = 1,
}) => Note(
  id: id,
  title: title,
  body: body,
  tags: tags,
  sources: sources,
  created: DateTime(2026, 1, day),
  updated: DateTime(2026, 1, day),
);

void main() {
  final notes = [
    _note(
      'a',
      'Esposizione',
      body: 'Il triangolo di esposizione: tempo, diaframma, ISO.',
      tags: ['fotografia'],
      sources: ['Mario Rossi'],
      day: 1,
    ),
    _note(
      'b',
      'Luce del mattino',
      body: 'La luce migliore per i ritratti è al mattino.',
      tags: ['fotografia', 'luce'],
      sources: ['Anna'],
      day: 2,
    ),
    _note(
      'c',
      'Riunione',
      body: 'Mario propone di spostare la consegna.',
      tags: ['lavoro'],
      sources: ['Mario Rossi'],
      day: 3,
    ),
    _note('d', 'Città', body: 'Appunti sulla città', day: 4),
  ];

  List<String> ids(SearchQuery q) =>
      searchNotes(notes, q).map((h) => h.note.id).toList();

  test('ricerca vuota: nessun risultato', () {
    expect(ids(const SearchQuery()), isEmpty);
  });

  test('solo testo, in titolo e corpo, ignorando maiuscole', () {
    expect(ids(const SearchQuery(text: 'MATTINO')), ['b']);
    expect(ids(const SearchQuery(text: 'diaframma')), ['a']);
  });

  test('ignora gli accenti', () {
    expect(ids(const SearchQuery(text: 'citta')), ['d']);
  });

  test('tutte le parole devono esserci', () {
    expect(ids(const SearchQuery(text: 'luce ritratti')), ['b']);
    expect(ids(const SearchQuery(text: 'luce consegna')), isEmpty);
  });

  test('il titolo pesa più del corpo', () {
    // "esposizione" è nel titolo di a; "mario" è nel corpo di c e nelle fonti.
    expect(ids(const SearchQuery(text: 'esposizione')), ['a']);
  });

  test('solo un tag', () {
    expect(ids(const SearchQuery(tags: ['fotografia'])), ['b', 'a']);
  });

  test('solo una fonte, senza badare a maiuscole', () {
    expect(ids(const SearchQuery(sources: ['mario rossi'])), ['c', 'a']);
  });

  test('testo + tag', () {
    expect(ids(const SearchQuery(text: 'luce', tags: ['fotografia'])), ['b']);
  });

  test('tag + fonte', () {
    expect(
      ids(const SearchQuery(tags: ['fotografia'], sources: ['Mario Rossi'])),
      ['a'],
    );
  });

  test('più tag insieme: la nota deve averli tutti', () {
    expect(ids(const SearchQuery(tags: ['fotografia', 'luce'])), ['b']);
  });

  test('il testo trova anche tag e fonti', () {
    expect(ids(const SearchQuery(text: 'anna')), ['b']);
  });

  test('anteprima attorno alla parola trovata', () {
    final hit = searchNotes(notes, const SearchQuery(text: 'iso')).single;
    expect(hit.snippet, contains('ISO'));
  });

  test('intervalli da evidenziare', () {
    expect(matchRanges('Luce e luce', ['luce']), [(0, 4), (7, 11)]);
    expect(matchRanges('Città', ['citta']), [(0, 5)]);
  });

  group('barra di ricerca', () {
    test('testo semplice', () {
      final p = SearchInput.parse('luce mattino');
      expect(p.freeText, 'luce mattino');
      expect(p.activeKind, isNull);
    });

    test('filtro tag in scrittura', () {
      final p = SearchInput.parse('luce tag:foto');
      expect(p.freeText, 'luce');
      expect(p.activeKind, FilterKind.tag);
      expect(p.activeValue, 'foto');
    });

    test('scorciatoie # e @', () {
      expect(SearchInput.parse('#fo').activeKind, FilterKind.tag);
      expect(SearchInput.parse('@ma').activeKind, FilterKind.source);
    });

    test('una fonte può contenere spazi', () {
      final p = SearchInput.parse('consegna da:Mario Ro');
      expect(p.freeText, 'consegna');
      expect(p.activeKind, FilterKind.source);
      expect(p.activeValue, 'Mario Ro');
    });

    test('vale l\'ultimo filtro scritto', () {
      final p = SearchInput.parse('da:Mario ciao #lu');
      expect(p.activeKind, FilterKind.tag);
      expect(p.activeValue, 'lu');
    });

    test('# in mezzo a una parola non è un filtro', () {
      expect(SearchInput.parse('C#').activeKind, isNull);
    });
  });
}
