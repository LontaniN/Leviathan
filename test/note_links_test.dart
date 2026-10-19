import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/markdown.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/model/note_links.dart';

Note _note(String id, String title) => Note(
  id: id,
  title: title,
  body: '',
  tags: const [],
  sources: const [],
  created: DateTime(2026),
  updated: DateTime(2026),
);

void main() {
  final limiti = _note('20261017-limiti', 'Limiti notevoli');
  final derivate = _note('20261018-derivate', 'Derivate');
  final notes = [limiti, derivate];

  test('trova i collegamenti, con e senza testo', () {
    final links = noteLinks(
      'Vedi [[20261017-limiti|i limiti]] e [[Derivate]].',
    );
    expect(links.map((l) => (l.target, l.label)), [
      ('20261017-limiti', 'i limiti'),
      ('Derivate', 'Derivate'),
    ]);
    expect(links.first.start, 5);
  });

  test('non scambia per collegamenti le quadre normali', () {
    expect(noteLinks('[link](https://x.it) e [[ ]] e [[a\nb]]'), isEmpty);
  });

  test('porta alla nota per nome del file o per titolo', () {
    expect(resolveNoteLink(notes, '20261017-limiti'), limiti);
    expect(resolveNoteLink(notes, 'derivate'), derivate);
    expect(resolveNoteLink(notes, 'limiti notevoli'), limiti);
    expect(resolveNoteLink(notes, 'nel cestino'), isNull);
  });

  test('il collegamento usa il nome del file e un testo pulito', () {
    expect(
      noteLink(limiti, 'Limiti [notevoli] | 2'),
      '[[20261017-limiti|Limiti notevoli 2]]',
    );
    expect(noteLink(limiti, '  '), '[[20261017-limiti]]');
  });

  test('senza selezione entra il titolo, al cursore', () {
    final value = insertNoteLink(
      const TextEditingValue(
        text: 'Vedi  qui',
        selection: TextSelection.collapsed(offset: 5),
      ),
      limiti,
      'Limiti notevoli',
    );
    expect(value.text, 'Vedi [[20261017-limiti|Limiti notevoli]] qui');
    expect(value.selection.baseOffset, value.text.length - 4);
  });

  test('il testo selezionato diventa il testo del collegamento', () {
    final value = insertNoteLink(
      const TextEditingValue(
        text: 'Ripassa i limiti oggi',
        selection: TextSelection(baseOffset: 8, extentOffset: 16),
      ),
      limiti,
      'Limiti notevoli',
    );
    expect(value.text, 'Ripassa [[20261017-limiti|i limiti]] oggi');
  });

  test('senza cursore il collegamento va in fondo', () {
    final value = insertNoteLink(
      const TextEditingValue(text: 'Fine'),
      derivate,
      'Derivate',
    );
    expect(value.text, 'Fine[[20261018-derivate|Derivate]]');
  });

  test('le anteprime mostrano solo il testo del collegamento', () {
    expect(
      plainText('Vedi [[20261017-limiti|i limiti]] e [[Derivate]]'),
      'Vedi i limiti e Derivate',
    );
  });
}
