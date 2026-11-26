part of '../providers.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.watch(settingsRepositoryProvider).load();
  }

  Future<void> updateSettings(AppSettings settings) async {
    final prev = state.valueOrNull;
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).saveSettings(settings);
      return settings;
    });
    if (prev == null ||
        prev.autoLocalBackupEnabled != settings.autoLocalBackupEnabled ||
        prev.autoLocalBackupPath != settings.autoLocalBackupPath) {
      unawaited(LocalAutoBackupService.applySettings(settings));
    }
  }
}
