/// I segni di elenco con cui spesso comincia una riga copiata o scritta di
/// getto: trattini, asterischi, pallini, numeri, caselle Markdown.
final _listMarker = RegExp(
  r'^(?:[-*+•–](?:\s+|$)|\d+[.)](?:\s+|$))?(?:\[[ xX]?\](?:\s+|$))?',
);

/// I titoli dei task di uno "svuota la testa": una riga per cosa.
///
/// Toglie i segni di elenco in testa, salta le righe vuote e quelle
/// ripetute (senza badare a maiuscole e spazi), e tiene l'ordine in cui
/// sono state scritte.
List<String> brainDumpTitles(String text) {
  final seen = <String>{};
  return [
    for (final line in text.split('\n'))
      if (line.trim().replaceFirst(_listMarker, '').trim() case final title
          when title.isNotEmpty && seen.add(title.toLowerCase()))
        title,
  ];
}
