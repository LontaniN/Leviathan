import 'package:flutter/services.dart' show TextEditingValue, TextSelection;

import 'note.dart';
import 'tags.dart';

/// Un collegamento a un'altra nota nel corpo: `[[id|testo]]`, dove `id` è
/// il nome del file della nota (non cambia mai, nemmeno se si cambia il
/// titolo) e `testo` è quello che si legge. È la stessa sintassi di
/// Obsidian, che quindi apre il collegamento.
///
/// Si legge anche `[[id]]` o `[[Titolo]]` scritti a mano: senza testo si
/// mostra il bersaglio. Il gruppo 1 è il bersaglio, il 2 il testo (se c'è).
final noteLinkPattern = RegExp(
  r'\[\[([^\[\]|\n]*[^\[\]|\s][^\[\]|\n]*)(?:\|([^\[\]\n]*))?\]\]',
);

/// Un collegamento trovato nel testo, con dove sta.
typedef NoteLinkMatch = ({int start, int end, String target, String label});

/// I collegamenti di [text], in ordine.
List<NoteLinkMatch> noteLinks(String text) => [
  for (final m in noteLinkPattern.allMatches(text))
    (
      start: m.start,
      end: m.end,
      target: m[1]!.trim(),
      label: linkLabel(m[1]!, m[2]),
    ),
];

/// Il testo da mostrare: quello dopo `|`, o il bersaglio se manca.
String linkLabel(String target, String? label) {
  final text = label?.trim() ?? '';
  return text.isEmpty ? target.trim() : text;
}

/// La nota a cui porta [target]: prima per nome del file, poi per titolo
/// (senza badare a maiuscole e accenti, come scrive a mano chi usa
/// Obsidian). Null se non c'è, ad esempio perché è nel cestino.
Note? resolveNoteLink(Iterable<Note> notes, String target) {
  final wanted = target.trim();
  if (wanted.isEmpty) return null;
  final folded = foldText(wanted);
  Note? byTitle;
  for (final note in notes) {
    if (note.id == wanted) return note;
    if (byTitle == null && foldText(note.title.trim()) == folded) {
      byTitle = note;
    }
  }
  return byTitle;
}

/// Il collegamento a [note] col testo [label]. Dal testo si tolgono i
/// caratteri che chiuderebbero il collegamento.
String noteLink(Note note, String label) {
  final text = label
      .replaceAll(RegExp(r'[\[\]|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.isEmpty ? '[[${note.id}]]' : '[[${note.id}|$text]]';
}

/// Mette nel testo un collegamento a [note] al posto della selezione: se
/// c'è del testo selezionato diventa il testo del collegamento, altrimenti
/// si usa il titolo della nota ([title]). Il cursore va subito dopo.
TextEditingValue insertNoteLink(
  TextEditingValue value,
  Note note,
  String title,
) {
  final text = value.text;
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);
  final selected = selection.textInside(text);
  final link = noteLink(note, selected.trim().isEmpty ? title : selected);
  final next = text.replaceRange(selection.start, selection.end, link);
  return TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: selection.start + link.length),
  );
}

/// [text] con i collegamenti ridotti al loro testo, per anteprime e
/// conteggi.
String withLinkLabels(String text) =>
    text.replaceAllMapped(noteLinkPattern, (m) => linkLabel(m[1]!, m[2]));
