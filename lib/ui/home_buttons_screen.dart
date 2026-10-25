import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../model/home_buttons.dart';
import '../state/settings.dart';
import 'theme.dart';

/// Icona, nome, spiegazione e chiave di un pulsante in alto nella home.
extension HomeButtonLook on HomeButton {
  IconData get icon => switch (this) {
    HomeButton.pinned => Icons.push_pin_outlined,
    HomeButton.graph => Icons.hub_outlined,
    HomeButton.lists => Icons.checklist,
    HomeButton.calendar => Icons.calendar_month_outlined,
    HomeButton.diary => Icons.menu_book_outlined,
    HomeButton.taskManager => Icons.low_priority,
  };

  /// La chiave del pulsante nella home (la usano i test).
  Key get homeKey => Key(switch (this) {
    HomeButton.pinned => 'pinned-button',
    HomeButton.graph => 'graph-button',
    HomeButton.lists => 'lists-button',
    HomeButton.calendar => 'calendar-button',
    HomeButton.diary => 'diary-button',
    HomeButton.taskManager => 'task-manager-button',
  });

  String label(AppLocalizations l) => switch (this) {
    HomeButton.pinned => l.pinned,
    HomeButton.graph => l.graph,
    HomeButton.lists => l.tasksAndNotes,
    HomeButton.calendar => l.calendar,
    HomeButton.diary => l.diary,
    HomeButton.taskManager => l.taskManager,
  };

  /// Una riga su a cosa serve, per scegliere quali tenere.
  String help(AppLocalizations l) => switch (this) {
    HomeButton.pinned => l.homeButtonPinnedHelp,
    HomeButton.graph => l.homeButtonGraphHelp,
    HomeButton.lists => l.homeButtonListsHelp,
    HomeButton.calendar => l.homeButtonCalendarHelp,
    HomeButton.diary => l.homeButtonDiaryHelp,
    HomeButton.taskManager => l.homeButtonTaskManagerHelp,
  };
}

/// Sceglie quali pulsanti stanno in alto nella home e in che ordine.
///
/// Ogni pulsante ha un interruttore e una riga su a cosa serve; si
/// trascinano dalla maniglia per cambiare l'ordine. In cima un'anteprima
/// mostra la fila come sarà nella home. Le impostazioni non si possono
/// togliere: stanno sempre in fondo, così si può sempre tornare qui.
class HomeButtonsScreen extends StatefulWidget {
  const HomeButtonsScreen({super.key, required this.settings});

  final Settings settings;

  @override
  State<HomeButtonsScreen> createState() => _HomeButtonsScreenState();
}

class _HomeButtonsScreenState extends State<HomeButtonsScreen> {
  /// Tutti i pulsanti, prima i visibili nel loro ordine, poi i nascosti.
  late List<HomeButton> _order = HomeButton.withHidden(
    widget.settings.homeButtons,
  );
  late final Set<HomeButton> _visible = {...widget.settings.homeButtons};

  void _save() {
    widget.settings.setHomeButtons([
      for (final b in _order)
        if (_visible.contains(b)) b,
    ]);
  }

  void _toggle(HomeButton button, bool on) {
    setState(() => on ? _visible.add(button) : _visible.remove(button));
    _save();
  }

  /// [to] è già la posizione finale, tolto il pulsante da [from].
  void _reorder(int from, int to) {
    setState(() {
      final button = _order.removeAt(from);
      _order.insert(to, button);
    });
    _save();
  }

  void _reset() {
    setState(() {
      _order = [...HomeButton.defaults];
      _visible
        ..clear()
        ..addAll(HomeButton.defaults);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.homeButtons),
        actions: [
          TextButton(
            key: const Key('home-buttons-reset'),
            onPressed: _reset,
            child: Text(l.homeButtonsReset),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LeviathanSpacing.lg,
                LeviathanSpacing.xs,
                LeviathanSpacing.lg,
                LeviathanSpacing.md,
              ),
              child: Text(
                l.homeButtonsHelp,
                style: LeviathanText.meta.copyWith(color: palette.muted),
              ),
            ),
            _Preview(
              buttons: [
                for (final b in _order)
                  if (_visible.contains(b)) b,
              ],
            ),
            const SizedBox(height: LeviathanSpacing.sm),
            Expanded(
              child: ReorderableListView.builder(
                key: const Key('home-buttons-list'),
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(bottom: LeviathanSpacing.xl),
                itemCount: _order.length,
                onReorderItem: _reorder,
                footer: ListTile(
                  key: const Key('home-button-settings'),
                  leading: Icon(Icons.settings_outlined, color: palette.muted),
                  title: Text(l.settings),
                  subtitle: Text(l.homeButtonSettingsHelp),
                  trailing: Icon(Icons.lock_outline, color: palette.muted),
                ),
                itemBuilder: (context, i) {
                  final button = _order[i];
                  final on = _visible.contains(button);
                  return Material(
                    key: ValueKey(button),
                    color: palette.background,
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        key: Key('home-button-drag-${button.name}'),
                        index: i,
                        child: Icon(Icons.drag_handle, color: palette.muted),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            button.icon,
                            size: LeviathanIconSize.md,
                            color: on ? palette.text : palette.muted,
                          ),
                          const SizedBox(width: LeviathanSpacing.sm),
                          Flexible(
                            child: Text(
                              button.label(l),
                              style: TextStyle(
                                color: on ? palette.text : palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(button.help(l)),
                      trailing: Switch(
                        key: Key('home-button-${button.name}'),
                        value: on,
                        onChanged: (value) => _toggle(button, value),
                      ),
                      onTap: () => _toggle(button, !on),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La fila di icone come sarà in alto nella home, con le impostazioni in
/// fondo.
class _Preview extends StatelessWidget {
  const _Preview({required this.buttons});

  final List<HomeButton> buttons;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('home-buttons-preview'),
      margin: const EdgeInsets.symmetric(horizontal: LeviathanSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: LeviathanSpacing.md,
        vertical: LeviathanSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(LeviathanRadii.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final b in [
              ...buttons.map((b) => b.icon),
              Icons.settings_outlined,
            ])
              Padding(
                padding: const EdgeInsets.all(LeviathanSpacing.sm),
                child: Icon(b, color: palette.text),
              ),
          ],
        ),
      ),
    );
  }
}
