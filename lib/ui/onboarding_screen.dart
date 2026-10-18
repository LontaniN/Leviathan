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
            padding: const EdgeInsets.all(LeviathanSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LeviathanSizes.formWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Leviathan',
                    style: LeviathanText.display.copyWith(
                      color: context.palette.accent,
                    ),
                  ),
                  const SizedBox(height: LeviathanSpacing.xs),
                  Text(
                    'Il tuo secondo cervello.',
                    style: LeviathanText.editorTitle.copyWith(
                      color: context.palette.text,
                    ),
                  ),
                  const SizedBox(height: LeviathanSpacing.lg),
                  Text(
                    'Dai un nome al tuo primo workspace. '
                    'Ogni workspace raccoglie le sue note: '
                    'puoi crearne altri in qualsiasi momento.',
                    style: text.bodyLarge?.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                  const SizedBox(height: LeviathanSpacing.xxl),
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
