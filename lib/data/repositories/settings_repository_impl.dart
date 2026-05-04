import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._box);

  final Box<String> _box;
  static const _key = 'settings';

  @override
  Future<AppSettings> load() async {
    final raw = _box.get(_key);
    if (raw == null) return AppSettings.defaults;
    return AppSettingsModel.fromJson(raw);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _box.put(_key, AppSettingsModel.fromEntity(settings).toJson());
  }
}
