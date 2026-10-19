import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/shared_text.dart';
import 'package:leviathan/state/share_inbox.dart';

void main() {
  group('condivisione nella bozza', () {
    test('bozza vuota: l\'oggetto fa da titolo, il testo è una citazione', () {
      final m = mergeShared('', '', (
        subject: ' Limiti notevoli ',
        text: 'https://esempio.it\n',
      ));
      expect(m.title, 'Limiti notevoli');
      expect(m.body, '\n\n> https://esempio.it');
      expect(m.appended, isFalse);
      // Si scrive sopra la citazione.
      expect(m.cursor, 0);
    });

    test('senza oggetto tutto va nel corpo', () {
      final m = mergeShared('', '', (subject: '', text: 'Un pensiero'));
      expect(m.title, '');
      expect(m.body, '\n\n> Un pensiero');
    });

    test('un oggetto uguale al testo non si ripete', () {
      final m = mergeShared('', '', (subject: 'Ciao', text: 'Ciao'));
      expect(m.title, '');
      expect(m.body, '\n\n> Ciao');
    });

    test('più paragrafi restano un\'unica citazione', () {
      final m = mergeShared('', '', (subject: '', text: 'Uno\n\nDue'));
      expect(m.body, '\n\n> Uno\n>\n> Due');
    });

    test(
      'bozza a metà: la citazione va in fondo, il cursore dopo il testo',
      () {
        final m = mergeShared('Idea', 'Prima riga\n\n', (
          subject: 'Articolo',
          text: 'https://esempio.it',
        ));
        expect(m.title, 'Idea');
        expect(m.body, 'Prima riga\n\n> Articolo\n>\n> https://esempio.it');
        expect(m.appended, isTrue);
        expect(m.cursor, 'Prima riga'.length);
      },
    );

    test('solo titolo nella bozza: conta come bozza a metà', () {
      final m = mergeShared('Idea', '', (subject: '', text: 'testo'));
      expect(m.title, 'Idea');
      expect(m.body, '\n\n> testo');
      expect(m.appended, isTrue);
    });

    test('solo oggetto: diventa il titolo e il corpo non cambia', () {
      final m = mergeShared('', 'corpo', (subject: 'Titolo', text: ''));
      expect(m.title, 'Titolo');
      expect(m.body, 'corpo');
    });
  });

  test('le righe vuote in cima al corpo si tolgono al salvataggio', () {
    expect(withoutLeadingBlankLines('\n\n> citazione'), '> citazione');
    expect(withoutLeadingBlankLines(' \n\t\nTesto'), 'Testo');
    expect(withoutLeadingBlankLines('    codice\n'), '    codice\n');
    expect(withoutLeadingBlankLines('Testo\n\nAltro'), 'Testo\n\nAltro');
  });

  test('la coda consegna le condivisioni in ordine, una volta sola', () {
    final inbox = ShareInbox();
    var notified = 0;
    inbox.addListener(() => notified++);
    expect(inbox.take(), isNull);
    inbox
      ..receive((subject: '', text: 'uno'))
      ..receive((subject: '', text: 'due'));
    expect(notified, 2);
    expect(inbox.take()?.text, 'uno');
    expect(inbox.take()?.text, 'due');
    expect(inbox.hasPending, isFalse);
  });
}
