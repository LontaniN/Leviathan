/// I pulsanti in alto nella home che si possono scegliere e riordinare dalle
/// impostazioni. Le impostazioni non sono fra questi: stanno sempre in
/// fondo, così da lì si può sempre tornare a cambiare la scelta.
enum HomeButton {
  pinned,
  graph,
  lists,
  calendar,
  diary,
  taskManager;

  /// Tutti, nell'ordine di partenza.
  static const defaults = values;

  /// La scelta salvata: i nomi dei pulsanti visibili, in ordine. I nomi
  /// sconosciuti (di versioni future o rovinati) e i doppioni si saltano;
  /// senza una lista valida, tutti nell'ordine di partenza.
  static List<HomeButton> parse(Object? json) {
    if (json is! List) return defaults;
    final buttons = <HomeButton>[];
    for (final name in json) {
      for (final button in values) {
        if (button.name == name && !buttons.contains(button)) {
          buttons.add(button);
        }
      }
    }
    return buttons;
  }

  /// [visible] seguiti dai pulsanti nascosti, nell'ordine di partenza: la
  /// lista che si riordina nelle impostazioni.
  static List<HomeButton> withHidden(List<HomeButton> visible) => [
    ...visible,
    for (final button in values)
      if (!visible.contains(button)) button,
  ];
}
