import 'package:hive/hive.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._box);

  final Box<dynamic> _box;

  AppSettings getSettings() {
    final map = _box.get('app_settings');
    if (map == null) {
      return AppSettings.defaults();
    }
    return AppSettings.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _box.put('app_settings', settings.toMap());
  }
}
