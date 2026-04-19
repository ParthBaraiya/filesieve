import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/file_picker/fs_picker_base.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../models/scan_duplicate_entry_model.dart';
import '../../models/scan_folder_model.dart';
import '../../models/scan_progress_model.dart';
import '../../repository/duplicate_finder/duplicate_finder_repository_base.dart';
import '../../repository/scan_session/scan_session_repository_base.dart';
import '../../utils/cancel_token.dart';
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

  // ignore: unused_field
  final ScanSessionRepositoryBase _repository;
  final DuplicateFinderRepositoryBase _scanRepository;
  CancelToken _cancelToken = CancelToken();

  @override
  Future<void> close() {
    _cancelToken.cancel();
    return super.close();
  }

  //#region Scan
  // -------------------------------------------------------------------------
  // Scan
  // -------------------------------------------------------------------------

  Future<void> startScan() async {
    if (state is! HomeScreenFoldersAdded) return;

    final currentFolders = state.allFolders;
    final files = <File>[];
    for (final folder in currentFolders) {
      try {
        await for (final entity in Directory(
          folder.path,
        ).list(recursive: true)) {
          if (entity is File) files.add(entity);
        }
      } on FileSystemException {
        // silently skip unreadable directories
      }
    }

    _cancelToken = CancelToken();
    emit(HomeScreenState.scanning(folders: List.unmodifiable(currentFolders)));

    try {
      await _scanRepository.find(
        files: files,
        onProgress: (sp) {
          emit(
            (state as HomeScreenScanning).copyWith(
              progress: sp,
              currentFilePath: sp.currentPath,
              filesAnalyzed: sp.stage == 'scanning'
                  ? sp.stageProcessed
                  : (state as HomeScreenScanning).filesAnalyzed,
              overallPercent: _computeOverallPercent(
                sp,
                (state as HomeScreenScanning).overallPercent,
              ),
            ),
          );
        },
        onGroupFound: (group, sizes) {
          final newEntries = <ScanDuplicateEntryModel>[];
          for (int i = 1; i < group.paths.length; i++) {
            newEntries.add(
              ScanDuplicateEntryModel(
                path: group.paths[i],
                fileName: p.basename(group.paths[i]),
                parentPath: p.dirname(group.paths[i]),
                sizeBytes: sizes[i],
                matchPercent: 100,
              ),
            );
          }
          emit(
            (state as HomeScreenScanning).copyWith(
              liveEntries: List.unmodifiable([
                ...(state as HomeScreenScanning).liveEntries,
                ...newEntries,
              ]),
            ),
          );
        },
        cancelToken: _cancelToken,
      );
      // TODO(future): navigate to results screen
    } on ScanCancelledException {
      emit(
        HomeScreenState.foldersAdded(
          folders: List.unmodifiable(state.allFolders),
        ),
      );
    } catch (e) {
      emit(
        HomeScreenState.foldersAdded(
          folders: List.unmodifiable(state.allFolders),
        ),
      );
    }
  }

  void cancelScan() {
    if (state is! HomeScreenScanning) return;
    _cancelToken.cancel();
  }

  double _computeOverallPercent(ScanProgress sp, double currentOverallPercent) {
    final ratio = sp.stageTotal == 0
        ? 0.0
        : (sp.stageProcessed / sp.stageTotal).clamp(0.0, 1.0);
    switch (sp.stage) {
      case 'scanning':
        return ratio * 10.0;
      case 'partial':
        return 10.0 + ratio * 40.0;
      case 'full':
        return 50.0 + ratio * 40.0;
      case 'compare':
        return 90.0 + ratio * 9.0;
      case 'done':
        return 100.0;
      default:
        return currentOverallPercent;
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
        HomeScreenState.foldersAdded(folders: List.unmodifiable(validFolders)),
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
    try {
      folders.removeAt(index);

      if (folders.isNotEmpty) {
        emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(folders)));
      } else {
        emit(const HomeScreenState.initial());
      }
    } catch (e) {
      print('$e');
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
