import 'package:flutter/services.dart' show TextEditingValue, TextSelection;
import 'package:markdown/markdown.dart' as md;

import 'note_links.dart';

/// Strumenti per il Markdown del corpo delle note: caselle delle checklist,
/// testo semplice per le anteprime e modifiche della barra di formattazione.

/// Una voce di checklist (`- [ ] testo` o `- [x] testo`), anche numerata
/// (`1. [ ] testo`) o dentro una citazione (`> - [ ] testo`): il Markdown le
/// disegna tutte come caselle. Il gruppo 1 è il carattere tra le quadre.
final _taskItem = RegExp(
  r'^[ \t]*(?:>[ \t]?)*[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+\[( |x|X)\](?=\s|$)',
  multiLine: true,
);

/// Gli intervalli dentro i blocchi di codice ``` (lì `- [ ]` non è una
/// casella).
List<(int, int)> _codeBlocks(String text) {
  final blocks = <(int, int)>[];
  final fence = RegExp(r'^[ \t]*```', multiLine: true);
  final marks = fence.allMatches(text).toList();
  for (var i = 0; i + 1 < marks.length; i += 2) {
    blocks.add((marks[i].start, marks[i + 1].end));
  }
  if (marks.length.isOdd) blocks.add((marks.last.start, text.length));
  return blocks;
}

/// La posizione del carattere tra le quadre di ogni casella, in ordine.
List<int> checkboxOffsets(String body) {
  final code = _codeBlocks(body);
  return [
    for (final m in _taskItem.allMatches(body))
      if (!code.any((b) => m.start >= b.$1 && m.start < b.$2)) m.end - 2,
  ];
}

/// Quante caselle disegna davvero la lettura della nota: lo stesso parser e
/// le stesse estensioni di `MarkdownBody`. Se non sono quante ne trova
/// [checkboxOffsets], numerarle contando spunterebbe la casella sbagliata.
int renderedCheckboxCount(String body) {
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  var count = 0;
  void visit(List<md.Node>? nodes) {
    for (final node in nodes ?? const <md.Node>[]) {
      if (node is! md.Element) continue;
      if (node.tag == 'input' && node.attributes['type'] == 'checkbox') {
        count++;
      }
      visit(node.children);
    }
  }

  visit(document.parse(body));
  return count;
}

/// Spunta o toglie la spunta alla casella numero [index] (da 0).
String toggleCheckbox(String body, int index) {
  final offsets = checkboxOffsets(body);
  if (index < 0 || index >= offsets.length) return body;
  final at = offsets[index];
  final mark = body[at] == ' ' ? 'x' : ' ';
  return body.replaceRange(at, at + 1, mark);
}

/// Quante parole ha il testo, senza contare i simboli Markdown.
int wordCount(String markdown) => RegExp(
  r"[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*",
  unicode: true,
).allMatches(plainText(markdown)).length;

/// Il testo senza i simboli Markdown, per anteprime e titoli ricavati dal
/// corpo. Le caselle diventano ☐ e ☑.
String plainText(String markdown) {
  return withLinkLabels(markdown)
      .split('\n')
      .map((line) {
        var l = line;
        l = l.replaceFirstMapped(
          RegExp(r'^(\s*)[-*+] \[( |x|X)\]\s?'),
          (m) => '${m[1]}${m[2] == ' ' ? '☐' : '☑'} ',
        );
        l = l.replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '');
        l = l.replaceFirst(RegExp(r'^\s*>\s?'), '');
        l = l.replaceFirst(RegExp(r'^\s*[-*+]\s+'), '• ');
        l = l.replaceFirst(RegExp(r'^\s*```.*$'), '');
        return l;
      })
      .join('\n')
      .replaceAllMapped(RegExp(r'!?\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'(\*\*|__)(.+?)\1'), (m) => m[2]!)
      .replaceAllMapped(
        RegExp(r'(?<![\w*])([*_])(?!\s)(.+?)(?<!\s)\1(?![\w*])'),
        (m) => m[2]!,
      )
      .replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m[1]!);
}

/// Racchiude la selezione tra [marker] (es. `**` per il grassetto). Se è
/// già racchiusa, toglie i simboli. Senza selezione inserisce la coppia e
/// mette il cursore in mezzo.
TextEditingValue wrapSelection(TextEditingValue value, String marker) {
  final text = value.text;
  final sel = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);
  final start = sel.start;
  final end = sel.end;
  final n = marker.length;
  final wrapped =
      start >= n &&
      end + n <= text.length &&
      text.substring(start - n, start) == marker &&
      text.substring(end, end + n) == marker;
  if (wrapped && start != end) {
    return TextEditingValue(
      text: text
          .replaceRange(end, end + n, '')
          .replaceRange(start - n, start, ''),
      selection: TextSelection(baseOffset: start - n, extentOffset: end - n),
    );
  }
  final inner = text.substring(start, end);
  return TextEditingValue(
    text: text.replaceRange(start, end, '$marker$inner$marker'),
    selection: TextSelection(baseOffset: start + n, extentOffset: end + n),
  );
}

/// Inizi di riga che la barra sa mettere e togliere.
enum LinePrefix {
  heading('## '),
  bullet('- '),
  numbered('1. '),
  checkbox('- [ ] '),
  quote('> ');

  const LinePrefix(this.text);

  final String text;
}

/// Un inizio di riga già presente: titolo, elenco, casella o citazione.
final _anyPrefix = RegExp(r'^(#{1,6} |[-*+] \[[ xX]\] |[-*+] |\d+[.)] |> )');

RegExp _prefixPattern(LinePrefix p) => switch (p) {
  LinePrefix.heading => RegExp(r'^#{1,6} '),
  LinePrefix.bullet => RegExp(r'^[-*+] (?!\[[ xX]\] )'),
  LinePrefix.numbered => RegExp(r'^\d+[.)] '),
  LinePrefix.checkbox => RegExp(r'^[-*+] \[[ xX]\] '),
  LinePrefix.quote => RegExp(r'^> '),
};

/// Mette [prefix] all'inizio delle righe toccate dalla selezione (al posto
/// di un eventuale altro inizio), oppure lo toglie se ce l'hanno già tutte.
/// Gli elenchi numerati si numerano da 1.
TextEditingValue toggleLinePrefix(TextEditingValue value, LinePrefix prefix) {
  final text = value.text;
  final sel = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);
  final from = sel.start == 0 ? 0 : text.lastIndexOf('\n', sel.start - 1) + 1;
  var to = text.indexOf('\n', sel.end);
  if (to == -1) to = text.length;

  final lines = text.substring(from, to).split('\n');
  final pattern = _prefixPattern(prefix);
  final remove = lines.every(pattern.hasMatch);
  var number = 0;
  final changed = [
    for (final line in lines)
      if (remove)
        line.replaceFirst(pattern, '')
      else
        (prefix == LinePrefix.numbered ? '${++number}. ' : prefix.text) +
            line.replaceFirst(_anyPrefix, ''),
  ].join('\n');

  final newText = text.replaceRange(from, to, changed);
  final delta = changed.length - (to - from);
  return TextEditingValue(
    text: newText,
    selection: sel.isCollapsed
        ? TextSelection.collapsed(
            offset: (sel.end + delta).clamp(from, from + changed.length),
          )
        : TextSelection(baseOffset: from, extentOffset: from + changed.length),
  );
}

/// Dopo un invio in una riga di elenco, la riga nuova continua l'elenco
/// (`- `, `- [ ] `, numero successivo, `> `). Un invio su una voce vuota
/// chiude l'elenco togliendo il simbolo. Se [after] non è un semplice
/// invio dopo [before], lo restituisce com'è.
TextEditingValue continueList(TextEditingValue before, TextEditingValue after) {
  final cursor = after.selection.baseOffset;
  if (!after.selection.isCollapsed ||
      cursor < 1 ||
      after.text.length != before.text.length + 1 ||
      after.text[cursor - 1] != '\n' ||
      after.text.replaceRange(cursor - 1, cursor, '') != before.text) {
    return after;
  }
  final text = after.text;
  final lineStart = cursor < 2 ? 0 : text.lastIndexOf('\n', cursor - 2) + 1;
  final line = text.substring(lineStart, cursor - 1);
  final m = RegExp(r'^([ \t]*)([-*+] \[[ xX]\] |[-*+] |(\d+)([.)]) |> )')
      .firstMatch(line);
  if (m == null) return after;

  if (line.length == m.end) {
    // Voce vuota: si chiude l'elenco.
    final cleaned = text.replaceRange(lineStart, cursor, '');
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: lineStart),
    );
  }
  final indent = m[1]!;
  final String next;
  if (m[3] != null) {
    next = '$indent${int.parse(m[3]!) + 1}${m[4]} ';
  } else if (m[2]!.contains('[')) {
    next = '$indent${m[2]![0]} [ ] ';
  } else {
    next = '$indent${m[2]}';
  }
  return TextEditingValue(
    text: text.replaceRange(cursor, cursor, next),
    selection: TextSelection.collapsed(offset: cursor + next.length),
  );
}
