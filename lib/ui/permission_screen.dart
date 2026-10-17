import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'theme.dart';

/// Spiega perché serve l'accesso ai file e porta alle impostazioni.
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.folder_open, size: 48, color: context.palette.accent),
              const SizedBox(height: 24),
              Text(
                'Accesso ai file',
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Le note vengono salvate come file nella cartella '
                'Documents/LeviathanNotes del telefono, così restano tue '
                'anche se disinstalli l\'app. Per scriverci, Android chiede '
                'il permesso "Accesso a tutti i file".',
                style: text.bodyLarge?.copyWith(color: context.palette.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: state.requestPermission,
                child: const Text('Concedi accesso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
