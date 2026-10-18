import 'dart:math' as math;
import 'dart:ui' show Color;

/// Le lettere latine accentate (minuscole) con la lettera semplice: non solo
/// l'italiano, così anche "Müller", "François" o "España" si trovano
/// scrivendo senza accenti. Ognuna diventa una sola lettera, quindi il testo
/// non cambia lunghezza (serve per evidenziare le parole trovate).
const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'ç': 'c', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ñ': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'ý': 'y', 'ÿ': 'y',
};

/// Le lettere di [_accents] per codice, per non creare una stringa per ogni
/// carattere.
final _accentCodes = {
  for (final MapEntry(:key, :value) in _accents.entries)
    key.codeUnitAt(0): value.codeUnitAt(0),
};

/// Minuscolo e senza accenti: la forma usata per confrontare.
///
/// Gira a ogni tasto su tutte le note, quindi deve costare poco: un testo
/// senza lettere accentate (il caso più comune) esce com'è dopo il
/// minuscolo, gli altri si rifanno in una sola passata.
String foldText(String s) {
  final lower = s.toLowerCase();
  final units = lower.codeUnits;
  var i = 0;
  while (i < units.length && !_isAccented(units[i])) {
    i++;
  }
  if (i == units.length) return lower;
  final folded = List<int>.of(units);
  for (; i < folded.length; i++) {
    if (_isAccented(folded[i])) folded[i] = _accentCodes[folded[i]]!;
  }
  return String.fromCharCodes(folded);
}

/// Le lettere accentate stanno tutte sopra l'ASCII: per il resto del testo
/// basta un confronto, senza cercare nella mappa.
bool _isAccented(int unit) => unit >= 0xC0 && _accentCodes.containsKey(unit);

/// Suggerisce le voci di [counts] più vicine a [query].
///
/// [counts] associa ogni voce al numero di note che la usano. L'ordine
/// premia: inizio uguale, poi una parola che inizia così, poi testo
/// contenuto, poi parole simili (pochi errori di battitura); a parità vince
/// la voce più usata. Il confronto ignora maiuscole e accenti.
List<String> rankSuggestions(
  String query,
  Map<String, int> counts, {
  Iterable<String> exclude = const [],
  int limit = 6,
}) {
  final q = foldText(query.trim());
  final excluded = exclude.map(foldText).toSet();
  final candidates = counts.keys.where((c) => !excluded.contains(foldText(c)));
  if (q.isEmpty) {
    final popular = candidates.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return popular.take(limit).toList();
  }
  final scored = <(String, int)>[];
  for (final candidate in candidates) {
    final score = _score(q, foldText(candidate));
    if (score != null) scored.add((candidate, score));
  }
  scored.sort((a, b) {
    final byScore = a.$2.compareTo(b.$2);
    if (byScore != 0) return byScore;
    return counts[b.$1]!.compareTo(counts[a.$1]!);
  });
  return scored.take(limit).map((s) => s.$1).toList();
}

/// Più basso = più pertinente; null = non suggerire.
int? _score(String query, String candidate) {
  if (candidate == query) return 0;
  if (candidate.startsWith(query)) return 1;
  if (candidate.split(RegExp(r'[-/\s]')).any((w) => w.startsWith(query))) {
    return 2;
  }
  if (candidate.contains(query)) return 3;
  // Errori di battitura: confronto con l'inizio lungo quanto la query.
  final prefix = candidate.substring(
    0,
    math.min(candidate.length, query.length),
  );
  final distance = _levenshtein(query, prefix);
  final allowed = query.length <= 3 ? 0 : (query.length <= 6 ? 1 : 2);
  if (distance <= allowed) return 4 + distance;
  return null;
}

int _levenshtein(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = [i + 1];
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      current.add(
        math.min(
          math.min(current[j] + 1, previous[j + 1] + 1),
          previous[j] + cost,
        ),
      );
    }
    previous = current;
  }
  return previous.last;
}

/// Regole sui tag: forma canonica, suggerimenti e colori.
class Tags {
  /// Forma canonica: minuscolo, senza `#`, spazi trasformati in trattini.
  ///
  /// "Machine Learning" → "machine-learning", "#Città" → "citta".
  static String normalize(String raw) {
    var tag = raw.trim();
    while (tag.startsWith('#')) {
      tag = tag.substring(1);
    }
    tag = foldText(tag);
    tag = tag.replaceAll(RegExp(r'[\s_]+'), '-');
    tag = tag.replaceAll(RegExp(r'[^a-z0-9\-/]'), '');
    tag = tag.replaceAll(RegExp(r'-{2,}'), '-');
    tag = tag.replaceAll(RegExp(r'^[-/]+|[-/]+$'), '');
    return tag;
  }

  /// Suggerisce i tag esistenti più vicini a [input].
  static List<String> suggest(
    String input,
    Map<String, int> counts, {
    Iterable<String> exclude = const [],
    int limit = 6,
  }) =>
      rankSuggestions(normalize(input), counts, exclude: exclude, limit: limit);

  static const palette = [
    Color(0xFFF2E94E), // giallo
    Color(0xFF9B8CF2), // lavanda
    Color(0xFFE07AB8), // rosa
    Color(0xFF5CC8C2), // teal
    Color(0xFFF2A65A), // arancio
    Color(0xFF7FD27F), // verde
    Color(0xFF6FA8F2), // azzurro
    Color(0xFFE86A6A), // rosso
    Color(0xFFC9B38A), // sabbia
    Color(0xFFB98AE0), // viola
  ];

  /// Colore stabile per un tag (lo stesso tag ha sempre lo stesso colore).
  static Color colorOf(String tag) {
    var hash = 0x811c9dc5; // FNV-1a
    for (final unit in tag.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return palette[hash % palette.length];
  }
}

/// Regole sulle fonti (di solito persone): si tengono maiuscole, accenti e
/// spazi, così "Mario Rossi" resta "Mario Rossi".
class Sources {
  /// Toglie gli spazi superflui: "  mario   rossi " → "mario rossi".
  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Se esiste già una fonte uguale a meno di maiuscole e accenti, usa
  /// quella: scrivere "mario rossi" riusa "Mario Rossi".
  static String canonical(String raw, Iterable<String> existing) {
    final name = normalize(raw);
    final key = foldText(name);
    for (final source in existing) {
      if (foldText(source) == key) return source;
    }
    return name;
  }

  static List<String> suggest(
    String input,
    Map<String, int> counts, {
    Iterable<String> exclude = const [],
    int limit = 6,
  }) =>
      rankSuggestions(normalize(input), counts, exclude: exclude, limit: limit);
}
