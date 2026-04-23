import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/cache_path_entry_model.dart';
import '../../repository/cache_paths/cache_paths_repository_base.dart';
import '../../values/app_strings.dart';
import 'settings_screen_state.dart';

class SettingsScreenCubit extends Cubit<SettingsScreenState> {
  SettingsScreenCubit({required CachePathsRepositoryBase repository})
      : _repo = repository,
        super(const SettingsScreenState.initial()) {
    _load();
  }

  final CachePathsRepositoryBase _repo;

  Future<void> _load() async {
    try {
      final entries = await _repo.resolveEntries();
      emit(SettingsScreenState.initial(entries: List.unmodifiable(entries)));
    } catch (_) {
      emit(const SettingsScreenState.initial());
    }
  }

  Future<void> openFolder(CachePathEntry entry) async {
    try {
      await _repo.openFolder(entry.path);
    } catch (_) {
      emit(SettingsScreenState.openFolderError(
          entries: state.entries,
          errorEntryId: entry.id,
          message: AppStrings.settingsCacheOpenFolderError));
      await Future.delayed(const Duration(seconds: 3));
      emit(SettingsScreenState.initial(entries: state.entries));
    }
  }

  Future<void> copyPath(CachePathEntry entry) async {
    try {
      await _repo.copyToClipboard(entry.path);
      emit(SettingsScreenState.pathCopied(
          entries: state.entries, copiedEntryId: entry.id));
      await Future.delayed(const Duration(seconds: 2));
      emit(SettingsScreenState.initial(entries: state.entries));
    } catch (_) {}
  }

}
