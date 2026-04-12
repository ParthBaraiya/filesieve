import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/scan_folder_model.dart';
import '../values/app_strings.dart';
import 'dashboard_screen_state.dart';

class DashboardScreenCubit extends Cubit<DashboardScreenState> {
  DashboardScreenCubit() : super(const DashboardScreenState.initial());

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
        DashboardScreenState.dropRejected(
          reason: AppStrings.dropRejectionNotFolder,
        ),
      );
      return;
    }

    final accessible = await _checkReadAccess(path);
    if (!accessible) {
      emit(
        DashboardScreenState.dropRejected(
          reason: AppStrings.dropRejectionNoAccess,
        ),
      );
      return;
    }

    emit(
      DashboardScreenState.foldersAdded(
        folders: [
          ScanFolderModel(
            path: path,
            displayName: _displayNameFor(path),
            hasReadAccess: true,
          ),
        ],
      ),
    );
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
    final segments = Directory(
      folderPath,
    ).uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : folderPath;
  }
}
