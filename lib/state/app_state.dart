import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/draft_store.dart';
import '../data/graph_layout_store.dart';
import '../data/note_repository.dart';
import '../data/recent_store.dart';
import '../data/storage_access.dart';
import '../data/tag_color_store.dart';
import '../data/workspace_repository.dart';

enum AppStatus { loading, needsPermission, onboarding, ready, error }

/// Stato globale: permesso di archiviazione, workspace disponibili e attivo.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageAccess _storage;
  WorkspaceRepository? _repo;

  AppStatus status = AppStatus.loading;
  String? errorMessage;
  List<String> workspaces = const [];
  String? currentWorkspace;

  /// Il primo workspace è appena stato creato dall'onboarding: entrandoci
  /// parte il tour guidato. Resta solo in memoria per questa sessione.
  bool firstWorkspaceCreated = false;

  WorkspaceRepository get repository => _repo!;

  Future<void> init() async {
    try {
      if (!await _storage.isGranted()) {
        _set(AppStatus.needsPermission);
        return;
      }
      _repo ??= WorkspaceRepository(await _storage.root());
      await _repo!.root.create(recursive: true);
      try {
        await _repo!.migrateLegacyNames();
      } on FileSystemException {
        // Restano i vecchi nomi: le note si aprono lo stesso.
      }
      workspaces = await _repo!.listWorkspaces();
      if (workspaces.isEmpty) {
        currentWorkspace = null;
        _set(AppStatus.onboarding);
        return;
      }
      final last = await _repo!.readLastWorkspace();
      currentWorkspace = workspaces.contains(last) ? last : workspaces.first;
      _set(AppStatus.ready);
    } on Object catch (e) {
      errorMessage = '$e';
      _set(AppStatus.error);
    }
  }

  Future<void> requestPermission() async {
    if (await _storage.request()) await init();
  }

  /// Richiamato quando l'app torna in primo piano (es. dalle impostazioni).
  Future<void> recheckPermission() async {
    if (status == AppStatus.needsPermission && await _storage.isGranted()) {
      await init();
    }
  }

  /// Crea un workspace e lo apre. Lancia [ArgumentError] se il nome non va.
  Future<void> createWorkspace(String name) async {
    final created = await repository.createWorkspace(name);
    if (status == AppStatus.onboarding) firstWorkspaceCreated = true;
    workspaces = await repository.listWorkspaces();
    await switchTo(created);
  }

  /// Rinomina il workspace [oldName]; se è quello aperto, resta aperto col
  /// nuovo nome. Lancia [ArgumentError] se il nome non va.
  Future<void> renameWorkspace(String oldName, String newName) async {
    final renamed = await repository.renameWorkspace(oldName, newName);
    workspaces = await repository.listWorkspaces();
    if (currentWorkspace == oldName) currentWorkspace = renamed;
    notifyListeners();
  }

  /// Elimina il workspace [name] (spostandolo fra gli eliminati). Se era
  /// quello aperto passa al primo rimasto; se non ne resta nessuno torna
  /// all'onboarding.
  Future<void> deleteWorkspace(String name) async {
    await repository.deleteWorkspace(name);
    workspaces = await repository.listWorkspaces();
    if (workspaces.isEmpty) {
      currentWorkspace = null;
      _set(AppStatus.onboarding);
    } else if (currentWorkspace == name) {
      await switchTo(workspaces.first);
    } else {
      notifyListeners();
    }
  }

  Future<void> switchTo(String name) async {
    currentWorkspace = name;
    await repository.writeLastWorkspace(name);
    _set(AppStatus.ready);
  }

  WorkspaceNameError? validateNewName(String name) =>
      WorkspaceRepository.validateName(name, workspaces);

  /// Come [validateNewName], ma il workspace [oldName] può tenere il suo nome
  /// (o cambiarne solo maiuscole e minuscole).
  WorkspaceNameError? validateRename(String oldName, String name) =>
      WorkspaceRepository.validateName(name, [
        for (final w in workspaces)
          if (w != oldName) w,
      ]);

  /// L'archivio delle note del workspace [name].
  NoteRepository notesOf(String name) => NoteRepository(
    repository.workspaceDir(name),
    trashDir: repository.trashDir(name),
  );

  /// Dove si salvano le posizioni dei nodi del grafo del workspace [name].
  GraphLayoutStore graphLayoutOf(String name) =>
      GraphLayoutStore(repository.graphLayoutFile(name));

  /// Dove si salvano i colori scelti per i tag del workspace [name].
  TagColorStore tagColorsOf(String name) =>
      TagColorStore(repository.tagColorsFile(name));

  /// Dove si tiene la bozza della home del workspace [name].
  DraftStore draftOf(String name) => DraftStore(repository.draftFile(name));

  /// Dove si tiene la modifica a metà di una nota del workspace [name].
  EditDraftStore editDraftOf(String name) =>
      EditDraftStore(repository.editDraftFile(name));

  /// Dove si ricordano le note aperte di recente nel workspace [name].
  RecentStore recentOf(String name) => RecentStore(repository.recentFile(name));

  void _set(AppStatus next) {
    status = next;
    notifyListeners();
  }
}
