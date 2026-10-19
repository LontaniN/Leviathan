import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/brain_dump.dart';

void main() {
  test('una riga per task, nell\'ordine scritto', () {
    expect(brainDumpTitles('Chiamare Anna\nComprare il pane'), [
      'Chiamare Anna',
      'Comprare il pane',
    ]);
  });

  test('salta le righe vuote e toglie gli spazi', () {
    expect(brainDumpTitles('\n  Uno  \n\n   \nDue\n'), ['Uno', 'Due']);
  });

  test('toglie i segni di elenco e le caselle', () {
    expect(
      brainDumpTitles(
        '- Uno\n* Due\n• Tre\n4. Quattro\n5) Cinque\n- [ ] Sei\n[x] Sette',
      ),
      ['Uno', 'Due', 'Tre', 'Quattro', 'Cinque', 'Sei', 'Sette'],
    );
  });

  test('un trattino dentro il testo resta', () {
    expect(brainDumpTitles('Pre-iscrizione - entro venerdì'), [
      'Pre-iscrizione - entro venerdì',
    ]);
  });

  test('le righe ripetute contano una volta', () {
    expect(brainDumpTitles('Pane\npane\n- Pane\nLatte'), ['Pane', 'Latte']);
  });

  test('senza testo nessun task', () {
    expect(brainDumpTitles(''), isEmpty);
    expect(brainDumpTitles('-\n  \n[ ]'), isEmpty);
  });
}
