import 'package:freezed_annotation/freezed_annotation.dart';

import '../values/enums.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

/// AppSettingsModel — user preferences saved between launches.
@freezed
abstract class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(RemovalMode.trash) RemovalMode removalMode,
    @Default(false) bool confirmBeforeEveryRemoval,
    @Default(true) bool includeSubfolders,
    @Default(true) bool skipHiddenFiles,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsModelFromJson(json);
}
