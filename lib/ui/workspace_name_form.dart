import 'package:flutter/material.dart';

import '../data/workspace_repository.dart';
import '../l10n/l10n.dart';
import 'theme.dart';

/// Campo + pulsante per dare un nome a un workspace, nuovo o da rinominare.
///
/// [validate] restituisce l'errore o null; [onSubmit] riceve il nome già
/// controllato e può lanciare [ArgumentError] con un [WorkspaceNameError] o
/// un messaggio. [initialName] precompila il campo, tutto selezionato. Senza
/// [buttonLabel] il pulsante dice "Crea".
class WorkspaceNameForm extends StatefulWidget {
  const WorkspaceNameForm({
    super.key,
    required this.validate,
    required this.onSubmit,
    this.buttonLabel,
    this.initialName = '',
  });

  final WorkspaceNameError? Function(String name) validate;
  final Future<void> Function(String name) onSubmit;
  final String? buttonLabel;
  final String initialName;

  @override
  State<WorkspaceNameForm> createState() => _WorkspaceNameFormState();
}

class _WorkspaceNameFormState extends State<WorkspaceNameForm> {
  late final _controller = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    final error = widget.validate(name);
    setState(() => _error = error == null ? null : _message(error));
    if (error != null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(name);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      final message = e.message;
      setState(
        () => _error = message is WorkspaceNameError
            ? _message(message)
            : '$message',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(WorkspaceNameError error) {
    final l = context.l10n;
    return switch (error) {
      WorkspaceNameError.empty => l.workspaceNameEmpty,
      WorkspaceNameError.tooLong => l.workspaceNameTooLong(
        WorkspaceRepository.maxNameLength,
      ),
      WorkspaceNameError.leadingDot => l.workspaceNameLeadingDot,
      WorkspaceNameError.trailingDot => l.workspaceNameTrailingDot,
      WorkspaceNameError.invalidChars => l.workspaceNameInvalidChars(
        WorkspaceRepository.invalidChars,
      ),
      WorkspaceNameError.taken => l.workspaceNameTaken,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: context.l10n.workspaceNameHint,
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: LeviathanSpacing.lg),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(widget.buttonLabel ?? context.l10n.create),
        ),
      ],
    );
  }
}
