/// Lo scorrimento veloce del diario: la colonna delle date fa da barra del
/// tempo, con oggi in cima e in fondo il giorno più vecchio fra le note e il
/// diario.
library;

/// Quanti giorni prima di [today] cade [day], contando i giorni di
/// calendario (non le ore: l'ora legale sposterebbe il conto).
int daysAgo(DateTime day, DateTime today) => DateTime.utc(
  today.year,
  today.month,
  today.day,
).difference(DateTime.utc(day.year, day.month, day.day)).inDays;

/// Quanti giorni copre la barra: fino al più vecchio dei giorni [days], ma mai
/// meno di [minDays], così anche un diario appena iniziato si scorre con
/// calma.
int scrubRange(Iterable<int> days, {int minDays = 30}) {
  var range = minDays;
  for (final ago in days) {
    if (ago > range) range = ago;
  }
  return range;
}

/// Il giorno (quanti giorni fa) sotto il dito a [fraction] della barra (0 in
/// cima, 1 in fondo).
///
/// Se un giorno scritto è vicino, entro [snap] (in frazione della barra), si
/// va su quello: i giorni vuoti si saltano senza doverli centrare.
/// [writtenAgo] è in ordine crescente.
int scrubDay(
  double fraction,
  int range,
  List<int> writtenAgo, {
  double snap = 0,
}) {
  final f = fraction.clamp(0.0, 1.0);
  final day = (f * range).round();
  int? best;
  var bestDistance = snap;
  for (final ago in writtenAgo) {
    final distance = (ago / range - f).abs();
    if (distance <= bestDistance) {
      best = ago;
      bestDistance = distance;
    }
  }
  return best ?? day;
}
