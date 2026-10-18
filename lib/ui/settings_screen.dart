import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/tags.dart';
import '../state/settings.dart';
import 'language_screen.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Impostazioni dell'app: la lingua dell'interfaccia e la palette.
///
/// Le palette sono schede a due colonne, ognuna con una miniatura della home
/// nei suoi colori. La griglia non è pigra: sono poche e così si costruiscono
/// tutte insieme.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final Settings settings;

  static const _columns = 2;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.settings)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(context.l10n.language),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LeviathanSpacing.md,
                  LeviathanSpacing.xs,
                  LeviathanSpacing.md,
                  LeviathanSpacing.lg,
                ),
                child: LanguageMenu(
                  key: const Key('settings-language'),
                  value: settings.language ?? deviceLanguage(),
                  onChanged: settings.setLanguage,
                ),
              ),
              SectionTitle(context.l10n.palette),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LeviathanSpacing.md,
                ),
                child: GridView.count(
                  crossAxisCount: _columns,
                  childAspectRatio: LeviathanSizes.paletteTileAspect,
                  mainAxisSpacing: LeviathanSpacing.md,
                  crossAxisSpacing: LeviathanSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final palette in LeviathanPalette.all)
                      _PaletteTile(
                        palette: palette,
                        selected: palette == settings.palette,
                        onTap: () => settings.setPalette(palette),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il nome di una palette nella lingua dell'interfaccia.
String paletteName(AppLocalizations l, LeviathanPalette palette) =>
    switch (palette.id) {
      'seppia' => l.paletteSeppia,
      'lavagna' => l.paletteLavagna,
      'grafite' => l.paletteGrafite,
      'abisso' => l.paletteAbisso,
      'brace' => l.paletteBrace,
      'muschio' => l.paletteMuschio,
      'ametista' => l.paletteAmetista,
      'carta' => l.paletteCarta,
      _ => l.paletteInchiostro,
    };

/// Una palette: la miniatura e sotto nome e tipo.
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
    final radius = BorderRadius.circular(LeviathanRadii.lg);
    return Material(
      color: current.surface,
      borderRadius: radius,
      child: InkWell(
        key: Key('palette-${palette.id}'),
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: LeviathanDurations.quick,
          padding: const EdgeInsets.all(LeviathanSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? current.accent : current.outline,
              width: selected
                  ? LeviathanSizes.selectedOutline
                  : LeviathanSizes.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Preview(palette)),
              const SizedBox(height: LeviathanSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LeviathanSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paletteName(context.l10n, palette),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LeviathanText.title,
                          ),
                          Text(
                            palette.brightness == Brightness.dark
                                ? context.l10n.dark
                                : context.l10n.light,
                            style: LeviathanText.meta.copyWith(
                              color: current.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: LeviathanIconSize.md,
                      color: selected ? current.accent : current.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniatura della home: intestazione, barra di ricerca, la colonna delle
/// note con le barrette dei tag e l'editor con il pulsante d'accento.
class _Preview extends StatelessWidget {
  const _Preview(this.palette);

  final LeviathanPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget line(double widthFactor, Color color) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: LeviathanSpacing.xs,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(LeviathanRadii.sm),
        ),
      ),
    );
    final tagColors = [
      Tags.palette[0],
      Tags.palette[3],
      Tags.palette[1],
      palette.muted,
    ];
    return Container(
      padding: const EdgeInsets.all(LeviathanSpacing.sm),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(0.45, palette.text),
          const SizedBox(height: LeviathanSpacing.sm),
          // La barra di ricerca.
          Container(
            height: LeviathanSpacing.md,
            decoration: ShapeDecoration(
              color: palette.surface,
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: LeviathanSpacing.sm),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // La colonna delle note.
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final color in tagColors)
                        Row(
                          children: [
                            Container(
                              width: LeviathanSizes.tagBar,
                              height: LeviathanSpacing.md,
                              color: color,
                            ),
                            const SizedBox(width: LeviathanSpacing.xs),
                            Expanded(child: line(0.8, palette.muted)),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: LeviathanSpacing.sm),
                // L'editor.
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(LeviathanSpacing.xs),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(
                              LeviathanRadii.cell,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              line(0.6, palette.text),
                              const SizedBox(height: LeviathanSpacing.xs),
                              line(0.9, palette.muted),
                              const SizedBox(height: LeviathanSpacing.xxs),
                              line(0.7, palette.muted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: LeviathanSpacing.xs),
                      Container(
                        height: LeviathanSpacing.md,
                        decoration: ShapeDecoration(
                          color: palette.accent,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
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
