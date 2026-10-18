import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/l10n/app_localizations.dart';
import 'package:leviathan/model/dates.dart';

void main() {
  // Sabato 17 ottobre 2026, pomeriggio.
  final now = DateTime(2026, 10, 17, 15, 30);
  final it = lookupAppLocalizations(const Locale('it'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('data completa', () {
    expect(formatDate(it, DateTime(2026, 1, 5)), '5 gen 2026');
    expect(formatDate(en, DateTime(2026, 1, 5)), 'Jan 5, 2026');
  });

  test('data per esteso', () {
    expect(formatLongDate(it, DateTime(2026, 10, 3)), '3 ottobre 2026');
    expect(formatLongDate(en, DateTime(2026, 10, 3)), 'October 3, 2026');
  });

  test('data relativa: più precisa quanto più è vicina', () {
    expect(formatRelative(it, DateTime(2026, 10, 17, 9, 5), now), '09:05');
    expect(formatRelative(it, DateTime(2026, 10, 16, 23, 59), now), '23:59');
    expect(formatRelative(it, DateTime(2026, 10, 12), now), 'lun');
    expect(formatRelative(it, DateTime(2026, 10, 10), now), '10 ott');
    expect(formatRelative(it, DateTime(2025, 12, 31), now), '31 dic 2025');
  });

  test('data relativa in inglese', () {
    expect(formatRelative(en, DateTime(2026, 10, 12), now), 'Mon');
    expect(formatRelative(en, DateTime(2026, 10, 10), now), 'Oct 10');
    expect(formatRelative(en, DateTime(2025, 12, 31), now), 'Dec 31, 2025');
  });

  test('sezioni della lista per giorno e mese', () {
    expect(dateSection(it, DateTime(2026, 10, 17, 0, 1), now), 'Oggi');
    expect(dateSection(it, DateTime(2026, 10, 16), now), 'Ieri');
    expect(dateSection(it, DateTime(2026, 10, 11), now), 'Questa settimana');
    expect(dateSection(it, DateTime(2026, 10, 2), now), 'Ottobre');
    expect(dateSection(it, DateTime(2025, 3, 2), now), 'Marzo 2025');
  });

  test('sezioni in inglese', () {
    expect(dateSection(en, DateTime(2026, 10, 17, 0, 1), now), 'Today');
    expect(dateSection(en, DateTime(2026, 10, 16), now), 'Yesterday');
    expect(dateSection(en, DateTime(2026, 10, 11), now), 'This week');
    expect(dateSection(en, DateTime(2025, 3, 2), now), 'March 2025');
  });

  test('il cambio dell\'ora legale non sposta i giorni', () {
    // Fra il 24 e il 25 ottobre 2026 in Italia si torna all'ora solare.
    final after = DateTime(2026, 10, 25, 0, 30);
    expect(dateSection(it, DateTime(2026, 10, 24, 23, 30), after), 'Ieri');
  });
}
