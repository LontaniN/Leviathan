import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Gestisce i workspace su disco.
///
/// Ogni workspace è una sottocartella di [root]. Le cartelle che iniziano con
/// un punto sono riservate all'app (impostazioni, indici) e non sono workspace.
class WorkspaceRepository {
  WorkspaceRepository(this.root);

  final Directory root;

  static const _settingsDirName = '.leviathan';
  static const _settingsFileName = 'settings.json';
  static const _invalidChars = r'<>:"/\|?*';

  File get _settingsFile =>
      File(p.join(root.path, _settingsDirName, _settingsFileName));

  /// Restituisce i nomi dei workspace in ordine alfabetico.
  ///
  /// Lettura sincrona: sono poche cartelle e così si evita uno stream.
  Future<List<String>> listWorkspaces() async {
    if (!root.existsSync()) return [];
    final names = [
      for (final entity in root.listSync(followLinks: false))
        if (entity is Directory && !p.basename(entity.path).startsWith('.'))
          p.basename(entity.path),
    ];
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  /// Crea un nuovo workspace e ne restituisce il nome normalizzato.
  ///
  /// Lancia [ArgumentError] se il nome non è valido o è già in uso.
  Future<String> createWorkspace(String rawName) async {
    final name = rawName.trim();
    final error = validateName(name, await listWorkspaces());
    if (error != null) throw ArgumentError(error);
    await Directory(p.join(root.path, name)).create(recursive: true);
    return name;
  }

  Directory workspaceDir(String name) => Directory(p.join(root.path, name));

  /// Il workspace usato per ultimo, se registrato.
  ///
  /// Le impostazioni sono un file minuscolo: lo si legge e scrive in modo
  /// sincrono, così non resta mai una scrittura a metà.
  Future<String?> readLastWorkspace() async {
    try {
      final json = jsonDecode(_settingsFile.readAsStringSync());
      return (json as Map<String, dynamic>)['lastWorkspace'] as String?;
    } on Object {
      return null;
    }
  }

  Future<void> writeLastWorkspace(String name) async {
    _settingsFile.parent.createSync(recursive: true);
    _settingsFile.writeAsStringSync(jsonEncode({'lastWorkspace': name}));
  }

  /// Controlla un nome di workspace; restituisce il messaggio d'errore o null.
  static String? validateName(String rawName, List<String> existing) {
    final name = rawName.trim();
    if (name.isEmpty) return 'Inserisci un nome';
    if (name.length > 60) return 'Nome troppo lungo (max 60 caratteri)';
    if (name.startsWith('.')) return 'Il nome non può iniziare con un punto';
    if (name.endsWith('.')) return 'Il nome non può finire con un punto';
    for (final char in _invalidChars.split('')) {
      if (name.contains(char)) {
        return 'Caratteri non ammessi: $_invalidChars';
      }
    }
    final lower = name.toLowerCase();
    if (existing.any((e) => e.toLowerCase() == lower)) {
      return 'Esiste già un workspace con questo nome';
    }
    return null;
  }
}
