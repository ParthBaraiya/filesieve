import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:filesieve/modules/home/duplicate_group_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/file_picker/fs_picker_base.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../models/scan_folder_model.dart';
import '../../repository/duplicate_finder/duplicate_finder_repository_base.dart';
import '../../repository/scan_session/scan_session_repository_base.dart';
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
  HomeScreenCubit({
    required ScanSessionRepositoryBase repository,
    required DuplicateFinderRepositoryBase scanRepository,
  }) : _repository = repository,
       _scanRepository = scanRepository,
       super(const HomeScreenState.initial());

  final ScanSessionRepositoryBase _repository;
  final DuplicateFinderRepositoryBase _scanRepository;

  late final scanner = FileScannerCubit(repo: _scanRepository);

  //#region Scan
  // -------------------------------------------------------------------------
  // Scan
  // -------------------------------------------------------------------------

  Future<void> startScan({
    bool includeSubfolders = true,
    bool skipHidden = true,
  }) async {
    if (state is! HomeScreenFoldersAdded) return;

    final currentFolders = state.allFolders;
    emit(HomeScreenState.scanning(folders: List.unmodifiable(currentFolders)));
    await _repository.createSession(currentFolders);
    await scanner.startScan(
      currentFolders.map((e) => e.path),
      includeSubfolders: includeSubfolders,
      skipHidden: skipHidden,
    );
  }

  //#endregion

  //#region Preview Events
  void setPreviewGroup(DuplicateGroupCubit group) {
    HomeScreenScanning? scannedState;

    if (state is HomeScreenScanning) {
      scannedState = state as HomeScreenScanning;
    } else if (state is HomeScreenFilePreview) {
      scannedState = (state as HomeScreenFilePreview).scannedState;
    }

    emit(
      HomeScreenState.filePreview(
        currentGroup: group,
        scannedState: scannedState,
      ),
    );
  }

  void backToPreview() {
    if (state is HomeScreenFilePreview) {
      final scanner = (state as HomeScreenFilePreview).scannedState;
      if (scanner != null) {
        emit(scanner);
      }
    }
  }
  //#endregion

  //#region Drag-and-drop events
  // -------------------------------------------------------------------------
  // Drag-and-drop events
  // -------------------------------------------------------------------------

  void onDragEnter() => emit(
    HomeScreenState.dragHover(folders: List.unmodifiable(state.allFolders)),
  );

  void onDragExit() {
    if (state.allFolders.isNotEmpty) {
      emit(
        HomeScreenState.foldersAdded(
          folders: List.unmodifiable(state.allFolders),
        ),
      );
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

      final accessible = await _checkScanValidity(path);
      if (!accessible.isValid) {
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
      emit(
        HomeScreenState.foldersAdded(
          folders: List.unmodifiable(<ScanFolderModel>{
            ...state.allFolders,
            ...validFolders,
          }),
        ),
      );
    } else if (lastRejectionReason != null) {
      emit(
        HomeScreenState.dropRejected(
          reason: lastRejectionReason,
          folders: List.unmodifiable(validFolders),
        ),
      );
    }
  }
  //#endregion

  //#region Folder picker
  // -------------------------------------------------------------------------
  // Folder picker
  // -------------------------------------------------------------------------

  /// Opens the native folder-picker dialog (singular selection only —
  /// [file_selector] does not provide a multi-directory picker).
  ///
  /// Validates the selected path before emitting. Returns immediately if
  /// the user cancels the dialog (null result).
  Future<void> onPickFolder() async {
    final path = await serviceLocator.get<FsPickerBase>().getDirectoryPaths();
    await addFolderPaths(path);
  }

  /// Validates each of [path] and adds the readable ones to the folder list.
  Future<void> addFolderPaths(Iterable<String> path) async {
    if (path.isEmpty) return;

    final folder = <ScanFolderModel>[];

    for (final p in path) {
      final accessible = await _checkScanValidity(p);

      if (accessible.isValid) {
        folder.add(
          ScanFolderModel(
            path: p,
            displayName: _displayNameFor(p),
            hasReadAccess: true,
          ),
        );
      }
    }

    if (folder.isEmpty) {
      emit(
        HomeScreenState.dropRejected(
          reason: AppStrings.dropRejectionNoAccess,
          folders: const [],
        ),
      );

      return;
    }

    emit(
      HomeScreenState.foldersAdded(
        folders: List.unmodifiable(<dynamic>{...state.allFolders, ...folder}),
      ),
    );
  }
  //#endregion

  //#region Utility
  // -------------------------------------------------------------------------
  // Utility
  // -------------------------------------------------------------------------

  /// Dismisses transient states (dragHover, dropRejected) back to the
  /// appropriate resting state — foldersAdded if folders exist, initial
  /// otherwise.
  void dismissTransient() {
    if (state.allFolders.isNotEmpty) {
      emit(
        HomeScreenState.foldersAdded(
          folders: List.unmodifiable(state.allFolders),
        ),
      );
    } else {
      emit(const HomeScreenState.initial());
    }
  }

  /// Removes the folder at [index] from the accumulator list.
  /// Emits foldersAdded if folders remain, initial if the list is now empty.
  void removeFolder(int index) {
    final folders = [...state.allFolders];
    if (index < 0 || index >= folders.length) return;
    folders.removeAt(index);

    if (folders.isNotEmpty) {
      emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(folders)));
    } else {
      emit(const HomeScreenState.initial());
    }
  }

  /// Returns [true] when the directory at [path] can be listed.
  ///
  /// - [StateError]: empty directory — still accessible.
  /// - [FileSystemException]: permission denied — not accessible.
  Future<ScanValidityResult> _checkScanValidity(String path) async {
    try {
      final stat = FileStat.statSync(path);
      if (stat.type == .file) {
        return ScanValidityResult(
          isValid: false,
          message: "${p.basename(path)} is skipped because it's a file.",
        );
      }

      final dir = Directory(path);
      await dir.list().first;
      return const ScanValidityResult(isValid: true);
    } on StateError {
      return ScanValidityResult(
        isValid: false,
        message: "${p.basename(path)} is skipped because it's empty.",
      ); // Empty directory — still readable
    } on FileSystemException {
      return ScanValidityResult(
        isValid: false,
        message: "${p.basename(path)} is skipped because access is denied.",
      );
    }
  }

  /// Extracts the display name (last path segment) from [folderPath].
  ///
  /// Uses [Directory.uri] path segments to handle both forward- and
  /// back-slash separators on Windows.
  String _displayNameFor(String folderPath) {
    final segments = Directory(
      folderPath,
    ).uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : folderPath;
  }

  //#endregion
}

class ScanValidityResult {
  final bool isValid;
  final String? message;

  const ScanValidityResult({required this.isValid, this.message});
}
