import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/cache_path_entry_model.dart';

part 'settings_screen_state.freezed.dart';

@freezed
sealed class SettingsScreenState with _$SettingsScreenState {
  const factory SettingsScreenState.initial({
    @Default(<CachePathEntry>[]) List<CachePathEntry> entries,
  }) = SettingsScreenInitial;

  const factory SettingsScreenState.pathCopied({
    required List<CachePathEntry> entries,
    required String copiedEntryId,
  }) = SettingsScreenPathCopied;

  const factory SettingsScreenState.openFolderError({
    required List<CachePathEntry> entries,
    required String errorEntryId,
    required String message,
  }) = SettingsScreenOpenFolderError;
}

extension SettingsScreenStateX on SettingsScreenState {
  List<CachePathEntry> get entries => switch (this) {
        SettingsScreenInitial(:final entries) => entries,
        SettingsScreenPathCopied(:final entries) => entries,
        SettingsScreenOpenFolderError(:final entries) => entries,
      };
}
