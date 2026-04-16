import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/scan_folder_model.dart';
import '../../repository/scan_session_repository.dart';
import '../../values/app_strings.dart';
import 'home_screen_state.dart';

/// HomeScreenCubit — manages drag-and-drop and folder-picker interactions
/// for the onboarding / empty-state screen.
///
/// Folder validation logic (T021):
/// - Uses [Directory.existsSync] to verify the path is a directory.
/// - Attempts [Directory.list().first] to verify read access; a [StateError]
///   (empty dir) is treated as accessible; a [FileSystemException] is not.
class HomeScreenCubit extends Cubit<HomeScreenState> {
  HomeScreenCubit({required ScanSessionRepository repository})
      : _repository = repository,
        super(const HomeScreenState.initial());

  // ignore: unused_field
  final ScanSessionRepository _repository;

  final List<ScanFolderModel> _folders = [];

  // -------------------------------------------------------------------------
  // Drag-and-drop events
  // -------------------------------------------------------------------------

  void onDragEnter() =>
      emit(HomeScreenState.dragHover(folders: List.unmodifiable(_folders)));

  void onDragExit() {
    if (_folders.isNotEmpty) {
      emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(_folders)));
    } else {
      emit(const HomeScreenState.initial());
    }
  }

  /// Called when the user drops items onto the drop zone.
  ///
  /// Each [XFile] is validated as a readable directory. Valid folders are
  /// collected and emitted as [HomeScreenFoldersAdded]. If all items are
  /// invalid, the cubit emits [HomeScreenDropRejected] with the last
  /// rejection reason.
  Future<void> onDrop(List<XFile> files) async {
    final validFolders = <ScanFolderModel>[];
    String? lastRejectionReason;

    for (final file in files) {
      final path = file.path;

      if (!Directory(path).existsSync()) {
        lastRejectionReason = AppStrings.dropRejectionNotFolder;
        continue;
      }

      final accessible = await _checkReadAccess(path);
      if (!accessible) {
        lastRejectionReason = AppStrings.dropRejectionNoAccess;
        continue;
      }

      validFolders.add(
        ScanFolderModel(
          path: path,
          displayName: _displayNameFor(path),
          hasReadAccess: true,
        ),
      );
    }

    if (validFolders.isNotEmpty) {
      _folders.addAll(validFolders);
      emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(_folders)));
    } else if (lastRejectionReason != null) {
      emit(
        HomeScreenState.dropRejected(
          reason: lastRejectionReason,
          folders: List.unmodifiable(_folders),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Folder picker
  // -------------------------------------------------------------------------

  /// Opens the native folder-picker dialog (singular selection only —
  /// [file_selector] does not provide a multi-directory picker).
  ///
  /// Validates the selected path before emitting. Returns immediately if
  /// the user cancels the dialog (null result).
  Future<void> onPickFolder() async {
    final path = await getDirectoryPath();
    if (path == null) return;

    if (!Directory(path).existsSync()) {
      emit(
        HomeScreenState.dropRejected(
          reason: AppStrings.dropRejectionNotFolder,
          folders: List.unmodifiable(_folders),
        ),
      );
      return;
    }

    final accessible = await _checkReadAccess(path);
    if (!accessible) {
      emit(
        HomeScreenState.dropRejected(
          reason: AppStrings.dropRejectionNoAccess,
          folders: List.unmodifiable(_folders),
        ),
      );
      return;
    }

    _folders.add(
      ScanFolderModel(
        path: path,
        displayName: _displayNameFor(path),
        hasReadAccess: true,
      ),
    );
    emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(_folders)));
  }

  // -------------------------------------------------------------------------
  // Utility
  // -------------------------------------------------------------------------

  /// Dismisses transient states (dragHover, dropRejected) back to the
  /// appropriate resting state — foldersAdded if folders exist, initial
  /// otherwise.
  void dismissTransient() {
    if (_folders.isNotEmpty) {
      emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(_folders)));
    } else {
      emit(const HomeScreenState.initial());
    }
  }

  /// Removes the folder at [index] from the accumulator list.
  /// Emits foldersAdded if folders remain, initial if the list is now empty.
  void removeFolder(int index) {
    if (index < 0 || index >= _folders.length) return;
    _folders.removeAt(index);
    if (_folders.isNotEmpty) {
      emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(_folders)));
    } else {
      emit(const HomeScreenState.initial());
    }
  }

  /// Returns [true] when the directory at [path] can be listed.
  ///
  /// - [StateError]: empty directory — still accessible.
  /// - [FileSystemException]: permission denied — not accessible.
  Future<bool> _checkReadAccess(String path) async {
    try {
      await Directory(path).list().first;
      return true;
    } on StateError {
      return true; // Empty directory — still readable
    } on FileSystemException {
      return false;
    }
  }

  /// Extracts the display name (last path segment) from [folderPath].
  ///
  /// Uses [Directory.uri] path segments to handle both forward- and
  /// back-slash separators on Windows.
  String _displayNameFor(String folderPath) {
    final segments = Directory(folderPath)
        .uri
        .pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    return segments.isNotEmpty ? segments.last : folderPath;
  }
}
