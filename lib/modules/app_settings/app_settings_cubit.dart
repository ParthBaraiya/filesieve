import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_settings_model.dart';
import '../../repository/app_settings/app_settings_repository_base.dart';
import '../../values/enums.dart';

/// AppSettingsCubit — app-wide preferences (theme, removal behaviour).
/// Every change is saved immediately.
class AppSettingsCubit extends Cubit<AppSettingsModel> {
  AppSettingsCubit({
    required AppSettingsRepositoryBase repository,
    required AppSettingsModel initial,
  }) : _repository = repository,
       super(initial);

  final AppSettingsRepositoryBase _repository;

  void setThemeMode(AppThemeMode mode) => _update(state.copyWith(themeMode: mode));

  /// Flips between light and dark. [currentlyDark] is what is on screen now,
  /// which matters when the mode is "system".
  void toggleTheme({required bool currentlyDark}) => setThemeMode(
    currentlyDark ? AppThemeMode.light : AppThemeMode.dark,
  );

  void setRemovalMode(RemovalMode mode) =>
      _update(state.copyWith(removalMode: mode));

  void setConfirmBeforeEveryRemoval(bool value) =>
      _update(state.copyWith(confirmBeforeEveryRemoval: value));

  void setIncludeSubfolders(bool value) =>
      _update(state.copyWith(includeSubfolders: value));

  void setSkipHiddenFiles(bool value) =>
      _update(state.copyWith(skipHiddenFiles: value));

  /// Restores defaults and deletes the saved file.
  Future<void> reset() async {
    emit(const AppSettingsModel());
    await _repository.clear();
  }

  void _update(AppSettingsModel next) {
    emit(next);
    _repository.save(next);
  }
}
