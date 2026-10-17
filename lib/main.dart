import 'package:flutter/material.dart';

import 'app.dart';
import 'data/storage_access.dart';
import 'state/app_state.dart';

void main() {
  runApp(LeviathanApp(state: AppState(DeviceStorageAccess())));
}
