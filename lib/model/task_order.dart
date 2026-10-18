import 'note.dart';

/// Le fasce del task manager: cosa faccio ora, dopo, più avanti.
///
/// Un task senza fascia è ancora "da ordinare".
enum TaskBand {
  now,
  next,
  later;

  /// Il nome scritto nel frontmatter (`priority: "now"`).
  String get key => name;

  static TaskBand? fromKey(Object? value) {
    final key = '${value ?? ''}'.trim().toLowerCase();
    for (final band in values) {
      if (band.key == key) return band;
    }
    return null;
  }
}

/// Quanti task si consiglia di tenere in "Ora": è un avviso, non un blocco.
const nowLimit = 3;

/// Le cifre delle posizioni, in ordine: le stringhe si confrontano come
/// testo e basta.
const _digits = '0123456789abcdefghijklmnopqrstuvwxyz';

/// Una posizione strettamente fra [before] e [after] (null = nessun vicino
/// da quel lato).
///
/// Le posizioni sono stringhe confrontate in ordine alfabetico (indici
/// frazionari): spostare un task cambia solo il suo file, mai quello dei
/// vicini. Non finiscono mai con '0', così fra due posizioni c'è sempre
/// posto per un'altra.
String rankBetween(String? before, String? after) {
  final a = before ?? '';
  if (after != null && a.compareTo(after) >= 0) {
    throw ArgumentError('"$before" non viene prima di "$after"');
  }
  return _midpoint(a, after);
}

String _midpoint(String a, String? b) {
  if (b != null) {
    // Il prefisso comune resta uguale; si cerca il punto medio del resto.
    var n = 0;
    while (n < b.length && (n < a.length ? a[n] : '0') == b[n]) {
      n++;
    }
    if (n > 0) {
      return b.substring(0, n) +
          _midpoint(a.length > n ? a.substring(n) : '', b.substring(n));
    }
  }
  final digitA = a.isEmpty ? 0 : _digits.indexOf(a[0]);
  final digitB = b == null ? _digits.length : _digits.indexOf(b[0]);
  if (digitB - digitA > 1) {
    return _digits[((digitA + digitB) / 2).round()];
  }
  // Cifre vicine: si scende di una cifra.
  if (b != null && b.length > 1) return b.substring(0, 1);
  return _digits[digitA] + _midpoint(a.length > 1 ? a.substring(1) : '', null);
}

/// I task aperti divisi per fascia, ognuna nel suo ordine.
class TaskBoard {
  TaskBoard._(this.unsorted, this.bands);

  /// Task aperti, sistemati come li vuole il task manager.
  ///
  /// "Da ordinare" va dal più recente; nelle fasce conta la posizione (a
  /// parità, o senza posizione, il più vecchio prima).
  factory TaskBoard.of(Iterable<Note> notes) {
    final unsorted = <Note>[];
    final bands = {for (final band in TaskBand.values) band: <Note>[]};
    for (final note in notes) {
      if (!note.isOpenTask) continue;
      final band = note.band;
      if (band == null) {
        unsorted.add(note);
      } else {
        bands[band]!.add(note);
      }
    }
    unsorted.sort((a, b) => b.created.compareTo(a.created));
    for (final list in bands.values) {
      list.sort(_byRank);
    }
    return TaskBoard._(unsorted, bands);
  }

  final List<Note> unsorted;
  final Map<TaskBand, List<Note>> bands;

  bool get isEmpty =>
      unsorted.isEmpty && bands.values.every((list) => list.isEmpty);

  static int _byRank(Note a, Note b) {
    final ra = a.rank, rb = b.rank;
    if (ra != null && rb != null && ra != rb) return ra.compareTo(rb);
    // Senza posizione vanno in fondo.
    if (ra == null && rb != null) return 1;
    if (rb == null && ra != null) return -1;
    return a.created.compareTo(b.created);
  }
}

/// Una posizione valida da mettere fra i task di [list] agli indici
/// `index - 1` e `index` (escluso [moving], che si sta spostando).
///
/// Se i vicini non hanno una posizione, l'hanno uguale o non valida (es.
/// scritta a mano con lettere maiuscole), la fascia va rinumerata: in quel
/// caso restituisce null.
String? rankAt(List<Note> list, int index, {Note? moving}) {
  final others = [
    for (final n in list)
      if (n.id != moving?.id) n,
  ];
  final i = index.clamp(0, others.length);
  final before = i > 0 ? others[i - 1].rank : null;
  final after = i < others.length ? others[i].rank : null;
  if (i > 0 && !_isValidRank(before)) return null;
  if (i < others.length && !_isValidRank(after)) return null;
  if (before != null && after != null && before.compareTo(after) >= 0) {
    return null;
  }
  return rankBetween(before, after);
}

/// Una posizione con cui [rankBetween] sa lavorare: solo cifre di
/// [_digits] e mai '0' in fondo (altrimenti prima di lei non c'è posto).
bool _isValidRank(String? rank) =>
    rank != null &&
    rank.isNotEmpty &&
    !rank.endsWith('0') &&
    rank.split('').every(_digits.contains);

/// Posizioni nuove, equidistanti e in ordine, per [count] task.
List<String> spreadRanks(int count) {
  final ranks = <String>[];
  String? last;
  for (var i = 0; i < count; i++) {
    last = rankBetween(last, null);
    ranks.add(last);
  }
  return ranks;
}

/// Inserimento per confronti: per trovare il posto di un task in una fascia
/// si chiede "viene prima questo o quello?" sul task a metà dell'intervallo
/// ancora possibile, che a ogni risposta si dimezza. Bastano circa log₂(n)
/// domande (5 per 30 task).
class BinaryInsertion {
  BinaryInsertion(this.list) : _hi = list.length;

  /// I task della fascia, nel loro ordine, senza quello da inserire.
  final List<Note> list;
  int _lo = 0;
  int _hi;

  bool get isDone => _lo >= _hi;

  /// Il task con cui confrontare ora; null quando il posto è trovato.
  Note? get pivot => isDone ? null : list[(_lo + _hi) ~/ 2];

  /// Il posto trovato (o il migliore finora).
  int get index => _lo;

  /// Quante domande restano al massimo.
  int get remaining {
    var span = _hi - _lo, steps = 0;
    while (span > 0) {
      span ~/= 2;
      steps++;
    }
    return steps;
  }

  /// Risposta alla domanda: il nuovo task viene prima di [pivot]?
  void answer({required bool before}) {
    if (isDone) return;
    final mid = (_lo + _hi) ~/ 2;
    if (before) {
      _hi = mid;
    } else {
      _lo = mid + 1;
    }
  }
}
