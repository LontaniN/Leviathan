import 'package:flutter/material.dart';

import '../state/settings.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Impostazioni dell'app. Per ora solo la scelta della palette.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: context.palette.background,
          title: const Text('Impostazioni'),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
          children: [
            const SectionTitle('Palette'),
            for (final palette in LeviathanPalette.all)
              _PaletteTile(
                palette: palette,
                selected: palette == settings.palette,
                onTap: () => settings.setPalette(palette),
              ),
          ],
        ),
      ),
    );
  }
}

/// Una palette con un'anteprima in miniatura dei suoi colori.
class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final LeviathanPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LeviathanSpacing.lg,
        vertical: LeviathanSpacing.xs,
      ),
      child: Material(
        color: current.surface,
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
        child: InkWell(
          key: Key('palette-${palette.id}'),
          borderRadius: BorderRadius.circular(LeviathanRadii.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(LeviathanSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LeviathanRadii.md),
              border: Border.all(
                color: selected ? current.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                _Preview(palette),
                const SizedBox(width: LeviathanSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(palette.name, style: LeviathanText.title),
                      const SizedBox(height: LeviathanSpacing.xxs),
                      Text(
                        palette.brightness == Brightness.dark
                            ? 'Scura'
                            : 'Chiara',
                        style: LeviathanText.meta.copyWith(
                          color: current.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: current.accent)
                else
                  Icon(Icons.circle_outlined, color: current.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura della home: fondo, un pannello, il pulsante d'accento e i
/// collegamenti del grafo.
class _Preview extends StatelessWidget {
  const _Preview(this.palette);

  final LeviathanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 64,
      padding: const EdgeInsets.all(LeviathanSpacing.sm),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(LeviathanSpacing.sm),
        border: Border.all(color: palette.muted.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // La colonna delle note.
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final color in [palette.accent, palette.link, palette.muted])
                Container(width: 3, height: 10, color: color),
            ],
          ),
          const SizedBox(width: LeviathanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(LeviathanSpacing.xs),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(LeviathanSpacing.xs),
                    ),
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 28,
                      height: 3,
                      color: palette.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: LeviathanSpacing.xs),
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(LeviathanSpacing.sm),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
