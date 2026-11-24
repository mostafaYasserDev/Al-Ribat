part of '../backup_export_service.dart';

Future<void> _restoreBackupFromJson(String raw) async {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('هيكلة الملف غير صحيحة.');
  }
  await _restoreBackupFromMap(decoded);
}

Future<void> _restoreBackupFromMap(Map<String, dynamic> decoded) async {
  final v = decoded['version'];

  final meta = Hive.box<String>('meta_box');
  final activitiesBox = Hive.box<String>('activities_box');
  final reflBox = Hive.box<String>('reflections_box');
  final workBox = Hive.box<String>('work_sessions_box');

  await activitiesBox.clear();
  await reflBox.clear();
  await workBox.clear();

  if (v == 1) {
    await _restoreBackupV1(decoded, activitiesBox, reflBox, workBox);
  } else if (v == 2) {
    await _restoreBackupV2(decoded, activitiesBox, reflBox, workBox);
  } else {
    throw const FormatException('إصدار النسخة غير مدعوم.');
  }

  final settingsRaw = decoded['settingsJson'];
  if (settingsRaw != null && settingsRaw is! String) {
    throw const FormatException('settingsJson يجب أن يكون نصًا أو null.');
  }

  if (settingsRaw == null) {
    await meta.delete('settings');
  } else {
    await meta.put('settings', settingsRaw);
  }

  final streakCount = decoded['streakCount'];
  if (streakCount is String && streakCount.isNotEmpty) {
    await meta.put('streak_count', streakCount);
  } else {
    await meta.delete('streak_count');
  }

  final streakLastDate = decoded['streakLastDate'];
  if (streakLastDate is String && streakLastDate.isNotEmpty) {
    await meta.put('streak_last_date', streakLastDate);
  } else {
    await meta.delete('streak_last_date');
  }
}
