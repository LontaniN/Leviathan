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

  /// Rinomina il workspace [oldName] e ne restituisce il nuovo nome
  /// normalizzato. Sposta anche cestino, disposizione del grafo e bozza.
  ///
  /// Lancia [ArgumentError] se il nome non è valido o è già in uso.
  Future<String> renameWorkspace(String oldName, String rawName) async {
    final name = rawName.trim();
    if (name == oldName) return name;
    final others = [
      for (final w in await listWorkspaces())
        if (w != oldName) w,
    ];
    final error = validateName(name, others);
    if (error != null) throw ArgumentError(error);

    await _move(workspaceDir(oldName), workspaceDir(name));
    await _move(trashDir(oldName), trashDir(name));
    final layout = graphLayoutFile(oldName);
    if (layout.existsSync()) {
      await layout.rename(graphLayoutFile(name).path);
    }
    final draft = draftFile(oldName);
    if (draft.existsSync()) await draft.rename(draftFile(name).path);
    if (await readLastWorkspace() == oldName) await writeLastWorkspace(name);
    return name;
  }

  /// Elimina il workspace [name] senza cancellare nulla: note, cestino,
  /// disposizione del grafo e bozza finiscono in
  /// `.leviathan/eliminati/<nome> <data>`.
  /// Restituisce la cartella in cui sono stati spostati.
  Future<Directory> deleteWorkspace(String name) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final target = Directory(
      p.join(root.path, _settingsDirName, 'eliminati', '$name $stamp'),
    );
    await target.create(recursive: true);
    await _move(workspaceDir(name), Directory(p.join(target.path, 'note')));
    await _move(trashDir(name), Directory(p.join(target.path, 'cestino')));
    final layout = graphLayoutFile(name);
    if (layout.existsSync()) {
      await layout.rename(p.join(target.path, 'grafo.json'));
    }
    final draft = draftFile(name);
    if (draft.existsSync()) {
      await draft.rename(p.join(target.path, 'bozza.json'));
    }
    return target;
  }

  /// Sposta una cartella, se esiste. Se cambia solo maiuscole/minuscole passa
  /// da un nome temporaneo: sui file system che non le distinguono il rename
  /// diretto fallirebbe.
  Future<void> _move(Directory from, Directory to) async {
    if (!from.existsSync()) return;
    to.parent.createSync(recursive: true);
    if (from.path.toLowerCase() == to.path.toLowerCase()) {
      from = await from.rename('${to.path}.rinomina');
    }
    await from.rename(to.path);
  }

  Directory workspaceDir(String name) => Directory(p.join(root.path, name));

  /// Il cestino del workspace [name].
  Directory trashDir(String name) =>
      Directory(p.join(root.path, _settingsDirName, 'trash', name));

  /// Il file con le posizioni dei nodi del grafo del workspace [name].
  File graphLayoutFile(String name) =>
      File(p.join(root.path, _settingsDirName, 'graph', '$name.json'));

  /// La bozza non salvata della home del workspace [name].
  File draftFile(String name) =>
      File(p.join(root.path, _settingsDirName, 'drafts', '$name.json'));

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
