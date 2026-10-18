import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/dates.dart';

void main() {
  // Sabato 17 ottobre 2026, pomeriggio.
  final now = DateTime(2026, 10, 17, 15, 30);

  test('data completa', () {
    expect(formatDate(DateTime(2026, 1, 5)), '5 gen 2026');
  });

  test('data relativa: più precisa quanto più è vicina', () {
    expect(formatRelative(DateTime(2026, 10, 17, 9, 5), now), '09:05');
    expect(formatRelative(DateTime(2026, 10, 16, 23, 59), now), '23:59');
    expect(formatRelative(DateTime(2026, 10, 12), now), 'lun');
    expect(formatRelative(DateTime(2026, 10, 10), now), '10 ott');
    expect(formatRelative(DateTime(2025, 12, 31), now), '31 dic 2025');
  });

  test('sezioni della lista per giorno e mese', () {
    expect(dateSection(DateTime(2026, 10, 17, 0, 1), now), 'Oggi');
    expect(dateSection(DateTime(2026, 10, 16), now), 'Ieri');
    expect(dateSection(DateTime(2026, 10, 11), now), 'Questa settimana');
    expect(dateSection(DateTime(2026, 10, 2), now), 'Ottobre');
    expect(dateSection(DateTime(2025, 3, 2), now), 'Marzo 2025');
  });

  test('il cambio dell\'ora legale non sposta i giorni', () {
    // Fra il 24 e il 25 ottobre 2026 in Italia si torna all'ora solare.
    final after = DateTime(2026, 10, 25, 0, 30);
    expect(dateSection(DateTime(2026, 10, 24, 23, 30), after), 'Ieri');
  });
}
