import 'tags.dart';
import 'text_cut.dart';

/// Un giorno del diario trovato: la chiave del file ("2026-10-25"), il
/// giorno e un pezzo del testo attorno alla prima parola cercata.
typedef DiaryHit = ({String key, DateTime day, String snippet});

/// I giorni di [days] (testo per chiave, come li legge `DiaryStore`) che
/// contengono tutte le [terms], già passate da [foldText]; dal più recente.
///
/// Come nella ricerca delle note le parole si cercano senza badare a
/// maiuscole e accenti, e possono stare in qualunque punto del giorno.
List<DiaryHit> searchDiary(Map<String, String> days, List<String> terms) {
  if (terms.isEmpty) return const [];
  final hits = <DiaryHit>[];
  for (final MapEntry(:key, value: text) in days.entries) {
    final day = DateTime.tryParse(key);
    if (day == null) continue;
    final folded = foldText(text);
    if (!terms.every(folded.contains)) continue;
    hits.add((key: key, day: day, snippet: _snippet(text, folded, terms)));
  }
  // Le chiavi sono date AAAA-MM-GG: l'ordine del testo è quello del tempo.
  hits.sort((a, b) => b.key.compareTo(a.key));
  return hits;
}

/// Un pezzo di [text] su una riga, che comincia poco prima della prima delle
/// [terms] trovata, senza tagliare una parola.
String _snippet(String text, String folded, List<String> terms) {
  const before = 30;
  const length = 160;
  var start = 0;
  // foldText di solito non cambia la lunghezza, ma qualche lettera in
  // minuscolo diventa due (es. 'İ'): in quel caso si parte dall'inizio.
  if (folded.length == text.length) {
    for (final term in terms) {
      final at = folded.indexOf(term);
      if (at == -1) continue;
      start = at > before ? at - before : 0;
      if (start > 0) {
        final space = text.indexOf(RegExp(r'\s'), start);
        start = space != -1 && space < at ? space + 1 : at;
      }
      break;
    }
  }
  final end = (start + length).clamp(0, text.length);
  var snippet = safeSubstring(
    text,
    start,
    end,
  ).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (start > 0) snippet = '…$snippet';
  if (end < text.length) snippet = '$snippet…';
  return snippet;
}
