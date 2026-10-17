import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/markdown.dart';

TextEditingValue _v(String text, int start, [int? end]) => TextEditingValue(
  text: text,
  selection: TextSelection(baseOffset: start, extentOffset: end ?? start),
);

void main() {
  group('checklist', () {
    const body =
        'Spesa:\n- [ ] latte\n- [x] pane\n\n```\n- [ ] non conta\n```\n'
        '  * [ ] rientrata';

    test('trova le caselle fuori dal codice', () {
      expect(checkboxOffsets(body), hasLength(3));
    });

    test('spunta e toglie la spunta per posizione', () {
      final once = toggleCheckbox(body, 0);
      expect(once, contains('- [x] latte'));
      final twice = toggleCheckbox(once, 1);
      expect(twice, contains('- [ ] pane'));
      expect(toggleCheckbox(body, 2), contains('  * [x] rientrata'));
      expect(toggleCheckbox(body, 9), body);
    });
  });

  test('testo semplice per le anteprime', () {
    expect(plainText('# Titolo'), 'Titolo');
    expect(plainText('Un **grassetto** e _corsivo_'), 'Un grassetto e corsivo');
    expect(plainText('- [ ] da fare\n- [x] fatto'), '☐ da fare\n☑ fatto');
    expect(plainText('> citazione con `codice`'), 'citazione con codice');
    expect(plainText('[sito](https://x.it) e snake_case'), 'sito e snake_case');
    expect(plainText('- voce'), '• voce');
  });

  group('barra di formattazione', () {
    test('racchiude la selezione e la toglie', () {
      final bold = wrapSelection(_v('ciao mondo', 5, 10), '**');
      expect(bold.text, 'ciao **mondo**');
      expect(
        bold.selection,
        const TextSelection(baseOffset: 7, extentOffset: 12),
      );
      expect(wrapSelection(bold, '**').text, 'ciao mondo');
    });

    test('senza selezione mette il cursore tra i simboli', () {
      final v = wrapSelection(_v('ab', 1), '_');
      expect(v.text, 'a__b');
      expect(v.selection.baseOffset, 2);
    });

    test('elenco puntato su più righe, poi tolto', () {
      final list = toggleLinePrefix(_v('uno\ndue', 0, 7), LinePrefix.bullet);
      expect(list.text, '- uno\n- due');
      expect(toggleLinePrefix(list, LinePrefix.bullet).text, 'uno\ndue');
    });

    test('numerato e casella sostituiscono l\'inizio esistente', () {
      final numbered = toggleLinePrefix(
        _v('- uno\n- due', 0, 11),
        LinePrefix.numbered,
      );
      expect(numbered.text, '1. uno\n2. due');
      final boxes = toggleLinePrefix(numbered, LinePrefix.checkbox);
      expect(boxes.text, '- [ ] uno\n- [ ] due');
    });

    test('solo la riga del cursore', () {
      final v = toggleLinePrefix(_v('a\nb\nc', 2), LinePrefix.heading);
      expect(v.text, 'a\n## b\nc');
      expect(v.selection.baseOffset, 5);
    });
  });

  group('invio negli elenchi', () {
    TextEditingValue enter(String text) {
      final before = _v(text, text.length);
      return continueList(before, _v('$text\n', text.length + 1));
    }

    test('continua puntati, numerati, caselle e citazioni', () {
      expect(enter('- latte').text, '- latte\n- ');
      expect(enter('2. due').text, '2. due\n3. ');
      expect(enter('- [x] fatto').text, '- [x] fatto\n- [ ] ');
      expect(enter('> frase').text, '> frase\n> ');
      expect(enter('  - rientro').text, '  - rientro\n  - ');
    });

    test('su una voce vuota chiude l\'elenco', () {
      final v = enter('- latte\n- ');
      expect(v.text, '- latte\n');
      expect(v.selection.baseOffset, 8);
    });

    test('fuori da un elenco non cambia niente', () {
      expect(enter('testo').text, 'testo\n');
    });
  });
}
