import 'dart:convert';
import 'dart:io';

import 'atomic_write.dart';

/// La nota che si sta scrivendo nella home e non è ancora salvata.
typedef Draft = ({
  String title,
  String body,
  List<String> tags,
  List<String> sources,
  bool isTask,
  bool knowledge,

  /// Il giorno a cui si riferisce la nota, se non è oggi.
  DateTime? date,
});

/// Tiene da parte la bozza della home: se Android chiude l'app mentre si
/// scrive, riaprendola il testo è ancora lì.
///
/// File: `.leviathan/drafts/<workspace>.json`. Una bozza vuota cancella il
/// file.
class DraftStore {
  DraftStore(this.file);

  final File file;

  Draft? read() {
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      List<String> list(Object? v) => [if (v is List) ...v.map((e) => '$e')];
      return (
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        tags: list(json['tags']),
        sources: list(json['sources']),
        isTask: json['task'] == true,
        knowledge: json['knowledge'] == true,
        date: DateTime.tryParse('${json['date'] ?? ''}'),
      );
    } on Object {
      return null;
    }
  }

  void write(Draft draft) {
    if (isEmpty(draft)) {
      clear();
      return;
    }
    writeFileAtomic(
      file,
      jsonEncode({
        'title': draft.title,
        'body': draft.body,
        'tags': draft.tags,
        'sources': draft.sources,
        'task': draft.isTask,
        'knowledge': draft.knowledge,
        if (draft.date case final date?) 'date': date.toIso8601String(),
      }),
    );
  }

  void clear() {
    if (file.existsSync()) file.deleteSync();
  }

  /// Niente da tenere: né testo né tag né fonti. Una data da sola non basta.
  static bool isEmpty(Draft draft) =>
      draft.title.trim().isEmpty &&
      draft.body.trim().isEmpty &&
      draft.tags.isEmpty &&
      draft.sources.isEmpty;
}
