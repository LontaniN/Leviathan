import 'package:flutter/material.dart';

import 'app.dart';
import 'data/storage_access.dart';
import 'state/app_state.dart';
import 'state/share_inbox.dart';
import 'state/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  // Il testo condiviso con cui l'app viene aperta arriva mentre parte.
  final shares = ShareInbox()..listenToPlatform();
  runApp(
    LeviathanApp(
      state: AppState(DeviceStorageAccess()),
      settings: settings,
      shares: shares,
    ),
  );
}
