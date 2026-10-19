import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/note.dart';
import 'package:leviathan/ui/note_body.dart';
import 'package:leviathan/ui/theme.dart';

Widget _body(String body, ValueChanged<String> onChanged) => MaterialApp(
  theme: buildTheme(LeviathanPalette.inchiostro),
  home: Scaffold(body: NoteBody(body, onChanged: onChanged)),
);

void main() {
  testWidgets('tocca la casella giusta anche in elenchi numerati e citazioni', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      _body('1. [ ] primo\n> - [ ] citato\n- [ ] terzo', (b) => changed = b),
    );
    final boxes = find.byIcon(Icons.check_box_outline_blank);
    expect(boxes, findsNWidgets(3));
    await tester.tap(boxes.first);
    expect(changed, startsWith('1. [x] primo'));
    await tester.tap(boxes.at(1));
    expect(changed, contains('> - [x] citato'));
  });

  testWidgets('se il conto non torna le caselle non si toccano', (
    tester,
  ) async {
    // Il blocco ~~~ è codice per il Markdown, ma la ricerca delle caselle
    // lo legge come testo: toccare quella vera spunterebbe l'altra.
    String? changed;
    await tester.pumpWidget(
      _body('~~~\n- [ ] codice\n~~~\n\n- [ ] vera', (b) => changed = b),
    );
    final boxes = find.byIcon(Icons.check_box_outline_blank);
    expect(boxes, findsOneWidget);
    await tester.tap(boxes, warnIfMissed: false);
    expect(changed, isNull);
  });

  testWidgets('un collegamento apre la nota; uno rotto è barrato', (
    tester,
  ) async {
    final target = Note(
      id: 'limiti',
      title: 'Limiti',
      body: '',
      tags: const [],
      sources: const [],
      created: DateTime(2026),
      updated: DateTime(2026),
    );
    Note? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(LeviathanPalette.inchiostro),
        home: Scaffold(
          body: NoteBody(
            'Vedi [[limiti|i limiti]] e [[sparita|la vecchia]].',
            notes: [target],
            onOpenNote: (n) => opened = n,
          ),
        ),
      ),
    );
    expect(find.textContaining('[[', findRichText: true), findsNothing);
    await tester.tapOnText(find.textRange.ofSubstring('i limiti'));
    expect(opened, target);

    final rich = tester.widget<RichText>(
      find.textContaining('la vecchia', findRichText: true),
    );
    TextSpan? broken;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == 'la vecchia') broken = span;
      return true;
    });
    expect(broken!.style!.decoration, TextDecoration.lineThrough);
  });
}
