import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import 'theme.dart';

/// Spiega perché serve l'accesso ai file e porta alle impostazioni.
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LeviathanSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.folder_open,
                size: LeviathanIconSize.xl,
                color: context.palette.accent,
              ),
              const SizedBox(height: LeviathanSpacing.xl),
              Text(
                l.permissionTitle,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LeviathanSpacing.md),
              Text(
                l.permissionBody,
                style: text.bodyLarge?.copyWith(color: context.palette.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LeviathanSpacing.xxl),
              FilledButton(
                onPressed: state.requestPermission,
                child: Text(l.permissionGrant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
