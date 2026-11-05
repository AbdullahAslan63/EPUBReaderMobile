import 'package:hive/hive.dart';

import '../models/app_settings.dart';
import 'hive_boxes.dart';

class SettingsService {
  SettingsService({Box? settingsBox})
      : _settings = settingsBox ?? HiveBoxes.settingsBox;

  static const _key = 'app';

  final Box _settings;

  Future<AppSettings> getSettings() async {
    final raw = _settings.get(_key);
    if (raw is Map) {
      return AppSettings.fromMap(Map<dynamic, dynamic>.from(raw));
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settings.put(_key, settings.toMap());
  }
}
