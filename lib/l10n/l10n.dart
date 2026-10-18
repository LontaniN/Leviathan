import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Le lingue dell'interfaccia: codice e nome scritto nella lingua stessa,
/// così nel menu ognuno riconosce la sua.
const appLanguages = {'en': 'English', 'it': 'Italiano'};

/// La lingua del telefono, se l'app la conosce; altrimenti l'inglese.
String deviceLanguage() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return appLanguages.containsKey(code) ? code : 'en';
}

extension L10nContext on BuildContext {
  /// I testi dell'interfaccia nella lingua scelta.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
