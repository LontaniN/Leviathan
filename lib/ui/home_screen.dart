import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'theme.dart';
import 'workspace_name_form.dart';

/// Schermata principale di un workspace.
///
/// Per ora contiene solo la barra con il nome del workspace; lista note,
/// editor, tag e fonte arrivano nei prossimi passi.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: _WorkspaceButton(state: state),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Qui arriveranno lista note ed editor',
                  style: TextStyle(color: LeviathanColors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il nome del workspace in alto, in piccolo: toccandolo si cambia workspace.
class _WorkspaceButton extends StatelessWidget {
  const _WorkspaceButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('workspace-button'),
      onPressed: () => showWorkspaceSwitcher(context, state),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.expand_more, size: 18),
      label: Text(
        state.currentWorkspace ?? '',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(foregroundColor: LeviathanColors.accent),
    );
  }
}

Future<void> showWorkspaceSwitcher(BuildContext context, AppState state) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: LeviathanColors.surface,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Workspace',
                  style: TextStyle(color: LeviathanColors.muted)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final name in state.workspaces)
                    ListTile(
                      title: Text(name),
                      trailing: name == state.currentWorkspace
                          ? const Icon(Icons.check,
                              color: LeviathanColors.accent)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        state.switchTo(name);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nuovo workspace'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showNewWorkspaceDialog(context, state);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showNewWorkspaceDialog(BuildContext context, AppState state) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nuovo workspace'),
      content: SizedBox(
        width: 360,
        child: WorkspaceNameForm(
          validate: state.validateNewName,
          onSubmit: (name) async {
            await state.createWorkspace(name);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    ),
  );
}
