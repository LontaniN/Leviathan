import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/dates.dart';
import '../model/note.dart';
import '../model/search.dart';
import '../state/notes_controller.dart';
import 'tag_bar.dart';
import 'task_check.dart';
import 'theme.dart';

/// Apre la scelta della nota da collegare; restituisce quella toccata, null
/// se si torna indietro. [exclude] è la nota che si sta scrivendo, che non
/// si collega a sé stessa.
Future<Note?> pickNote(
  BuildContext context,
  NotesController notes, {
  String? exclude,
}) => Navigator.of(context).push<Note>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => NotePickerScreen(notes: notes, exclude: exclude),
  ),
);

/// Cerca la nota da collegare: senza testo propone quelle aperte di recente
/// e poi le più nuove; scrivendo, la ricerca su titolo, corpo, tag e fonti.
class NotePickerScreen extends StatefulWidget {
  const NotePickerScreen({super.key, required this.notes, this.exclude});

  final NotesController notes;
  final String? exclude;

  @override
  State<NotePickerScreen> createState() => _NotePickerScreenState();
}

class _NotePickerScreenState extends State<NotePickerScreen> {
  final _query = TextEditingController();

  /// Quante note proporre senza testo.
  static const _suggested = 30;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Note> _candidates() {
    final notes = widget.notes;
    bool allowed(Note n) => n.id != widget.exclude;
    final query = SearchQuery(text: _query.text);
    if (!query.isEmpty) {
      return [
        for (final hit in searchNotes(notes.notes, query))
          if (allowed(hit.note)) hit.note,
      ];
    }
    final recent = notes.recentlyOpened(limit: _suggested);
    final ids = {for (final n in recent) n.id};
    return [
      ...recent.where(allowed),
      ...notes.notes.where((n) => allowed(n) && !ids.contains(n.id)),
    ].take(_suggested).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final candidates = _candidates();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.background,
        title: TextField(
          key: const Key('note-picker-field'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.pickNoteHint,
            filled: false,
            border: InputBorder.none,
          ),
        ),
      ),
      body: candidates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(LeviathanSpacing.xxl),
                child: Text(
                  widget.notes.notes.length > 1 || widget.exclude == null
                      ? l.noNotesFound
                      : l.noNotesToLink,
                  textAlign: TextAlign.center,
                  style: LeviathanText.body.copyWith(color: palette.muted),
                ),
              ),
            )
          : ListView.builder(
              key: const Key('note-picker-list'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: candidates.length,
              itemBuilder: (context, i) {
                final note = candidates[i];
                return ListTile(
                  key: Key('pick-${note.id}'),
                  leading: TagBar(
                    note: note,
                    height: LeviathanSizes.tagBarCompact,
                  ),
                  minLeadingWidth: 0,
                  title: Text(
                    note.displayTitle(l.untitled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: taskTitleStyle(
                      context,
                      note,
                      LeviathanText.title.copyWith(color: palette.text),
                    ),
                  ),
                  subtitle: Text(
                    formatDate(l, note.created),
                    style: LeviathanText.meta.copyWith(color: palette.muted),
                  ),
                  onTap: () => Navigator.pop(context, note),
                );
              },
            ),
    );
  }
}
