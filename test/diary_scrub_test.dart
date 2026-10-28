import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/diary_scrub.dart';

void main() {
  test('giorni fa contati sul calendario', () {
    final today = DateTime(2026, 10, 25, 9);
    expect(daysAgo(DateTime(2026, 10, 25, 23), today), 0);
    expect(daysAgo(DateTime(2026, 10, 24, 23, 59), today), 1);
    // Attraverso il cambio dell'ora legale (25 ottobre 2026).
    expect(daysAgo(DateTime(2026, 3, 1), today), 238);
  });

  test('la barra arriva al giorno scritto più vecchio, almeno 30 giorni', () {
    expect(scrubRange([]), 30);
    expect(scrubRange([2, 10]), 30);
    expect(scrubRange([2, 400]), 400);
  });

  test('il dito sceglie il giorno in proporzione', () {
    expect(scrubDay(0, 100, []), 0);
    expect(scrubDay(0.5, 100, []), 50);
    expect(scrubDay(1, 100, []), 100);
    expect(scrubDay(-0.2, 100, []), 0);
    expect(scrubDay(1.3, 100, []), 100);
  });

  test('vicino a un giorno scritto ci si aggancia', () {
    expect(scrubDay(0.5, 100, [47, 80], snap: 0.05), 47);
    expect(scrubDay(0.5, 100, [40, 80], snap: 0.05), 50);
    // Fra due giorni scritti vince il più vicino.
    expect(scrubDay(0.5, 100, [47, 52], snap: 0.05), 52);
  });
}
