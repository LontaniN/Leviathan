/// Testo arrivato da un'altra app col tasto Condividi: l'oggetto (es. il
/// titolo di una pagina, spesso vuoto) e il testo vero e proprio.
typedef SharedText = ({String subject, String text});

/// Aggiunge una condivisione al titolo e al corpo di una bozza.
///
/// L'oggetto diventa il titolo se la bozza non ne ha uno; altrimenti va nel
/// corpo, sopra il testo. Quello che arriva da fuori entra nel corpo come
/// citazione (`> `), così resta distinto da quello che si scrive di proprio
/// pugno: riassumere con parole proprie aiuta a ricordare più che copiare.
///
/// In una bozza senza corpo la citazione sta sotto una riga vuota e
/// [cursor] è all'inizio, pronto per scrivere sopra; in una bozza a metà la
/// citazione va in fondo, staccata da una riga vuota, e [cursor] resta alla
/// fine del testo che c'era. [appended] dice se la bozza aveva già qualcosa
/// (titolo o corpo).
({String title, String body, bool appended, int cursor}) mergeShared(
  String title,
  String body,
  SharedText share,
) {
  var subject = share.subject.trim();
  final text = share.text.trim();
  // Alcune app ripetono il testo anche nell'oggetto.
  if (subject == text) subject = '';
  final appended = title.trim().isNotEmpty || body.trim().isNotEmpty;
  final useSubjectAsTitle = title.trim().isEmpty && subject.isNotEmpty;
  final addition = [
    if (!useSubjectAsTitle && subject.isNotEmpty) subject,
    if (text.isNotEmpty) text,
  ].join('\n\n');
  final newTitle = useSubjectAsTitle ? subject : title;
  final existing = body.trimRight();
  if (addition.isEmpty) {
    return (
      title: newTitle,
      body: body,
      appended: appended,
      cursor: body.length,
    );
  }
  final quoted = quoteMarkdown(addition);
  if (existing.trim().isEmpty) {
    return (
      title: newTitle,
      body: '\n\n$quoted',
      appended: appended,
      cursor: 0,
    );
  }
  return (
    title: newTitle,
    body: '$existing\n\n$quoted',
    appended: appended,
    cursor: existing.length,
  );
}

/// [text] come citazione Markdown: ogni riga comincia con `> `, e le righe
/// vuote con `>` da solo, così la citazione resta un blocco unico.
String quoteMarkdown(String text) =>
    [for (final line in text.split('\n')) line.trim().isEmpty ? '>' : '> $line']
        .join('\n');

/// Il corpo senza le righe vuote in cima: quelle lasciate sopra una
/// citazione condivisa, se poi non ci si è scritto nulla. Il rientro della
/// prima riga con testo resta.
String withoutLeadingBlankLines(String body) =>
    body.replaceFirst(RegExp(r'^([ \t]*\n)+'), '');
