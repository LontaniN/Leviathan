/// Date scritte come le si dice: "Oggi", "Ieri", "3 ott" (o "Today",
/// "Yesterday", "Oct 3"), nella lingua dei testi [l].
library;

import '../l10n/app_localizations.dart';

const _months = {
  'it': [
    'gen', 'feb', 'mar', 'apr', 'mag', 'giu', //
    'lug', 'ago', 'set', 'ott', 'nov', 'dic',
  ],
  'en': [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ],
};

const _monthNames = {
  'it': [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', //
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
  ],
  'en': [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
};

const _weekdays = {
  'it': ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
  'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
};

const _weekdayInitials = {
  'it': ['L', 'M', 'M', 'G', 'V', 'S', 'D'],
  'en': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
};

/// La tabella della lingua di [l] (l'inglese se manca).
List<String> _in(Map<String, List<String>> table, AppLocalizations l) =>
    table[l.localeName] ?? table['en']!;

bool _italian(AppLocalizations l) => l.localeName == 'it';

String _two(int n) => n.toString().padLeft(2, '0');

/// Giorni di calendario fra [from] e [to] (non ore diviso 24: l'ora legale
/// sposterebbe il conto).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Il nome del mese (1-12) con l'iniziale maiuscola: "Ottobre", "October".
String monthName(AppLocalizations l, int month) =>
    _in(_monthNames, l)[month - 1];

/// Il mese (1-12) corto: "ott", "Oct".
String shortMonth(AppLocalizations l, int month) => _in(_months, l)[month - 1];

/// Il giorno della settimana (1 lunedì, 7 domenica) corto: "lun", "Mon".
String weekdayName(AppLocalizations l, int weekday) =>
    _in(_weekdays, l)[weekday - 1];

/// Le iniziali dei giorni della settimana, da lunedì.
List<String> weekdayInitials(AppLocalizations l) => _in(_weekdayInitials, l);

/// Giorno e mese corto: "10 ott", "Oct 10".
String _dayMonth(AppLocalizations l, DateTime date) {
  final month = _in(_months, l)[date.month - 1];
  return _italian(l) ? '${date.day} $month' : '$month ${date.day}';
}

/// Data completa e breve: "17 ott 2026", "Oct 17, 2026".
String formatDate(AppLocalizations l, DateTime date) => _italian(l)
    ? '${_dayMonth(l, date)} ${date.year}'
    : '${_dayMonth(l, date)}, ${date.year}';

/// Data completa per esteso: "17 ottobre 2026", "October 17, 2026".
String formatLongDate(AppLocalizations l, DateTime date) {
  final month = monthName(l, date.month);
  return _italian(l)
      ? '${date.day} ${month.toLowerCase()} ${date.year}'
      : '$month ${date.day}, ${date.year}';
}

/// Il giorno di [day] con l'ora di [time]: una nota datata a un altro giorno
/// tiene l'ora in cui la si salva (o quella che aveva), così l'ordine fra le
/// note dello stesso giorno resta sensato.
DateTime onDay(DateTime day, DateTime time) => DateTime(
  day.year,
  day.month,
  day.day,
  time.hour,
  time.minute,
  time.second,
  time.millisecond,
);

/// Stesso giorno di calendario.
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// L'ora: "14:05".
String formatTime(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

/// Data corta per gli elenchi, più precisa quanto più è vicina: l'ora per
/// oggi e ieri, il giorno della settimana negli ultimi sei giorni, giorno e
/// mese nell'anno, altrimenti anche l'anno.
///
/// Va accanto alle intestazioni di [dateSection]: sotto "Ieri" ripetere
/// "ieri" non direbbe niente, l'ora sì.
String formatRelative(AppLocalizations l, DateTime date, DateTime now) {
  final days = _daysBetween(date, now);
  if (days <= 1) return formatTime(date);
  if (days < 7) return _in(_weekdays, l)[date.weekday - 1];
  if (date.year == now.year) return _dayMonth(l, date);
  return formatDate(l, date);
}

/// L'intestazione sotto cui cade [date] in un elenco dal più recente:
/// "Oggi", "Ieri", "Questa settimana", poi il mese ("Settembre", o
/// "Settembre 2025" se di un altro anno).
String dateSection(AppLocalizations l, DateTime date, DateTime now) {
  final days = _daysBetween(date, now);
  if (days <= 0) return l.today;
  if (days == 1) return l.yesterday;
  if (days < 7) return l.thisWeek;
  final month = monthName(l, date.month);
  return date.year == now.year ? month : '$month ${date.year}';
}
