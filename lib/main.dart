import 'package:flutter/material.dart';

import 'app.dart';
import 'data/storage_access.dart';
import 'state/app_state.dart';
import 'state/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  runApp(
    LeviathanApp(state: AppState(DeviceStorageAccess()), settings: settings),
  );
}
