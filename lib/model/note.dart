import 'dart:convert';

/// Una nota: titolo, corpo, tag e fonte.
///
/// Su disco è un file Markdown con un'intestazione (frontmatter) in cima:
///
/// ```
/// ---
/// title: "Titolo"
/// tags: ["tag-uno", "tag-due"]
/// source: "https://…"
/// created: "2026-10-17T14:05:12.000"
/// updated: "2026-10-17T14:05:12.000"
/// ---
/// Corpo della nota…
/// ```
///
/// I valori sono scritti come JSON, che è anche YAML valido: il file resta
/// leggibile da Obsidian e da qualsiasi editor.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.source,
    required this.created,
    required this.updated,
  });

  /// Nome del file senza estensione; non cambia se si modifica il titolo.
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final String source;
  final DateTime created;
  final DateTime updated;

  Note copyWith({
    String? title,
    String? body,
    List<String>? tags,
    String? source,
    DateTime? updated,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        source: source ?? this.source,
        created: created,
        updated: updated ?? this.updated,
      );

  /// Il titolo, oppure l'inizio del corpo se il titolo è vuoto.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = body.trim().split('\n').first.trim();
    if (firstLine.isEmpty) return 'Senza titolo';
    return firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine;
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('title: ${jsonEncode(title)}')
      ..writeln('tags: ${jsonEncode(tags)}')
      ..writeln('source: ${jsonEncode(source)}')
      ..writeln('created: ${jsonEncode(created.toIso8601String())}')
      ..writeln('updated: ${jsonEncode(updated.toIso8601String())}')
      ..writeln('---')
      ..write(body);
    return buffer.toString();
  }

  /// Legge un file; tollera file scritti a mano o senza intestazione.
  static Note fromMarkdown(String id, String content, DateTime fallbackDate) {
    final text = content.replaceAll('\r\n', '\n');
    final fields = <String, Object?>{};
    var body = text;
    if (text.startsWith('---\n')) {
      final end = text.indexOf('\n---', 4);
      if (end != -1) {
        for (final line in text.substring(4, end).split('\n')) {
          final colon = line.indexOf(':');
          if (colon <= 0) continue;
          fields[line.substring(0, colon).trim()] =
              _parseValue(line.substring(colon + 1).trim());
        }
        final afterHeader = text.indexOf('\n', end + 1);
        body = afterHeader == -1 ? '' : text.substring(afterHeader + 1);
      }
    }
    final tagsField = fields['tags'];
    final tags = switch (tagsField) {
      List<dynamic> list => list.map((t) => '$t').toList(),
      String s when s.isNotEmpty => s.split(',').map((t) => t.trim()).toList(),
      _ => <String>[],
    };
    final created = _parseDate(fields['created']) ?? fallbackDate;
    return Note(
      id: id,
      title: '${fields['title'] ?? ''}',
      body: body,
      tags: tags.where((t) => t.isNotEmpty).toList(),
      source: '${fields['source'] ?? ''}',
      created: created,
      updated: _parseDate(fields['updated']) ?? created,
    );
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

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
