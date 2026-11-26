import 'dart:io';

import 'package:al_ribat/data/models/app_settings_model.dart';
import 'package:al_ribat/data/repositories/settings_repository_impl.dart';
import 'package:al_ribat/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late SettingsRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('al_ribat_settings_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('meta_box_test');
    repo = SettingsRepositoryImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('meta_box_test');
    await tempDir.delete(recursive: true);
  });

  test('returns defaults when no data exists', () async {
    final loaded = await repo.load();
    expect(loaded.themeMode, AppSettings.defaults.themeMode);
    expect(
        loaded.notificationsEnabled, AppSettings.defaults.notificationsEnabled);
  });

  test('saves and loads settings including new fields', () async {
    final settings = AppSettings.defaults.copyWith(
      themeMode: AppThemeMode.dark,
      asrMadhab: AsrMadhab.hanafi,
      phasePromptsEnabled: false,
      biometricLockEnabled: false,
      autoLockTimeoutSeconds: 60,
      focusLeadMinutes: 20,
    );
    await repo.saveSettings(settings);
    final loaded = await repo.load();
    expect(loaded.themeMode, AppThemeMode.dark);
    expect(loaded.asrMadhab, AsrMadhab.hanafi);
    expect(loaded.phasePromptsEnabled, false);
    expect(loaded.biometricLockEnabled, false);
    expect(loaded.autoLockTimeoutSeconds, 60);
    expect(loaded.focusLeadMinutes, 20);
  });

  test('fromJson uses AppSettings.defaults and survives unknown enums', () {
    final parsedEmpty = AppSettingsModel.fromJson('{}');
    expect(parsedEmpty.themeMode, AppSettings.defaults.themeMode);
    expect(
      parsedEmpty.notificationsEnabled,
      AppSettings.defaults.notificationsEnabled,
    );
    expect(parsedEmpty.asrMadhab, AppSettings.defaults.asrMadhab);

    final parsedUnknown = AppSettingsModel.fromJson(
      '{"themeMode":"neon","prayerMethod":"custom","asrMadhab":"other","prayerLocationMode":"satellite"}',
    );
    expect(parsedUnknown.themeMode, AppSettings.defaults.themeMode);
    expect(parsedUnknown.prayerMethod, AppSettings.defaults.prayerMethod);
    expect(parsedUnknown.asrMadhab, AppSettings.defaults.asrMadhab);
    expect(
      parsedUnknown.prayerLocationMode,
      AppSettings.defaults.prayerLocationMode,
    );
  });
}
