import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'state/app_state.dart';
import 'state/settings.dart';
import 'state/share_inbox.dart';
import 'ui/home_screen.dart';
import 'ui/language_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/permission_screen.dart';
import 'ui/theme.dart';

class LeviathanApp extends StatefulWidget {
  LeviathanApp({
    super.key,
    required this.state,
    Settings? settings,
    ShareInbox? shares,
  }) : settings = settings ?? Settings(),
       shares = shares ?? ShareInbox();

  final AppState state;
  final Settings settings;

  /// Il testo condiviso da altre app, che la home mette nella bozza.
  final ShareInbox shares;

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
        final app = MaterialApp(
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
        return SettingsScope(settings: widget.settings, child: app);
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
            // Entrando la prima volta nel primo workspace creato parte il
            // tour guidato, se non è già stato fatto.
            AppStatus.ready => HomeScreen(
              key: ValueKey(state.currentWorkspace),
              state: state,
              settings: widget.settings,
              shares: widget.shares,
              startTour:
                  state.firstWorkspaceCreated && !widget.settings.tourSeen,
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
