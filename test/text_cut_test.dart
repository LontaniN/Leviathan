import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/search.dart';
import 'package:leviathan/model/text_cut.dart';

/// Vero se [s] non contiene mezze coppie surrogate.
bool _wellFormed(String s) {
  for (var i = 0; i < s.length; i++) {
    final u = s.codeUnitAt(i);
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 >= s.length) return false;
      final next = s.codeUnitAt(i + 1);
      if (next < 0xDC00 || next > 0xDFFF) return false;
      i++;
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      return false;
    }
  }
  return true;
}

Note _note(String body, {String title = ''}) => Note(
  id: 'x',
  title: title,
  body: body,
  tags: const [],
  sources: const [],
  created: DateTime(2026),
  updated: DateTime(2026),
);

void main() {
  test('non spezza le emoji ai bordi', () {
    const s = 'ab😀cd'; // 😀 occupa le posizioni 2 e 3
    expect(safeSubstring(s, 0, 3), 'ab');
    expect(safeSubstring(s, 3), '😀cd');
    expect(safeSubstring(s, 1, 4), 'b😀');
    expect(safeSubstring(s, 3, 3), '');
  });

  test('il titolo ricavato dal corpo non taglia un\'emoji', () {
    final title = _note('${'a' * 59}😀 coda').displayTitle('u');
    expect(_wellFormed(title), isTrue);
    expect(title, '${'a' * 59}…');
  });

  test('l\'estratto della ricerca non taglia un\'emoji', () {
    final note = _note('cerca ${'a' * 153}😀 dopo', title: 'T');
    final hit = searchNotes([note], const SearchQuery(text: 'cerca')).single;
    expect(_wellFormed(hit.snippet), isTrue);
  });

  test('l\'anteprima del calendario non taglia un\'emoji', () {
    final note = _note('cerca ${'a' * 113}😀 dopo', title: 'T');
    expect(_wellFormed(matchPreview(note, ['cerca'], 'u')), isTrue);
  });
}
