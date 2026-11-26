import 'dart:convert';
import 'dart:io';

import 'package:al_ribat/domain/entities/app_settings.dart';
import 'package:al_ribat/services/backup/local_auto_backup_service.dart';
import 'package:al_ribat/services/backup_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory hiveDir;
  late Directory autoBackupDir;
  late Box<String> metaBox;
  late Box<String> activitiesBox;
  late Box<String> reflBox;
  late Box<String> workBox;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDir = await Directory.systemTemp.createTemp('al_ribat_backup_hive_');
    Hive.init(hiveDir.path);
    metaBox = await Hive.openBox<String>('meta_box');
    activitiesBox = await Hive.openBox<String>('activities_box');
    reflBox = await Hive.openBox<String>('reflections_box');
    workBox = await Hive.openBox<String>('work_sessions_box');
  });

  setUp(() async {
    await metaBox.clear();
    await activitiesBox.clear();
    await reflBox.clear();
    await workBox.clear();
    autoBackupDir =
        await Directory.systemTemp.createTemp('al_ribat_auto_backup_');
    await LocalAutoBackupService.resetForTesting();
    LocalAutoBackupService.overrideDirectoryForTesting = autoBackupDir;
  });

  tearDown(() async {
    await LocalAutoBackupService.resetForTesting();
    if (await autoBackupDir.exists()) {
      await autoBackupDir.delete(recursive: true);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('restore does not clear existing data when JSON payload is invalid',
      () async {
    await activitiesBox.put(
        'a1', jsonEncode({'id': 'a1', 'title': 'Existing'}));

    await expectLater(
      BackupExportService.restoreFromJsonString(
        jsonEncode({
          'version': 2,
          'activities': [
            jsonEncode({'title': 'Missing ID'}),
          ],
          'reflections': [],
          'workSessions': [],
        }),
        mode: BackupRestoreMode.replace,
      ),
      throwsFormatException,
    );

    expect(activitiesBox.get('a1'), isNotNull);
  });

  test('restore supports merge and replace modes plus projectMeta', () async {
    await activitiesBox.put(
        'existing_1', jsonEncode({'id': 'existing_1', 'title': 'Keep Me'}));
    await metaBox.put('proj_info_p1', '{"desc":"Local"}');
    await metaBox.put('streak_count', '5');

    final incoming = jsonEncode({
      'version': 2,
      'settingsJson': null,
      'streakCount': '3',
      'projectMeta': {'proj_info_p2': '{"desc":"Imported"}'},
      'activities': [
        jsonEncode({'id': 'imported_1', 'title': 'New Activity'}),
      ],
      'reflections': [],
      'workSessions': [],
    });

    // Merge keeps existing_1, adds imported_1, keeps higher streak (5)
    await BackupExportService.restoreFromJsonString(
      incoming,
      mode: BackupRestoreMode.merge,
    );
    expect(activitiesBox.get('existing_1'), isNotNull);
    expect(activitiesBox.get('imported_1'), isNotNull);
    expect(metaBox.get('proj_info_p1'), '{"desc":"Local"}');
    expect(metaBox.get('proj_info_p2'), '{"desc":"Imported"}');
    expect(metaBox.get('streak_count'), '5');

    // Replace clears existing_1 and proj_info_p1
    await BackupExportService.restoreFromJsonString(
      incoming,
      mode: BackupRestoreMode.replace,
    );
    expect(activitiesBox.get('existing_1'), isNull);
    expect(activitiesBox.get('imported_1'), isNotNull);
    expect(metaBox.get('proj_info_p1'), isNull);
    expect(metaBox.get('proj_info_p2'), '{"desc":"Imported"}');
    expect(metaBox.get('streak_count'), '3');
  });

  test('LocalAutoBackupService writes on enable and updates on Hive changes',
      () async {
    await activitiesBox.put(
        'act_1', jsonEncode({'id': 'act_1', 'title': 'Initial'}));

    await LocalAutoBackupService.applySettings(
      AppSettings.defaults.copyWith(autoLocalBackupEnabled: true),
    );

    final filePath = LocalAutoBackupService.statusNotifier.value.filePath!;
    final file = File(filePath);
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), contains('Initial'));

    // Mutate Hive box and wait for 400ms debounce + atomic write
    await activitiesBox.put(
        'act_2', jsonEncode({'id': 'act_2', 'title': 'Instant Update'}));
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final updatedContent = await file.readAsString();
    expect(updatedContent, contains('Instant Update'));

    // Clear and restore from auto-backup file
    await activitiesBox.clear();
    await LocalAutoBackupService.restoreFromAutoBackup(
      mode: BackupRestoreMode.replace,
    );
    expect(activitiesBox.get('act_1'), isNotNull);
    expect(activitiesBox.get('act_2'), isNotNull);
  });
}
