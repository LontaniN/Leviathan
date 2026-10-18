import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/shared_text.dart';
import 'package:leviathan/state/share_inbox.dart';

void main() {
  group('condivisione nella bozza', () {
    test('bozza vuota: l\'oggetto fa da titolo, il testo da corpo', () {
      final m = mergeShared('', '', (
        subject: ' Limiti notevoli ',
        text: 'https://esempio.it\n',
      ));
      expect(m.title, 'Limiti notevoli');
      expect(m.body, 'https://esempio.it');
      expect(m.appended, isFalse);
    });

    test('senza oggetto tutto va nel corpo', () {
      final m = mergeShared('', '', (subject: '', text: 'Un pensiero'));
      expect(m.title, '');
      expect(m.body, 'Un pensiero');
    });

    test('un oggetto uguale al testo non si ripete', () {
      final m = mergeShared('', '', (subject: 'Ciao', text: 'Ciao'));
      expect(m.title, '');
      expect(m.body, 'Ciao');
    });

    test('bozza a metà: il testo va in fondo, il titolo resta', () {
      final m = mergeShared('Idea', 'Prima riga\n\n', (
        subject: 'Articolo',
        text: 'https://esempio.it',
      ));
      expect(m.title, 'Idea');
      expect(m.body, 'Prima riga\n\nArticolo\n\nhttps://esempio.it');
      expect(m.appended, isTrue);
    });

    test('solo titolo nella bozza: conta come bozza a metà', () {
      final m = mergeShared('Idea', '', (subject: '', text: 'testo'));
      expect(m.title, 'Idea');
      expect(m.body, 'testo');
      expect(m.appended, isTrue);
    });
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
