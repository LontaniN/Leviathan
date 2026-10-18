/// Date scritte come le si dice: "Oggi", "Ieri", "3 ott".
library;

const _months = [
  'gen', 'feb', 'mar', 'apr', 'mag', 'giu', //
  'lug', 'ago', 'set', 'ott', 'nov', 'dic',
];

const _monthNames = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', //
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
];

const _weekdays = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];

String _two(int n) => n.toString().padLeft(2, '0');

/// Giorni di calendario fra [from] e [to] (non ore diviso 24: l'ora legale
/// sposterebbe il conto).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Data completa e breve: "17 ott 2026".
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// L'ora: "14:05".
String formatTime(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

/// Data corta per gli elenchi, più precisa quanto più è vicina: l'ora per
/// oggi e ieri, il giorno della settimana negli ultimi sei giorni, giorno e
/// mese nell'anno, altrimenti anche l'anno.
///
/// Va accanto alle intestazioni di [dateSection]: sotto "Ieri" ripetere
/// "ieri" non direbbe niente, l'ora sì.
String formatRelative(DateTime date, DateTime now) {
  final days = _daysBetween(date, now);
  if (days <= 1) return formatTime(date);
  if (days < 7) return _weekdays[date.weekday - 1];
  if (date.year == now.year) return '${date.day} ${_months[date.month - 1]}';
  return formatDate(date);
}

/// L'intestazione sotto cui cade [date] in un elenco dal più recente:
/// "Oggi", "Ieri", "Questa settimana", poi il mese ("Settembre", o
/// "Settembre 2025" se di un altro anno).
String dateSection(DateTime date, DateTime now) {
  final days = _daysBetween(date, now);
  if (days <= 0) return 'Oggi';
  if (days == 1) return 'Ieri';
  if (days < 7) return 'Questa settimana';
  final month = _monthNames[date.month - 1];
  return date.year == now.year ? month : '$month ${date.year}';
}
