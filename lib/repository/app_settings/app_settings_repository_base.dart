import '../../models/app_settings_model.dart';

/// Contract for loading and saving [AppSettingsModel].
abstract class AppSettingsRepositoryBase {
  /// Returns the saved settings, or defaults when nothing valid is saved.
  Future<AppSettingsModel> load();

  Future<void> save(AppSettingsModel settings);

  /// Deletes saved settings so defaults apply again.
  Future<void> clear();
}
