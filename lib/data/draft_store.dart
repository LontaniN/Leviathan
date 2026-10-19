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

  /// Il prossimo passo, se è un task.
  String nextStep,

  /// Il giorno a cui si riferisce la nota, se non è oggi.
  DateTime? date,
});

/// La modifica di una nota già salvata rimasta a metà: la nota, il testo e
/// dove era il cursore nel corpo.
typedef EditDraft = ({String noteId, Draft draft, int cursor});

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
      return _decode(jsonDecode(file.readAsStringSync()) as Map);
    } on Object {
      return null;
    }
  }

  void write(Draft draft) {
    if (isEmpty(draft)) {
      clear();
      return;
    }
    writeFileAtomic(file, jsonEncode(_encode(draft)));
  }

  void clear() {
    if (file.existsSync()) file.deleteSync();
  }

  /// Niente da tenere: né testo né tag né fonti. Una data da sola non basta.
  static bool isEmpty(Draft draft) =>
      draft.title.trim().isEmpty &&
      draft.body.trim().isEmpty &&
      draft.tags.isEmpty &&
      draft.sources.isEmpty &&
      draft.nextStep.trim().isEmpty;
}

/// Tiene da parte la modifica di una nota già salvata, finché non la si
/// salva o si esce dalla pagina: se Android chiude l'app nel frattempo, la
/// home propone di riprenderla dal punto in cui si era.
///
/// File: `.leviathan/edit-drafts/<workspace>.json`, una sola modifica per
/// workspace (se ne apre una alla volta).
class EditDraftStore {
  EditDraftStore(this.file);

  final File file;

  EditDraft? read() {
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map;
      final id = json['note'];
      if (id is! String || id.isEmpty) return null;
      final cursor = json['cursor'];
      return (
        noteId: id,
        draft: _decode(json),
        cursor: cursor is int ? cursor : 0,
      );
    } on Object {
      return null;
    }
  }

  void write(String noteId, Draft draft, int cursor) {
    writeFileAtomic(
      file,
      jsonEncode({'note': noteId, 'cursor': cursor, ..._encode(draft)}),
    );
  }

  void clear() {
    if (file.existsSync()) file.deleteSync();
  }
}

Map<String, Object?> _encode(Draft draft) => {
  'title': draft.title,
  'body': draft.body,
  'tags': draft.tags,
  'sources': draft.sources,
  'task': draft.isTask,
  'knowledge': draft.knowledge,
  if (draft.nextStep.isNotEmpty) 'nextStep': draft.nextStep,
  if (draft.date case final date?) 'date': date.toIso8601String(),
};

Draft _decode(Map<dynamic, dynamic> json) {
  List<String> list(Object? v) => [if (v is List) ...v.map((e) => '$e')];
  return (
    title: '${json['title'] ?? ''}',
    body: '${json['body'] ?? ''}',
    tags: list(json['tags']),
    sources: list(json['sources']),
    isTask: json['task'] == true,
    knowledge: json['knowledge'] == true,
    nextStep: '${json['nextStep'] ?? ''}',
    date: DateTime.tryParse('${json['date'] ?? ''}'),
  );
}
