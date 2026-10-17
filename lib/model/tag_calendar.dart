import 'note.dart';
import 'tags.dart';

/// I tag usati in un periodo (un giorno o un mese) e quante volte.
class TagTally {
  TagTally();

  /// Ogni tag con il numero di note del periodo che lo usano.
  final Map<String, int> counts = {};

  /// Quante note sono state scritte nel periodo (anche senza tag).
  int notes = 0;

  /// I tag dal più usato; a parità, in ordine alfabetico.
  List<MapEntry<String, int>> ranked() {
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return foldText(a.key).compareTo(foldText(b.key));
      });
    return entries;
  }
}

/// Raggruppa [notes] per giorno di creazione. Le chiavi sono la mezzanotte
/// del giorno (ora locale).
Map<DateTime, TagTally> tallyByDay(Iterable<Note> notes) =>
    _tally(notes, (d) => DateTime(d.year, d.month, d.day));

/// Raggruppa [notes] per mese di creazione. Le chiavi sono il primo del mese.
Map<DateTime, TagTally> tallyByMonth(Iterable<Note> notes) =>
    _tally(notes, (d) => DateTime(d.year, d.month));

Map<DateTime, TagTally> _tally(
  Iterable<Note> notes,
  DateTime Function(DateTime) bucket,
) {
  final result = <DateTime, TagTally>{};
  for (final note in notes) {
    final tally = result[bucket(note.created)] ??= TagTally();
    tally.notes++;
    for (final tag in note.tags.toSet()) {
      tally.counts[tag] = (tally.counts[tag] ?? 0) + 1;
    }
  }
  return result;
}
