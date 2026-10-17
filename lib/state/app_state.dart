import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/note_repository.dart';
import '../data/storage_access.dart';
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

  WorkspaceRepository get repository => _repo!;

  Future<void> init() async {
    try {
      if (!await _storage.isGranted()) {
        _set(AppStatus.needsPermission);
        return;
      }
      _repo ??= WorkspaceRepository(await _storage.root());
      await _repo!.root.create(recursive: true);
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
    workspaces = await repository.listWorkspaces();
    await switchTo(created);
  }

  Future<void> switchTo(String name) async {
    currentWorkspace = name;
    await repository.writeLastWorkspace(name);
    _set(AppStatus.ready);
  }

  String? validateNewName(String name) =>
      WorkspaceRepository.validateName(name, workspaces);

  /// L'archivio delle note del workspace [name].
  NoteRepository notesOf(String name) => NoteRepository(
        repository.workspaceDir(name),
        trashDir: Directory(
            p.join(repository.root.path, '.leviathan', 'trash', name)),
      );

  void _set(AppStatus next) {
    status = next;
    notifyListeners();
  }
}
