import 'note.dart';
import 'tags.dart';

/// Una ricerca: testo libero più filtri per tag e per fonte.
///
/// Ogni parte è facoltativa e si combinano tutte in AND: una nota compare
/// se contiene tutte le parole, ha tutti i tag e tutte le fonti scelti.
class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.tags = const [],
    this.sources = const [],
  });

  final String text;
  final List<String> tags;
  final List<String> sources;

  /// Le parole cercate, normalizzate (minuscolo, senza accenti).
  List<String> get terms =>
      foldText(text).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  bool get isEmpty => terms.isEmpty && tags.isEmpty && sources.isEmpty;
}

class SearchHit {
  const SearchHit(this.note, this.score, this.snippet);

  final Note note;
  final int score;

  /// Un pezzo del corpo attorno alla prima parola trovata (o l'inizio).
  final String snippet;
}

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
    if (!query.tags.every(note.tags.contains)) continue;
    final noteSources = note.sources.map(foldText).toSet();
    if (!wantedSources.every(noteSources.contains)) continue;

    final title = foldText(note.title);
    final body = foldText(note.body);
    final labels = foldText([...note.tags, ...note.sources].join(' '));
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
    hits.add(SearchHit(note, score, _snippet(note.body, body, terms)));
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
  // foldText non cambia la lunghezza per l'italiano, ma per sicurezza:
  if (start >= body.length) start = 0;
  final end = (start + length).clamp(0, body.length);
  var text = body.substring(start, end).replaceAll(RegExp(r'\s+'), ' ').trim();
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
enum FilterKind { tag, source }

/// Cosa c'è nella barra: testo libero e, in fondo, un filtro in scrittura.
///
/// Come su Discord: `tag:` (o `#`) e `da:` (o `@`) aprono un filtro. Un tag
/// finisce allo spazio; una fonte può contenere spazi ("da:Mario Rossi") e
/// resta aperta finché non la si conferma.
class SearchInput {
  const SearchInput(this.freeText, this.activeKind, this.activeValue);

  final String freeText;
  final FilterKind? activeKind;
  final String activeValue;

  static final _marker = RegExp(
    r'(?<=^|\s)(tag:|#|da:|@)',
    caseSensitive: false,
  );

  static SearchInput parse(String raw) {
    final markers = _marker.allMatches(raw);
    if (markers.isNotEmpty) {
      final match = markers.last;
      final marker = match.group(1)!.toLowerCase();
      final value = raw.substring(match.end);
      final kind = marker == 'tag:' || marker == '#'
          ? FilterKind.tag
          : FilterKind.source;
      // Un tag non contiene spazi: dopo uno spazio si torna al testo libero.
      if (kind == FilterKind.source || !value.contains(RegExp(r'\s'))) {
        return SearchInput(raw.substring(0, match.start).trim(), kind, value);
      }
    }
    return SearchInput(raw.trim(), null, '');
  }
}
