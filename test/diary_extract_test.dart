import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/data/diary_store.dart';
import 'package:leviathan/model/diary_extract.dart';
import 'package:leviathan/state/diary_extracts.dart';

DiaryExtract _e(String id, String text, int start, {String? note}) =>
    DiaryExtract(
      id: id,
      day: '2026-10-25',
      text: text,
      start: start,
      noteId: note,
    );

void main() {
  test('il pezzo si ritrova anche se il testo intorno cambia', () {
    final a = _e('a', 'orto sul tetto', 10);
    expect(extractRanges('Idea: un orto sul tetto.', [a]).single.start, 9);
    expect(
      extractRanges('Stamattina pioveva. Idea: un orto sul tetto.', [
        a,
      ]).single.start,
      29,
    );
    // Cancellato o cambiato, non c'è più.
    expect(extractRanges('Idea: un orto in cortile.', [a]), isEmpty);
  });

  test('fra più copie si prende la più vicina a dove era', () {
    final a = _e('a', 'mare', 20);
    final ranges = extractRanges('mare al mattino, mare la sera', [a]);
    expect(ranges.single.start, 17);
  });

  test('due pezzi accavallati tengono il primo, in ordine di testo', () {
    final text = 'uno due tre quattro';
    final ranges = extractRanges(text, [
      _e('b', 'tre quattro', 8),
      _e('a', 'uno due', 0),
      _e('c', 'due tre', 4),
    ]);
    expect([for (final r in ranges) r.extract.id], ['a', 'b']);
    expect(extractAt(ranges, 9)?.extract.id, 'b');
    expect(extractAt(ranges, 7), isNull);
  });

  test('i pezzi si salvano accanto ai giorni, senza rovinarli', () {
    final root = Directory.systemTemp.createTempSync('leviathan_extracts');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = DiaryStore(Directory('${root.path}/diary'));
    expect(store.readExtracts(), isEmpty);

    store.write(DateTime(2026, 10, 25), 'Pioggia.');
    store.writeExtracts([
      const DiaryExtract(
        id: 'a',
        day: '2026-10-25',
        text: 'Pioggia',
        start: 0,
        tags: ['meteo'],
        sources: ['io'],
      ),
      _e('b', 'x', 3, note: 'nota-1'),
    ]);
    final read = store.readExtracts();
    expect(read.map((e) => e.id), ['a', 'b']);
    expect(read.first.tags, ['meteo']);
    expect(read.first.sources, ['io']);
    expect(read.first.pending, isTrue);
    expect(read.last.noteId, 'nota-1');
    // Il file dei pezzi non è un giorno.
    expect(store.readAll().keys, ['2026-10-25']);

    File('${root.path}/diary/extracts.json').writeAsStringSync('{rotto');
    expect(store.readExtracts(), isEmpty);
  });

  test('i colori delle note cancellate si tolgono', () {
    final root = Directory.systemTemp.createTempSync('leviathan_orphans');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = DiaryStore(Directory('${root.path}/diary'));
    final extracts = DiaryExtracts(store)
      ..add(day: '2026-10-25', text: 'a', start: 0, noteId: 'viva')
      ..add(day: '2026-10-25', text: 'b', start: 2, noteId: 'cancellata')
      ..add(day: '2026-10-25', text: 'c', start: 4);
    extracts.removeOrphans((id) => id == 'viva' ? id : null);

    expect(extracts.all.map((e) => e.text), ['a', 'c']);
    expect(store.readExtracts().map((e) => e.text), ['a', 'c']);
  });

  group('il pezzo segue le modifiche', () {
    const before = 'Idea: un orto sul tetto.';
    final a = _e('a', 'orto sul tetto', 9, note: 'n');

    DiaryExtract? follow(String after, {int caret = -1}) {
      final changed = followEdit(before, after, [a], caret: caret);
      return changed.isEmpty ? null : changed.single;
    }

    test('scrivendo dentro si allarga e tiene la nota', () {
      final e = follow('Idea: un orto grande sul tetto.')!;
      expect(e.text, 'orto grande sul tetto');
      expect(e.start, 9);
      expect(e.noteId, 'n');
      expect(e.id, 'a');
      expect(
        extractRanges('Idea: un orto grande sul tetto.', [e]).single.end,
        30,
      );
    });

    test('correggendo una parola resta collegato', () {
      expect(
        follow('Idea: un orto sul tettuccio.')!.text,
        'orto sul tettuccio',
      );
      expect(follow('Idea: un orto sul tet.')!.text, 'orto sul tet');
    });

    test('scrivendo ai bordi il testo nuovo resta fuori', () {
      expect(follow('Idea: un bell\'orto sul tetto.'), isNull);
      // Il cursore alla fine di ", subito": senza, il "to" di "subito"
      // sembrerebbe scritto dentro "tetto".
      expect(follow('Idea: un orto sul tetto, subito.', caret: 31), isNull);
      expect(follow('Stamattina. Idea: un orto sul tetto.'), isNull);
    });

    test('il cursore dice dove si è scritto fra lettere uguali', () {
      // "tetto" → "tettto": senza cursore la t in più cade dentro comunque.
      expect(
        follow('Idea: un orto sul tettto.', caret: 21)!.text,
        'orto sul tettto',
      );
      // Una "o" scritta subito prima di "orto" resta fuori.
      expect(follow('Idea: un oorto sul tetto.', caret: 10), isNull);
    });

    test('cancellato tutto non cambia', () {
      expect(follow('Idea: un .'), isNull);
    });

    test('una modifica a cavallo del bordo prende il testo nuovo', () {
      final e = follow('Idea: due orti sul tetto.')!;
      expect(e.text, 'due orti sul tetto');
      expect(e.start, 6);
    });
  });
}
