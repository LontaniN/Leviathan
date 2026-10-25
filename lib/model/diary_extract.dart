/// Un pezzo di testo del diario da cui è nata una nota ([noteId]).
///
/// Nel diario resta colorato col primo tag della nota, così si vede quale
/// testo è già una nota e quale no.
class DiaryExtract {
  const DiaryExtract({
    required this.id,
    required this.day,
    required this.text,
    required this.start,
    this.tags = const [],
    this.sources = const [],
    this.noteId,
  });

  final String id;

  /// Il giorno del diario, come nome del suo file ("2026-10-25").
  final String day;

  /// Il testo scelto, com'era nel diario.
  final String text;

  /// Dove cominciava nel giorno: se il testo è cambiato intorno, si cerca
  /// la copia più vicina a qui (vedi [extractRanges]).
  final int start;

  final List<String> tags;
  final List<String> sources;

  /// La nota nata da questo pezzo; null solo per i pezzi salvati da una
  /// versione di prova, che si possono ancora far diventare note.
  final String? noteId;

  bool get pending => noteId == null;

  DiaryExtract copyWith({
    List<String>? tags,
    List<String>? sources,
    String? noteId,
  }) => DiaryExtract(
    id: id,
    day: day,
    text: text,
    start: start,
    tags: tags ?? this.tags,
    sources: sources ?? this.sources,
    noteId: noteId ?? this.noteId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'day': day,
    'text': text,
    'start': start,
    if (tags.isNotEmpty) 'tags': tags,
    if (sources.isNotEmpty) 'sources': sources,
    if (noteId != null) 'note': noteId,
  };

  /// Null se il JSON non è un pezzo valido.
  static DiaryExtract? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final day = json['day'];
    final text = json['text'];
    if (id is! String || day is! String || text is! String || text.isEmpty) {
      return null;
    }
    List<String> list(Object? v) => [if (v is List) ...v.whereType<String>()];
    final start = json['start'];
    final note = json['note'];
    return DiaryExtract(
      id: id,
      day: day,
      text: text,
      start: start is int ? start : 0,
      tags: list(json['tags']),
      sources: list(json['sources']),
      noteId: note is String && note.isNotEmpty ? note : null,
    );
  }
}

/// Un pezzo ritrovato nel testo del suo giorno: da [start] a [end].
typedef ExtractRange = ({int start, int end, DiaryExtract extract});

/// Dove stanno i pezzi [extracts] nel testo [text] di un giorno, in ordine.
///
/// Ogni pezzo si cerca per testo, alla copia più vicina a dove era: così
/// resta al suo posto anche se prima o dopo si è scritto altro. Un pezzo che
/// non si trova più (lo si è cancellato o cambiato) non c'è; due pezzi che
/// si accavallano tengono il primo.
List<ExtractRange> extractRanges(String text, Iterable<DiaryExtract> extracts) {
  final found = <ExtractRange>[];
  for (final extract in extracts) {
    int? best;
    for (
      var at = text.indexOf(extract.text);
      at >= 0;
      at = text.indexOf(extract.text, at + 1)
    ) {
      if (best == null ||
          (at - extract.start).abs() < (best - extract.start).abs()) {
        best = at;
      }
    }
    if (best != null) {
      found.add((
        start: best,
        end: best + extract.text.length,
        extract: extract,
      ));
    }
  }
  found.sort((a, b) => a.start.compareTo(b.start));
  final ranges = <ExtractRange>[];
  for (final range in found) {
    if (ranges.isEmpty || range.start >= ranges.last.end) ranges.add(range);
  }
  return ranges;
}

/// Il pezzo che contiene la posizione [offset], se c'è.
ExtractRange? extractAt(List<ExtractRange> ranges, int offset) {
  for (final range in ranges) {
    if (offset >= range.start && offset < range.end) return range;
  }
  return null;
}
