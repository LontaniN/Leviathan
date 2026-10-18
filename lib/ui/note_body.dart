import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../model/markdown.dart';
import 'theme.dart';

/// Il corpo di una nota formattato come Markdown.
///
/// Un a capo resta un a capo (come lo si scrive sul telefono). Le caselle
/// delle checklist si spuntano toccandole se c'è [onChanged], che riceve il
/// testo aggiornato.
class NoteBody extends StatelessWidget {
  const NoteBody(this.body, {super.key, this.onChanged});

  final String body;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Il pacchetto non dice quale casella sta disegnando: le costruisce in
    // ordine di testo, quindi le si numera contando. Il modulo protegge da
    // una seconda costruzione con lo stesso widget.
    final total = checkboxOffsets(body).length;
    var next = 0;
    return MarkdownBody(
      data: body,
      softLineBreak: true,
      // Citazioni e blocchi di codice a tutta larghezza.
      fitContent: false,
      styleSheet: markdownStyle(context),
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      checkboxBuilder: (checked) {
        final index = total == 0 ? 0 : next++ % total;
        return _Checkbox(
          checked: checked,
          onTap: onChanged == null
              ? null
              : () => onChanged!(toggleCheckbox(body, index)),
        );
      },
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
