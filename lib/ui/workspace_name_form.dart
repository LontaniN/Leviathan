import 'package:flutter/material.dart';

/// Campo + pulsante per dare un nome a un nuovo workspace.
///
/// [validate] restituisce un messaggio d'errore o null; [onSubmit] riceve il
/// nome già controllato.
class WorkspaceNameForm extends StatefulWidget {
  const WorkspaceNameForm({
    super.key,
    required this.validate,
    required this.onSubmit,
    this.buttonLabel = 'Crea',
  });

  final String? Function(String name) validate;
  final Future<void> Function(String name) onSubmit;
  final String buttonLabel;

  @override
  State<WorkspaceNameForm> createState() => _WorkspaceNameFormState();
}

class _WorkspaceNameFormState extends State<WorkspaceNameForm> {
  final _controller = TextEditingController();
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
    setState(() => _error = error);
    if (error != null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(name);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = '${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            hintText: 'es. Lavoro, Fotografia, Studio…',
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(widget.buttonLabel),
        ),
      ],
    );
  }
}
