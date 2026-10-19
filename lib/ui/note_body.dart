import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../l10n/l10n.dart';
import '../model/markdown.dart';
import '../model/note.dart';
import '../model/note_links.dart';
import 'theme.dart';

/// Il corpo di una nota formattato come Markdown.
///
/// Un a capo resta un a capo (come lo si scrive sul telefono). Le caselle
/// delle checklist si spuntano toccandole se c'è [onChanged], che riceve il
/// testo aggiornato.
///
/// I collegamenti ad altre note (`[[id|testo]]`, vedi [noteLinkPattern]) si
/// cercano fra [notes] e toccandoli si apre la nota con [onOpenNote]; uno
/// che non porta a nessuna nota (eliminata, o scritto male) è barrato.
class NoteBody extends StatelessWidget {
  const NoteBody(
    this.body, {
    super.key,
    this.onChanged,
    this.notes = const [],
    this.onOpenNote,
  });

  final String body;
  final ValueChanged<String>? onChanged;
  final List<Note> notes;
  final ValueChanged<Note>? onOpenNote;

  @override
  Widget build(BuildContext context) {
    // Il pacchetto non dice quale casella sta disegnando: le costruisce in
    // ordine di testo, quindi le si numera contando. Il modulo protegge da
    // una seconda costruzione con lo stesso widget. Se le caselle disegnate
    // non sono quelle trovate nel testo (una sintassi che [checkboxOffsets]
    // non conosce), il conto sbaglierebbe: restano in sola lettura.
    final total = checkboxOffsets(body).length;
    final tappable = onChanged != null && total == renderedCheckboxCount(body);
    var next = 0;
    return MarkdownBody(
      data: body,
      softLineBreak: true,
      // Citazioni e blocchi di codice a tutta larghezza.
      fitContent: false,
      styleSheet: markdownStyle(context),
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      inlineSyntaxes: [_NoteLinkSyntax()],
      builders: {
        _NoteLinkSyntax.tag: _NoteLinkBuilder(
          notes: notes,
          onOpenNote: onOpenNote,
        ),
      },
      checkboxBuilder: (checked) {
        final index = total == 0 ? 0 : next++ % total;
        return _Checkbox(
          checked: checked,
          onTap: tappable
              ? () => onChanged!(toggleCheckbox(body, index))
              : null,
        );
      },
    );
  }
}

/// Riconosce `[[id|testo]]` prima dei link Markdown, che leggerebbero le
/// quadre a modo loro.
class _NoteLinkSyntax extends md.InlineSyntax {
  _NoteLinkSyntax() : super(noteLinkPattern.pattern);

  static const tag = 'note-link';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.text(tag, linkLabel(match[1]!, match[2]))
        ..attributes['target'] = match[1]!.trim(),
    );
    return true;
  }
}

/// Disegna un collegamento come testo nel colore dell'accento con la
/// freccia davanti, dentro la riga: si distingue dal resto e dai link web.
class _NoteLinkBuilder extends MarkdownElementBuilder {
  _NoteLinkBuilder({required this.notes, required this.onOpenNote});

  final List<Note> notes;
  final ValueChanged<Note>? onOpenNote;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final palette = context.palette;
    final target = resolveNoteLink(notes, element.attributes['target'] ?? '');
    final base = parentStyle ?? LeviathanText.reading;
    final style = target == null
        ? base.copyWith(
            color: palette.muted,
            decoration: TextDecoration.lineThrough,
          )
        : base.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: palette.accent.withValues(
              alpha: LeviathanOpacity.selection,
            ),
          );
    final recognizer = TapGestureRecognizer()
      ..onTap = target == null
          ? () => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(context.l10n.linkedNoteMissing)),
            )
          : () => onOpenNote?.call(target);
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: LeviathanSpacing.xxs),
              child: Icon(
                Icons.subdirectory_arrow_right,
                size: LeviathanIconSize.sm,
                color: style.color,
              ),
            ),
          ),
          TextSpan(
            text: element.textContent,
            style: style,
            recognizer: recognizer,
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      size: LeviathanIconSize.lg,
      color: checked ? context.palette.muted : context.palette.accent,
    );
    return Align(
      alignment: Alignment.topLeft,
      child: onTap == null
          ? icon
          : Semantics(
              button: true,
              checked: checked,
              child: InkResponse(
                onTap: onTap,
                radius: LeviathanIconSize.lg,
                child: icon,
              ),
            ),
    );
  }
}

/// Lo stile del Markdown nella lettura delle note, con i colori della
/// palette.
MarkdownStyleSheet markdownStyle(BuildContext context) {
  final theme = Theme.of(context);
  final palette = context.palette;
  final body = LeviathanText.reading.copyWith(color: palette.text);
  final code = body.copyWith(
    fontFamily: 'monospace',
    fontSize: LeviathanText.body.fontSize,
    backgroundColor: palette.surface,
  );
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: body,
    listBullet: body,
    a: body.copyWith(color: palette.accent),
    code: code,
    codeblockDecoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(LeviathanRadii.md),
    ),
    codeblockPadding: const EdgeInsets.all(LeviathanSpacing.md),
    blockquote: body.copyWith(color: palette.muted),
    blockquoteDecoration: BoxDecoration(
      color: palette.surface,
      border: Border(
        left: BorderSide(color: palette.link, width: LeviathanSizes.tagBar),
      ),
    ),
    blockquotePadding: const EdgeInsets.symmetric(
      horizontal: LeviathanSpacing.md,
      vertical: LeviathanSpacing.sm,
    ),
    h1: LeviathanText.heading.copyWith(color: palette.text),
    h2: LeviathanText.editorTitle.copyWith(color: palette.text),
    h3: LeviathanText.title.copyWith(color: palette.text),
    strong: const TextStyle(fontWeight: FontWeight.w700),
    h1Padding: const EdgeInsets.only(top: LeviathanSpacing.sm),
    h2Padding: const EdgeInsets.only(top: LeviathanSpacing.sm),
    listIndent: LeviathanSpacing.xxl,
    blockSpacing: LeviathanSpacing.md,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: palette.outline)),
    ),
  );
}
