/// Le scadenze dei task: quanto manca e sotto quale intestazione cadono.
library;

import 'note.dart';

/// Le intestazioni della scheda "Scadenze", dalla più urgente.
enum DueSection { overdue, today, tomorrow, week, later }

/// Quanti giorni mancano dal giorno di [now] a [due]: 0 oggi, negativo se è
/// passata. Si contano i giorni di calendario (non le ore: l'ora legale
/// sposterebbe il conto).
int daysUntil(DateTime due, DateTime now) => DateTime.utc(
  due.year,
  due.month,
  due.day,
).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

/// L'intestazione sotto cui cade una scadenza fra [days] giorni.
DueSection dueSection(int days) => switch (days) {
  < 0 => DueSection.overdue,
  0 => DueSection.today,
  1 => DueSection.tomorrow,
  <= 7 => DueSection.week,
  _ => DueSection.later,
};

/// I task ancora da fare con una scadenza, dalla più vicina (le scadute in
/// cima); a pari giorno dal più recente.
List<Note> tasksByDue(Iterable<Note> notes) {
  final tasks = [
    for (final n in notes)
      if (n.isOpenTask && n.due != null) n,
  ];
  tasks.sort((a, b) {
    final byDue = a.due!.compareTo(b.due!);
    if (byDue != 0) return byDue;
    return b.created.compareTo(a.created);
  });
  return tasks;
}
