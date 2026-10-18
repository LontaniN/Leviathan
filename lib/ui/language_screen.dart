import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/settings.dart';
import 'theme.dart';

/// Primo avvio: si sceglie la lingua da un menu a tendina.
///
/// Parte dalla lingua del telefono, se l'app la conosce. La schermata si
/// riscrive subito nella lingua scelta, così si vede cosa si sta scegliendo;
/// la scelta si salva solo con "Continua".
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.settings});

  final Settings settings;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _language = deviceLanguage();

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: Locale(_language),
      child: Builder(
        builder: (context) {
          final l = context.l10n;
          final text = Theme.of(context).textTheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(LeviathanSpacing.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: LeviathanSizes.formWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.translate,
                          size: LeviathanIconSize.xl,
                          color: context.palette.accent,
                        ),
                        const SizedBox(height: LeviathanSpacing.xl),
                        Text(l.languageTitle, style: text.headlineSmall),
                        const SizedBox(height: LeviathanSpacing.sm),
                        Text(
                          l.languageBody,
                          style: text.bodyLarge?.copyWith(
                            color: context.palette.muted,
                          ),
                        ),
                        const SizedBox(height: LeviathanSpacing.xxl),
                        LanguageMenu(
                          key: const Key('language-menu'),
                          value: _language,
                          onChanged: (code) => setState(() => _language = code),
                        ),
                        const SizedBox(height: LeviathanSpacing.xl),
                        FilledButton(
                          key: const Key('language-continue'),
                          onPressed: () =>
                              widget.settings.setLanguage(_language),
                          child: Text(l.continueButton),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Il menu a tendina delle lingue, ognuna scritta nella lingua stessa.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: context.l10n.language,
        prefixIcon: const Icon(Icons.language, size: LeviathanIconSize.md),
      ),
      borderRadius: BorderRadius.circular(LeviathanRadii.md),
      dropdownColor: context.palette.surface,
      items: [
        for (final MapEntry(key: code, value: name) in appLanguages.entries)
          DropdownMenuItem(value: code, child: Text(name)),
      ],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}
