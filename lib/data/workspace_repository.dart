import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'atomic_write.dart';

/// Perché un nome di workspace non va bene; il messaggio lo scrive la UI.
enum WorkspaceNameError {
  empty,
  tooLong,
  leadingDot,
  trailingDot,
  invalidChars,
  taken,
}

/// Gestisce i workspace su disco.
///
/// Ogni workspace è una sottocartella di [root]. Le cartelle che iniziano con
/// un punto sono riservate all'app (impostazioni, indici) e non sono workspace.
class WorkspaceRepository {
  WorkspaceRepository(this.root);

  final Directory root;

  static const _settingsDirName = '.leviathan';
  static const _settingsFileName = 'settings.json';

  /// Dove finiscono i workspace eliminati, e dentro ognuno le sue parti.
  static const deletedDirName = 'deleted';
  static const _deletedNotes = 'notes';
  static const _deletedTrash = 'trash';
  static const _deletedGraph = 'graph.json';
  static const _deletedDraft = 'draft.json';
  static const _deletedTagColors = 'tag-colors.json';
  static const _deletedEditDraft = 'edit-draft.json';
  static const _deletedRecent = 'recent.json';

  /// I nomi italiani delle prime versioni, con quelli che li sostituiscono.
  static const _legacyDeletedDirName = 'eliminati';
  static const _legacyDeletedParts = {
    'note': _deletedNotes,
    'cestino': _deletedTrash,
    'grafo.json': _deletedGraph,
    'bozza.json': _deletedDraft,
  };

  /// Caratteri che i file system non accettano nei nomi di cartella.
  static const invalidChars = r'<>:"/\|?*';

  static const maxNameLength = 60;

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
  /// Lancia [ArgumentError] con il [WorkspaceNameError] se il nome non è
  /// valido o è già in uso.
  Future<String> createWorkspace(String rawName) async {
    final name = rawName.trim();
    final error = validateName(name, await listWorkspaces());
    if (error != null) throw ArgumentError(error);
    await Directory(p.join(root.path, name)).create(recursive: true);
    return name;
  }

  /// Rinomina il workspace [oldName] e ne restituisce il nuovo nome
  /// normalizzato. Sposta anche cestino, disposizione del grafo, bozza e
  /// colori dei tag.
  ///
  /// Lancia [ArgumentError] con il [WorkspaceNameError] se il nome non è
  /// valido o è già in uso.
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
    final colors = tagColorsFile(oldName);
    if (colors.existsSync()) {
      await colors.parent.create(recursive: true);
      await colors.rename(tagColorsFile(name).path);
    }
    for (final file in [editDraftFile, recentFile]) {
      final from = file(oldName);
      if (from.existsSync()) await from.rename(file(name).path);
    }
    if (await readLastWorkspace() == oldName) await writeLastWorkspace(name);
    return name;
  }

  /// Elimina il workspace [name] senza cancellare nulla: note, cestino,
  /// disposizione del grafo, bozze, colori dei tag e note recenti finiscono
  /// in `.leviathan/deleted/<nome> <data>`.
  /// Restituisce la cartella in cui sono stati spostati.
  Future<Directory> deleteWorkspace(String name) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final target = Directory(
      p.join(root.path, _settingsDirName, deletedDirName, '$name $stamp'),
    );
    await target.create(recursive: true);
    await _move(
      workspaceDir(name),
      Directory(p.join(target.path, _deletedNotes)),
    );
    await _move(trashDir(name), Directory(p.join(target.path, _deletedTrash)));
    final layout = graphLayoutFile(name);
    if (layout.existsSync()) {
      await layout.rename(p.join(target.path, _deletedGraph));
    }
    final draft = draftFile(name);
    if (draft.existsSync()) {
      await draft.rename(p.join(target.path, _deletedDraft));
    }
    final colors = tagColorsFile(name);
    if (colors.existsSync()) {
      await colors.rename(p.join(target.path, _deletedTagColors));
    }
    final edit = editDraftFile(name);
    if (edit.existsSync()) {
      await edit.rename(p.join(target.path, _deletedEditDraft));
    }
    final recent = recentFile(name);
    if (recent.existsSync()) {
      await recent.rename(p.join(target.path, _deletedRecent));
    }
    return target;
  }

  /// Porta ai nomi inglesi i workspace eliminati con le prime versioni:
  /// `.leviathan/eliminati/<…>/{note,cestino,grafo.json,bozza.json}` diventa
  /// `.leviathan/deleted/<…>/{notes,trash,graph.json,draft.json}`.
  ///
  /// Non sovrascrive nulla: se un nome nuovo è già occupato la voce resta
  /// dov'è, e così anche la vecchia cartella.
  Future<void> migrateLegacyNames() async {
    final legacy = Directory(
      p.join(root.path, _settingsDirName, _legacyDeletedDirName),
    );
    if (!legacy.existsSync()) return;
    final deleted = Directory(
      p.join(root.path, _settingsDirName, deletedDirName),
    );
    deleted.createSync(recursive: true);
    for (final entry in legacy.listSync(followLinks: false)) {
      if (entry is Directory) {
        for (final MapEntry(key: old, value: renamed)
            in _legacyDeletedParts.entries) {
          final from = p.join(entry.path, old);
          final to = p.join(entry.path, renamed);
          if (FileSystemEntity.typeSync(to) != FileSystemEntityType.notFound) {
            continue;
          }
          switch (FileSystemEntity.typeSync(from)) {
            case FileSystemEntityType.directory:
              await Directory(from).rename(to);
            case FileSystemEntityType.file:
              await File(from).rename(to);
            default:
          }
        }
      }
      final target = p.join(deleted.path, p.basename(entry.path));
      if (FileSystemEntity.typeSync(target) == FileSystemEntityType.notFound) {
        await entry.rename(target);
      }
    }
    if (legacy.listSync().isEmpty) await legacy.delete();
  }

  /// Sposta una cartella, se esiste. Se cambia solo maiuscole/minuscole passa
  /// da un nome temporaneo: sui file system che non le distinguono il rename
  /// diretto fallirebbe.
  Future<void> _move(Directory from, Directory to) async {
    if (!from.existsSync()) return;
    to.parent.createSync(recursive: true);
    if (from.path.toLowerCase() == to.path.toLowerCase()) {
      from = await from.rename('${to.path}.renaming');
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

  /// I colori scelti a mano per i tag del workspace [name].
  File tagColorsFile(String name) =>
      File(p.join(root.path, _settingsDirName, 'tag-colors', '$name.json'));

  /// La bozza non salvata della home del workspace [name].
  File draftFile(String name) =>
      File(p.join(root.path, _settingsDirName, 'drafts', '$name.json'));

  /// La modifica rimasta a metà di una nota del workspace [name].
  File editDraftFile(String name) =>
      File(p.join(root.path, _settingsDirName, 'edit-drafts', '$name.json'));

  /// Le note aperte di recente nel workspace [name].
  File recentFile(String name) =>
      File(p.join(root.path, _settingsDirName, 'recent', '$name.json'));

  /// Il workspace usato per ultimo, se registrato.
  ///
  /// Le impostazioni sono un file minuscolo: lo si legge e scrive in modo
  /// sincrono, e la scrittura è atomica ([writeFileAtomic]).
  Future<String?> readLastWorkspace() async {
    try {
      final json = jsonDecode(_settingsFile.readAsStringSync());
      return (json as Map<String, dynamic>)['lastWorkspace'] as String?;
    } on Object {
      return null;
    }
  }

  Future<void> writeLastWorkspace(String name) async {
    writeFileAtomic(_settingsFile, jsonEncode({'lastWorkspace': name}));
  }

  /// Controlla un nome di workspace; restituisce l'errore o null.
  static WorkspaceNameError? validateName(
    String rawName,
    List<String> existing,
  ) {
    final name = rawName.trim();
    if (name.isEmpty) return WorkspaceNameError.empty;
    if (name.length > maxNameLength) return WorkspaceNameError.tooLong;
    if (name.startsWith('.')) return WorkspaceNameError.leadingDot;
    if (name.endsWith('.')) return WorkspaceNameError.trailingDot;
    if (invalidChars.split('').any(name.contains)) {
      return WorkspaceNameError.invalidChars;
    }
    final lower = name.toLowerCase();
    if (existing.any((e) => e.toLowerCase() == lower)) {
      return WorkspaceNameError.taken;
    }
    return null;
  }
}
