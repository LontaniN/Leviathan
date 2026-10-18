import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'state/app_state.dart';
import 'state/settings.dart';
import 'ui/home_screen.dart';
import 'ui/language_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/permission_screen.dart';
import 'ui/theme.dart';

class LeviathanApp extends StatefulWidget {
  LeviathanApp({super.key, required this.state, Settings? settings})
    : settings = settings ?? Settings();

  final AppState state;
  final Settings settings;

  @override
  State<LeviathanApp> createState() => _LeviathanAppState();
}

class _LeviathanAppState extends State<LeviathanApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Tornando dalle impostazioni di Android il permesso può essere cambiato.
    if (lifecycle == AppLifecycleState.resumed) {
      widget.state.recheckPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, home) {
        final language = widget.settings.language;
        return MaterialApp(
          title: 'Leviathan',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(widget.settings.palette),
          locale: Locale(language ?? deviceLanguage()),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Al primo avvio, prima di tutto, si sceglie la lingua.
          home: language == null
              ? LanguageScreen(settings: widget.settings)
              : home,
        );
      },
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final state = widget.state;
          return switch (state.status) {
            AppStatus.loading => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            AppStatus.needsPermission => PermissionScreen(state: state),
            AppStatus.onboarding => OnboardingScreen(state: state),
            // La chiave ricrea la schermata (e le sue note) a ogni cambio.
            AppStatus.ready => HomeScreen(
              key: ValueKey(state.currentWorkspace),
              state: state,
              settings: widget.settings,
            ),
            AppStatus.error => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(LeviathanSpacing.xxl),
                  child: Text(
                    context.l10n.errorMessage('${state.errorMessage}'),
                  ),
                ),
              ),
            ),
          };
        },
      ),
    );
  }
}
