import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> saveSettings(AppSettings settings);
}
