import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'theme.dart';
import 'workspace_name_form.dart';

/// Primo avvio: si dà il nome al primo workspace.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Leviathan',
                      style: text.displaySmall
                          ?.copyWith(color: LeviathanColors.accent)),
                  const SizedBox(height: 8),
                  Text(
                    'Dai un nome al tuo primo workspace. '
                    'Ogni workspace raccoglie le sue note: '
                    'puoi crearne altri in qualsiasi momento.',
                    style:
                        text.bodyLarge?.copyWith(color: LeviathanColors.muted),
                  ),
                  const SizedBox(height: 32),
                  WorkspaceNameForm(
                    validate: state.validateNewName,
                    onSubmit: state.createWorkspace,
                    buttonLabel: 'Crea workspace',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
