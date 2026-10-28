import 'dart:convert';

import 'markdown.dart';
import 'task_order.dart';
import 'text_cut.dart';

/// Che domanda si fa una nota: cos'è successo (nota), cosa c'è da fare
/// (task) o cosa so (conoscenza).
enum NoteKind { note, task, knowledge }

/// Una nota: titolo, corpo, tag e fonti. Può essere un task da spuntare, o
/// una nota di conoscenza.
///
/// Su disco è un file Markdown con un'intestazione (frontmatter) in cima:
///
/// ```
/// ---
/// title: "Titolo"
/// tags: ["tag-uno", "tag-due"]
/// sources: ["Mario Rossi"]
/// created: "2026-10-17T14:05:12.000"
/// updated: "2026-10-17T14:05:12.000"
/// ---
/// Corpo della nota…
/// ```
///
/// Un task ha in più `type: "task"`, `done` e, se fatto, `done_at`; le note
/// normali non scrivono questi campi. Un task può avere una scadenza
/// (`due: "2026-10-30"`, solo il giorno). Nel task manager un task ha anche una
/// fascia (`priority: "now"`, `"next"` o `"later"`) e una posizione nella
/// fascia (`rank`, vedi [rankBetween]); senza fascia è "da ordinare". Una nota di conoscenza ha
/// `knowledge: true`; una fissata in cima alle recenti ha `pinned: true`.
///
/// I valori sono scritti come JSON, che è anche YAML valido: il file resta
/// leggibile da Obsidian e da qualsiasi editor. In lettura si accettano anche
/// le liste YAML a trattini che scrive Obsidian (`tags:` e sotto `  - uno`),
/// e le proprietà che Leviathan non usa (es. `aliases`) restano com'erano,
/// in [extraFrontmatter].
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.sources,
    required this.created,
    required this.updated,
    this.isTask = false,
    this.done = false,
    this.doneAt,
    this.due,
    this.knowledge = false,
    this.pinned = false,
    this.band,
    this.rank,
    this.extraFrontmatter = '',
  });

  /// Nome del file senza estensione; non cambia se si modifica il titolo.
  final String id;
  final String title;
  final String body;
  final List<String> tags;

  /// Da chi o da dove arriva l'informazione (di solito persone).
  /// Seconda categorizzazione delle note: non colora nulla.
  final List<String> sources;
  final DateTime created;
  final DateTime updated;

  /// Una nota da fare: si spunta quando è eseguita.
  final bool isTask;

  /// Solo per i task: già eseguito.
  final bool done;

  /// Quando il task è stato spuntato (se lo si sa).
  final DateTime? doneAt;

  /// Solo per i task: il giorno entro cui va fatto (senza ora); null se non
  /// ha scadenza.
  final DateTime? due;

  /// Solo per le note: dice cosa si sa, non cosa è successo.
  final bool knowledge;

  /// Fissata in cima alle recenti.
  final bool pinned;

  /// Solo per i task: la fascia del task manager; null se da ordinare.
  final TaskBand? band;

  /// Solo per i task: la posizione nella fascia (si confronta come testo).
  final String? rank;

  /// Le righe dell'intestazione che Leviathan non usa (proprietà aggiunte da
  /// Obsidian o a mano), da riscrivere identiche; vuoto se non ce ne sono.
  final String extraFrontmatter;

  /// Un task ancora da fare.
  bool get isOpenTask => isTask && !done;

  NoteKind get kind => isTask
      ? NoteKind.task
      : knowledge
      ? NoteKind.knowledge
      : NoteKind.note;

  /// Togliendo [isTask] o [done] si perdono anche spunta e data di
  /// esecuzione, e togliendo [isTask] anche fascia, posizione e scadenza,
  /// così non restano valori senza senso; un task non è mai conoscenza.
  /// [clearDue] toglie la scadenza ([due] null vuol dire "lasciala").
  Note copyWith({
    String? title,
    String? body,
    List<String>? tags,
    List<String>? sources,
    DateTime? created,
    DateTime? updated,
    bool? isTask,
    bool? done,
    DateTime? doneAt,
    DateTime? due,
    bool clearDue = false,
    bool? knowledge,
    bool? pinned,
  }) {
    final task = isTask ?? this.isTask;
    final isDone = task && (done ?? this.done);
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      sources: sources ?? this.sources,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      isTask: task,
      done: isDone,
      doneAt: isDone ? (doneAt ?? this.doneAt) : null,
      due: task && !clearDue ? _day(due ?? this.due) : null,
      knowledge: !task && (knowledge ?? this.knowledge),
      pinned: pinned ?? this.pinned,
      band: task ? band : null,
      rank: task ? rank : null,
      extraFrontmatter: extraFrontmatter,
    );
  }

  /// Lo stesso task in un altro posto del task manager: [band] null lo
  /// rimette fra quelli da ordinare (e allora non ha posizione).
  Note placed(TaskBand? band, String? rank) => Note(
    id: id,
    title: title,
    body: body,
    tags: tags,
    sources: sources,
    created: created,
    updated: updated,
    isTask: isTask,
    done: done,
    doneAt: doneAt,
    due: due,
    knowledge: knowledge,
    pinned: pinned,
    band: isTask ? band : null,
    rank: isTask && band != null ? rank : null,
    extraFrontmatter: extraFrontmatter,
  );

  /// Il titolo, oppure l'inizio del corpo se il titolo è vuoto; [untitled]
  /// se non c'è nemmeno quello.
  String displayTitle(String untitled) {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = plainText(body.trim().split('\n').first).trim();
    if (firstLine.isEmpty) return untitled;
    return firstLine.length > 60
        ? '${safeSubstring(firstLine, 0, 60)}…'
        : firstLine;
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('title: ${jsonEncode(title)}')
      ..writeln('tags: ${jsonEncode(tags)}')
      ..writeln('sources: ${jsonEncode(sources)}')
      ..writeln('created: ${jsonEncode(created.toIso8601String())}')
      ..writeln('updated: ${jsonEncode(updated.toIso8601String())}');
    if (isTask) {
      buffer
        ..writeln('type: "task"')
        ..writeln('done: $done');
      if (doneAt != null) {
        buffer.writeln('done_at: ${jsonEncode(doneAt!.toIso8601String())}');
      }
      if (due case final due?) {
        buffer.writeln('due: ${jsonEncode(dayKey(due))}');
      }
      if (band != null) buffer.writeln('priority: ${jsonEncode(band!.key)}');
      if (rank != null) buffer.writeln('rank: ${jsonEncode(rank)}');
    }
    if (knowledge) buffer.writeln('knowledge: true');
    if (pinned) buffer.writeln('pinned: true');
    if (extraFrontmatter.isNotEmpty) buffer.writeln(extraFrontmatter);
    buffer
      ..writeln('---')
      ..write(body);
    return buffer.toString();
  }

  /// Legge un file; tollera file scritti a mano o senza intestazione.
  static Note fromMarkdown(String id, String content, DateTime fallbackDate) {
    final text = content.replaceAll('\r\n', '\n');
    var fields = <String, Object?>{};
    var extra = '';
    var body = text;
    if (text.startsWith('---\n')) {
      // La riga di chiusura può seguire subito quella di apertura: Obsidian
      // lascia `---` e `---` quando si tolgono tutte le proprietà.
      final close = _headerClose.allMatches(text, 3).firstOrNull;
      if (close != null) {
        final end = close.start;
        final header = end > 4 ? text.substring(4, end) : '';
        (fields, extra) = _parseHeader(header);
        // La scadenza vale solo per i task: in una nota normale (es. scritta
        // a mano) resta com'è, fra le proprietà da conservare.
        if (!_isTaskType(fields['type']) && fields.containsKey('due')) {
          (fields, extra) = _parseHeader(header, ignore: const {'due'});
        }
        body = close.end < text.length ? text.substring(close.end + 1) : '';
      }
    }
    final tags = _parseList(fields['tags']);
    // `source` (singolare) è il formato delle prime versioni.
    final sources = _parseList(fields['sources'] ?? fields['source']);
    final created = _parseDate(fields['created']) ?? fallbackDate;
    final isTask = _isTaskType(fields['type']);
    final done = isTask && (fields['done'] == true || fields['done'] == 'true');
    final band = isTask ? TaskBand.fromKey(fields['priority']) : null;
    final rank = '${fields['rank'] ?? ''}'.trim();
    return Note(
      id: id,
      title: '${fields['title'] ?? ''}',
      body: body,
      tags: tags,
      sources: sources,
      created: created,
      updated: _parseDate(fields['updated']) ?? created,
      isTask: isTask,
      done: done,
      doneAt: done ? _parseDate(fields['done_at']) : null,
      due: isTask ? _day(_parseDate(fields['due'])) : null,
      knowledge: !isTask && _isTrue(fields['knowledge']),
      pinned: fields['pinned'] == true || fields['pinned'] == 'true',
      band: band,
      rank: band != null && rank.isNotEmpty ? rank : null,
      extraFrontmatter: extra,
    );
  }

  static bool _isTaskType(Object? type) =>
      '${type ?? ''}'.trim().toLowerCase() == 'task';

  /// I campi dell'intestazione che Leviathan legge e riscrive; tutti gli
  /// altri finiscono in [extraFrontmatter].
  static const _knownFields = {
    'title',
    'tags',
    'sources',
    'source',
    'created',
    'updated',
    'type',
    'done',
    'done_at',
    'due',
    'priority',
    'rank',
    'knowledge',
    'pinned',
  };

  /// La riga che chiude l'intestazione: solo `---` (al più con spazi dopo),
  /// non `----` o `---testo`.
  static final _headerClose = RegExp(r'\n---[ \t]*(?=\n|$)');

  /// Una riga che apre una voce dell'intestazione: `chiave:` a inizio riga.
  static final _entryStart = RegExp(r'^[^\s#-][^:]*:');

  /// Divide l'intestazione in campi noti e righe da conservare.
  ///
  /// Le righe rientrate o che cominciano con `-` (liste YAML, testo su più
  /// righe) appartengono alla voce sopra. Un campo noto senza valore seguito
  /// solo da righe `- …` è una lista. Le righe che non stanno sotto nessuna
  /// voce (es. commenti in cima) si conservano, come i campi in [ignore].
  static (Map<String, Object?>, String) _parseHeader(
    String header, {
    Set<String> ignore = const {},
  }) {
    final entries = <List<String>>[];
    for (final line in header.split('\n')) {
      // Un commento a inizio riga fa voce a sé: sotto un campo noto andrebbe
      // perso.
      if (entries.isEmpty ||
          _entryStart.hasMatch(line) ||
          line.startsWith('#')) {
        entries.add([line]);
      } else {
        entries.last.add(line);
      }
    }
    final fields = <String, Object?>{};
    final extra = <String>[];
    for (final [first, ...rest] in entries) {
      final colon = first.indexOf(':');
      final key = colon > 0 ? first.substring(0, colon).trim() : '';
      if (!_entryStart.hasMatch(first) ||
          !_knownFields.contains(key) ||
          ignore.contains(key)) {
        extra.addAll([first, ...rest]);
        continue;
      }
      final value = first.substring(colon + 1).trim();
      final items = [
        for (final line in rest)
          if (line.trim().isNotEmpty) line.trim(),
      ];
      final isList =
          value.isEmpty &&
          items.isNotEmpty &&
          items.every((i) => i.startsWith('-'));
      fields[key] = isList
          ? [for (final i in items) _parseValue(i.substring(1).trim())]
          : _parseValue(value);
    }
    // Righe vuote ai bordi: non servono e si accumulerebbero a ogni salvataggio.
    while (extra.isNotEmpty && extra.first.trim().isEmpty) {
      extra.removeAt(0);
    }
    while (extra.isNotEmpty && extra.last.trim().isEmpty) {
      extra.removeLast();
    }
    return (fields, extra.join('\n'));
  }

  static bool _isTrue(Object? field) => field == true || field == 'true';

  static List<String> _parseList(Object? field) {
    final items = switch (field) {
      List<dynamic> list => list.map((t) => '$t'),
      String s => s.split(','),
      _ => const <String>[],
    };
    return items.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  static Object? _parseValue(String raw) {
    if (raw.isEmpty) return '';
    try {
      return jsonDecode(raw);
    } on FormatException {
      // Valori YAML scritti a mano senza virgolette, es. tags: [a, b]
      if (raw.startsWith('[') && raw.endsWith(']')) {
        return raw
            .substring(1, raw.length - 1)
            .split(',')
            .map((t) => t.trim().replaceAll(RegExp(r'''^["']|["']$'''), ''))
            .toList();
      }
      return raw.replaceAll(RegExp(r'''^["']|["']$'''), '');
    }
  }

  /// Solo il giorno di [date], senza ora.
  static DateTime? _day(DateTime? date) =>
      date == null ? null : DateTime(date.year, date.month, date.day);

  /// Il giorno come lo si scrive nell'intestazione: "2026-10-30".
  static String dayKey(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${day.year}-${two(day.month)}-${two(day.day)}';
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
