import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/search.dart';
import 'package:leviathan/model/tags.dart';

Note _note(
  String id,
  String title, {
  String body = '',
  List<String> tags = const [],
  List<String> sources = const [],
  int day = 1,
  bool? done,
}) => Note(
  id: id,
  title: title,
  body: body,
  tags: tags,
  sources: sources,
  created: DateTime(2026, 1, day),
  updated: DateTime(2026, 1, day),
  isTask: done != null,
  done: done ?? false,
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

  test('una nota modificata si cerca col testo nuovo', () {
    final before = _note('m', 'Vecchio titolo', body: 'corpo');
    expect(searchNotes([before], const SearchQuery(text: 'vecchio')), [
      isA<SearchHit>(),
    ]);
    final after = before.copyWith(title: 'Titolo nuovo', body: 'Città');
    expect(searchNotes([after], const SearchQuery(text: 'vecchio')), isEmpty);
    final hits = searchNotes([after], const SearchQuery(text: 'citta'));
    expect(hits.single.snippet, 'Città');
  });

  test('foldText toglie accenti e maiuscole solo dove servono', () {
    expect(foldText('Perché CITTÀ è così'), 'perche citta e cosi');
    expect(foldText('nessun accento'), 'nessun accento');
    expect(foldText('Müller, François, España'), 'muller, francois, espana');
    expect(foldText(''), '');
    // Lettere non latine e simboli restano come sono.
    expect(foldText('Ω → ✓'), 'ω → ✓');
  });

  group('filtro stato', () {
    final withTasks = [
      ...notes,
      _note('t1', 'Studiare luce', tags: ['luce'], day: 5, done: false),
      _note('t2', 'Ripassare luce', tags: ['luce'], day: 6, done: true),
    ];
    List<String> taskIds(SearchQuery q) =>
        searchNotes(withTasks, q).map((h) => h.note.id).toList();

    test('aperti, fatti e tutti i task', () {
      expect(taskIds(const SearchQuery(task: TaskFilter.aperto)), ['t1']);
      expect(taskIds(const SearchQuery(task: TaskFilter.fatto)), ['t2']);
      expect(taskIds(const SearchQuery(task: TaskFilter.task)), ['t2', 't1']);
    });

    test('si combina con testo e tag', () {
      expect(
        taskIds(
          const SearchQuery(
            text: 'luce',
            tags: ['luce'],
            task: TaskFilter.aperto,
          ),
        ),
        ['t1'],
      );
    });

    test('nome abbreviato e suggerimenti', () {
      expect(TaskFilter.parse('ap'), TaskFilter.aperto);
      expect(TaskFilter.parse('FATTO'), TaskFilter.fatto);
      expect(TaskFilter.parse('boh'), isNull);
      expect(TaskFilter.suggest(''), TaskFilter.values);
      expect(TaskFilter.suggest('f'), [TaskFilter.fatto]);
    });

    test('nomi inglesi', () {
      expect(TaskFilter.parse('open'), TaskFilter.aperto);
      expect(TaskFilter.parse('DONE'), TaskFilter.fatto);
      expect(TaskFilter.suggest('d'), [TaskFilter.fatto]);
    });
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

    test('filtro stato in scrittura', () {
      final p = SearchInput.parse('esame stato:ap');
      expect(p.freeText, 'esame');
      expect(p.activeKind, FilterKind.status);
      expect(p.activeValue, 'ap');
    });

    test('marcatori inglesi', () {
      final source = SearchInput.parse('delivery from:Mario Ro');
      expect(source.freeText, 'delivery');
      expect(source.activeKind, FilterKind.source);
      expect(source.activeValue, 'Mario Ro');
      expect(SearchInput.parse('exam status:op').activeKind, FilterKind.status);
    });

    test('# in mezzo a una parola non è un filtro', () {
      expect(SearchInput.parse('C#').activeKind, isNull);
    });
  });

  group('anteprima per il calendario', () {
    test('parte poco prima della parola, senza tagliare parole', () {
      final note = _note(
        'p',
        'Gita',
        body: 'Siamo partiti presto e al lago abbiamo visto gli aironi.',
      );
      expect(
        matchPreview(note, ['lago'], 'Senza titolo'),
        '…e al lago abbiamo visto gli aironi.',
      );
    });

    test('se la parola è nel titolo basta il titolo', () {
      final note = _note('t', 'Lago di Como', body: 'Un giro in barca.');
      expect(matchPreview(note, ['lago'], 'Senza titolo'), 'Lago di Como');
    });

    test("dall'inizio se la parola è in testa", () {
      final note = _note('i', 'Gita', body: 'Lago ghiacciato.');
      expect(matchPreview(note, ['lago'], 'Senza titolo'), 'Lago ghiacciato.');
    });
  });
}
