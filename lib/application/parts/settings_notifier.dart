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
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).saveSettings(settings);
      return settings;
    });
    ref.invalidate(prayerScheduleProvider);
  }
}
