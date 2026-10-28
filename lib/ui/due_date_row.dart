import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/dates.dart';
import 'theme.dart';

/// La riga della scadenza di un task, sotto il titolo: toccandola si sceglie
/// il giorno dal calendario, la croce la toglie.
class DueDateRow extends StatelessWidget {
  const DueDateRow({super.key, required this.due, required this.onChanged});

  /// Il giorno di scadenza; null se non c'è.
  final DateTime? due;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shown = due ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: shown,
      // Una scadenza già passata resta sceglibile, per spostarla.
      firstDate: shown.isBefore(today) ? shown : today,
      lastDate: DateTime(today.year + 50),
      helpText: context.l10n.dueDateTitle,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    final due = this.due;
    return InkWell(
      key: const Key('due-date-row'),
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LeviathanSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: LeviathanIconSize.sm,
              color: due == null ? palette.muted : palette.accent,
            ),
            const SizedBox(width: LeviathanSpacing.sm),
            Expanded(
              child: Text(
                due == null ? l.dueDateAdd : l.dueOn(formatDate(l, due)),
                style: LeviathanText.body.copyWith(
                  color: due == null ? palette.muted : palette.text,
                ),
              ),
            ),
            if (due != null)
              IconButton(
                key: const Key('due-date-clear'),
                tooltip: l.dueDateClear,
                icon: const Icon(Icons.close, size: LeviathanIconSize.sm),
                color: palette.muted,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onChanged(null),
              ),
          ],
        ),
      ),
    );
  }
}
