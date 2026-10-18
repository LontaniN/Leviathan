import 'markdown.dart';
import 'note.dart';
import 'tags.dart';
import 'text_cut.dart';

/// Filtro sullo stato dei task: la parola dopo `stato:` (o `status:`).
///
/// Ogni filtro ha un nome per lingua; la ricerca li riconosce tutti,
/// qualunque sia la lingua dell'interfaccia.
enum TaskFilter {
  task(['task']),
  aperto(['aperto', 'open']),
  fatto(['fatto', 'done']);

  const TaskFilter(this.keywords);

  final List<String> keywords;

  bool matches(Note note) => switch (this) {
    TaskFilter.task => note.isTask,
    TaskFilter.aperto => note.isOpenTask,
    TaskFilter.fatto => note.isTask && note.done,
  };

  bool _startsWith(String folded) => keywords.any((k) => k.startsWith(folded));

  /// Il filtro con questo nome (anche abbreviato: "ap" → aperto).
  static TaskFilter? parse(String value) {
    final v = foldText(value.trim());
    if (v.isEmpty) return null;
    for (final f in values) {
      if (f._startsWith(v)) return f;
    }
    return null;
  }

  /// I filtri con un nome che comincia con [value], nell'ordine dell'enum.
  static List<TaskFilter> suggest(String value) {
    final v = foldText(value.trim());
    return [
      for (final f in values)
        if (f._startsWith(v)) f,
    ];
  }
}

/// Una ricerca: testo libero più filtri per tag, fonte e stato dei task.
///
/// Ogni parte è facoltativa e si combinano tutte in AND: una nota compare
/// se contiene tutte le parole, ha tutti i tag e tutte le fonti scelti e,
/// se c'è, rispetta il filtro sui task.
class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.tags = const [],
    this.sources = const [],
    this.task,
  });

  final String text;
  final List<String> tags;
  final List<String> sources;
  final TaskFilter? task;

  /// Le parole cercate, normalizzate (minuscolo, senza accenti).
  List<String> get terms =>
      foldText(text).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  bool get isEmpty =>
      terms.isEmpty && tags.isEmpty && sources.isEmpty && task == null;
}

class SearchHit {
  /// [snippet] si calcola solo quando serve: un elenco lungo mostra poche
  /// righe alla volta.
  SearchHit(this.note, this.score, String Function() snippet)
    : _makeSnippet = snippet;

  final Note note;
  final int score;
  final String Function() _makeSnippet;

  /// Un pezzo del corpo attorno alla prima parola trovata (o l'inizio).
  late final String snippet = _makeSnippet();
}

/// Titolo, corpo, etichette e fonti di una nota già passati da [foldText].
typedef _FoldedNote = ({
  String title,
  String body,
  String labels,
  Set<String> sources,
});

/// Le forme normalizzate di ogni nota, calcolate alla prima ricerca. Una
/// nota modificata è un oggetto nuovo, quindi non si legge mai una forma
/// vecchia; le note che non esistono più spariscono con la loro voce.
final _foldedCache = Expando<_FoldedNote>('foldedNote');

_FoldedNote _folded(Note note) => _foldedCache[note] ??= (
  title: foldText(note.title),
  body: foldText(note.body),
  labels: foldText([...note.tags, ...note.sources].join(' ')),
  sources: note.sources.map(foldText).toSet(),
);

/// Cerca nelle note; risultati dai più pertinenti, poi dai più recenti.
///
/// Le parole si cercano in titolo, corpo, tag e fonti; un risultato nel
/// titolo pesa più di uno nel corpo.
List<SearchHit> searchNotes(List<Note> notes, SearchQuery query) {
  if (query.isEmpty) return const [];
  final terms = query.terms;
  final wantedSources = query.sources.map(foldText).toSet();
  final hits = <SearchHit>[];
  for (final note in notes) {
    if (query.task != null && !query.task!.matches(note)) continue;
    if (!query.tags.every(note.tags.contains)) continue;
    final folded = _folded(note);
    if (!wantedSources.every(folded.sources.contains)) continue;

    final (:title, :body, :labels, sources: _) = folded;
    var score = 0;
    var matchesAll = true;
    for (final term in terms) {
      if (title.contains(term)) {
        score += title.startsWith(term) ? 6 : 4;
      } else if (labels.contains(term)) {
        score += 2;
      } else if (body.contains(term)) {
        score += 1;
      } else {
        matchesAll = false;
        break;
      }
    }
    if (!matchesAll) continue;
    hits.add(SearchHit(note, score, () => _snippet(note.body, body, terms)));
  }
  hits.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return b.note.created.compareTo(a.note.created);
  });
  return hits;
}

String _snippet(String body, String foldedBody, List<String> terms) {
  const before = 40;
  const length = 160;
  var start = 0;
  for (final term in terms) {
    final at = foldedBody.indexOf(term);
    if (at != -1) {
      start = at > before ? at - before : 0;
      break;
    }
  }
  // foldText di solito non cambia la lunghezza, ma qualche lettera in
  // minuscolo diventa due (es. 'İ'): per sicurezza.
  if (start >= body.length) start = 0;
  final end = (start + length).clamp(0, body.length);
  var text = plainText(safeSubstring(body, start, end))
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (start > 0) text = '…$text';
  if (end < body.length) text = '$text…';
  return text;
}

/// Gli intervalli di [text] che contengono una delle [terms], per evidenziarli.
List<(int, int)> matchRanges(String text, List<String> terms) {
  if (terms.isEmpty) return const [];
  final folded = foldText(text);
  if (folded.length != text.length) return const [];
  final ranges = <(int, int)>[];
  for (final term in terms) {
    var from = 0;
    while (true) {
      final at = folded.indexOf(term, from);
      if (at == -1) break;
      ranges.add((at, at + term.length));
      from = at + term.length;
    }
  }
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  // Unisce gli intervalli sovrapposti.
  final merged = <(int, int)>[];
  for (final r in ranges) {
    if (merged.isNotEmpty && r.$1 <= merged.last.$2) {
      final last = merged.removeLast();
      merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
    } else {
      merged.add(r);
    }
  }
  return merged;
}

/// Un filtro che si sta scrivendo nella barra di ricerca.
enum FilterKind { tag, source, status }

/// Cosa c'è nella barra: testo libero e, in fondo, un filtro in scrittura.
///
/// Come su Discord: `tag:` (o `#`), `da:` / `from:` (o `@`) e `stato:` /
/// `status:` aprono un filtro, in qualunque lingua. Tag e stato finiscono
/// allo spazio; una fonte può contenere spazi ("da:Mario Rossi") e resta
/// aperta finché non la si conferma.
class SearchInput {
  const SearchInput(this.freeText, this.activeKind, this.activeValue);

  final String freeText;
  final FilterKind? activeKind;
  final String activeValue;

  static final _marker = RegExp(
    r'(?<=^|\s)(tag:|#|da:|from:|@|stato:|status:)',
    caseSensitive: false,
  );

  static SearchInput parse(String raw) {
    final markers = _marker.allMatches(raw);
    if (markers.isNotEmpty) {
      final match = markers.last;
      final marker = match.group(1)!.toLowerCase();
      final value = raw.substring(match.end);
      final kind = switch (marker) {
        'tag:' || '#' => FilterKind.tag,
        'stato:' || 'status:' => FilterKind.status,
        _ => FilterKind.source,
      };
      // Tag e stato non contengono spazi: dopo uno spazio si torna al testo
      // libero.
      if (kind == FilterKind.source || !value.contains(RegExp(r'\s'))) {
        return SearchInput(raw.substring(0, match.start).trim(), kind, value);
      }
    }
    return SearchInput(raw.trim(), null, '');
  }
}

/// Un'anteprima corta di [note] che comincia vicino alla prima delle [terms]
/// trovata, per le caselle piccole del calendario: se la parola è nel
/// titolo basta il titolo (o [untitled]), altrimenti il pezzo di testo che
/// la contiene.
String matchPreview(Note note, List<String> terms, String untitled) {
  const before = 12;
  const length = 120;
  final title = note.displayTitle(untitled);
  final foldedTitle = foldText(title);
  if (terms.any(foldedTitle.contains)) return title;

  final body = plainText(note.body).replaceAll(RegExp(r'\s+'), ' ').trim();
  final folded = foldText(body);
  // foldText di solito non cambia la lunghezza, ma qualche lettera in
  // minuscolo diventa due (es. 'İ'): per sicurezza.
  if (folded.length != body.length) return title;
  for (final term in terms) {
    final at = folded.indexOf(term);
    if (at == -1) continue;
    var start = at > before ? at - before : 0;
    // Non si comincia a metà parola.
    if (start > 0) {
      final space = body.indexOf(' ', start);
      start = space != -1 && space < at ? space + 1 : at;
    }
    final end = (start + length).clamp(0, body.length);
    var text = safeSubstring(body, start, end);
    if (start > 0) text = '…$text';
    if (end < body.length) text = '$text…';
    return text;
  }
  // La parola è fra i tag o le fonti.
  return title;
}
