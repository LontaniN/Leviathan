/// Testo arrivato da un'altra app col tasto Condividi: l'oggetto (es. il
/// titolo di una pagina, spesso vuoto) e il testo vero e proprio.
typedef SharedText = ({String subject, String text});

/// Aggiunge una condivisione al titolo e al corpo di una bozza.
///
/// L'oggetto diventa il titolo se la bozza non ne ha uno; altrimenti va nel
/// corpo, sopra il testo. Il testo va in fondo al corpo, staccato da una
/// riga vuota, così una bozza a metà non perde nulla. [appended] dice se la
/// bozza aveva già qualcosa (titolo o corpo).
({String title, String body, bool appended}) mergeShared(
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
  final existing = body.trimRight();
  return (
    title: useSubjectAsTitle ? subject : title,
    body: existing.trim().isEmpty
        ? addition
        : addition.isEmpty
        ? body
        : '$existing\n\n$addition',
    appended: appended,
  );
}
