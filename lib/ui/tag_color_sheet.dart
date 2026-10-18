import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'theme.dart';

/// Il foglio per scegliere il colore di [tag], aperto tenendo premuto il
/// tag. Il colore vale per tutto il workspace.
Future<void> showTagColorSheet(
  BuildContext context,
  NotesController notes,
  String tag,
) {
  final l = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final palette = sheetContext.palette;
      final current = Tags.colorOf(tag);
      final custom = Tags.custom.containsKey(tag);
      void pick(Color? color) {
        Navigator.pop(sheetContext);
        notes.setTagColor(tag, color);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LeviathanSpacing.xl,
            0,
            LeviathanSpacing.xl,
            LeviathanSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.tagColorTitle(tag), style: LeviathanText.title),
              const SizedBox(height: LeviathanSpacing.lg),
              Wrap(
                spacing: LeviathanSpacing.md,
                runSpacing: LeviathanSpacing.md,
                children: [
                  for (final color in Tags.palette)
                    InkResponse(
                      key: Key('tag-color-${color.toARGB32()}'),
                      onTap: () => pick(color),
                      radius: LeviathanSizes.tagSwatch / 2,
                      child: Container(
                        width: LeviathanSizes.tagSwatch,
                        height: LeviathanSizes.tagSwatch,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: color == current
                              ? Border.all(
                                  color: palette.text,
                                  width: LeviathanSizes.selectedOutline,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              if (custom) ...[
                const SizedBox(height: LeviathanSpacing.md),
                ListTile(
                  key: const Key('tag-color-auto'),
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Tags.autoColorOf(tag),
                    radius: LeviathanSizes.tagDot,
                  ),
                  title: Text(l.tagColorAuto),
                  onTap: () => pick(null),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
