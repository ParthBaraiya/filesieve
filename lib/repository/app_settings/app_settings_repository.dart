import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../models/app_settings_model.dart';
import 'app_settings_repository_base.dart';

/// Stores settings as a small JSON file inside [directoryPath]
/// (the ObjectBox store folder).
class AppSettingsRepository implements AppSettingsRepositoryBase {
  AppSettingsRepository(String directoryPath)
    : _file = File(p.join(directoryPath, 'app_settings.json'));

  final File _file;

  @override
  Future<AppSettingsModel> load() async {
    try {
      if (!await _file.exists()) return const AppSettingsModel();
      final json = jsonDecode(await _file.readAsString());
      return AppSettingsModel.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or unreadable file: fall back to defaults.
      return const AppSettingsModel();
    }
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(settings.toJson()));
  }

  @override
  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
