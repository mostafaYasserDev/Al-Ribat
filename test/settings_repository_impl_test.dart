import 'dart:io';

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
    expect(loaded.themeMode, AppThemeMode.dark);
    expect(loaded.notificationsEnabled, true);
  });

  test('saves and loads settings', () async {
    final settings = AppSettings.defaults.copyWith(
      themeMode: AppThemeMode.light,
      focusLeadMinutes: 20,
    );
    await repo.saveSettings(settings);
    final loaded = await repo.load();
    expect(loaded.themeMode, AppThemeMode.light);
    expect(loaded.focusLeadMinutes, 20);
  });
}
