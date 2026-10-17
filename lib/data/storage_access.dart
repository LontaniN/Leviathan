import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dove vivono le note e come ottenere il permesso di scriverci.
abstract interface class StorageAccess {
  /// True se l'app può già leggere e scrivere nella cartella principale.
  Future<bool> isGranted();

  /// Chiede il permesso all'utente; restituisce lo stato aggiornato.
  Future<bool> request();

  /// La cartella che contiene tutti i workspace.
  Future<Directory> root();
}

/// Implementazione reale.
///
/// Su Android le note stanno in `Documents/LeviathanNotes` nella memoria
/// condivisa, così sopravvivono alla disinstallazione e si possono
/// sincronizzare; serve il permesso "Accesso a tutti i file". Sul desktop
/// stanno in `Documenti/LeviathanNotes` e non serve alcun permesso.
class DeviceStorageAccess implements StorageAccess {
  static const folderName = 'LeviathanNotes';

  @override
  Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    return Permission.manageExternalStorage.isGranted;
  }

  @override
  Future<bool> request() async {
    if (!Platform.isAndroid) return true;
    return (await Permission.manageExternalStorage.request()).isGranted;
  }

  @override
  Future<Directory> root() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Documents/$folderName');
    }
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, folderName));
  }
}
