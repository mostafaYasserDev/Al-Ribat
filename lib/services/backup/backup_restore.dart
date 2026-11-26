part of '../backup_export_service.dart';

Future<void> _restoreBackupFromJson(
  String raw, {
  BackupRestoreMode mode = BackupRestoreMode.replace,
}) async {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('هيكلة الملف غير صحيحة.');
  }
  await _restoreBackupFromMap(decoded, mode: mode);
}

Future<void> _restoreBackupFromMap(
  Map<String, dynamic> decoded, {
  BackupRestoreMode mode = BackupRestoreMode.replace,
}) async {
  final v = decoded['version'];
  if (v != 1 && v != 2) {
    throw const FormatException('إصدار النسخة غير مدعوم.');
  }

  final settingsRaw = decoded['settingsJson'];
  if (settingsRaw != null && settingsRaw is! String) {
    throw const FormatException('settingsJson يجب أن يكون نصًا أو null.');
  }

  final projectMetaRaw = decoded['projectMeta'];
  final projectMeta = <String, String>{};
  if (projectMetaRaw != null) {
    if (projectMetaRaw is! Map) {
      throw const FormatException('projectMeta يجب أن يكون كائنًا.');
    }
    for (final entry in projectMetaRaw.entries) {
      if (entry.value is String) {
        projectMeta[entry.key.toString()] = entry.value as String;
      }
    }
  }

  final parsedV2 = v == 2 ? _parseBackupV2(decoded) : null;

  final meta = Hive.box<String>('meta_box');
  final activitiesBox = Hive.box<String>('activities_box');
  final reflBox = Hive.box<String>('reflections_box');
  final workBox = Hive.box<String>('work_sessions_box');

  if (mode == BackupRestoreMode.replace) {
    await activitiesBox.clear();
    await reflBox.clear();
    await workBox.clear();
    final metaKeysToDelete = meta.keys.where((k) {
      final s = k.toString();
      return s.startsWith('proj_groups_meta_') || s.startsWith('proj_info_');
    }).toList();
    for (final k in metaKeysToDelete) {
      await meta.delete(k);
    }
  }

  if (v == 1) {
    await _restoreBackupV1(decoded, activitiesBox, reflBox, workBox);
  } else if (parsedV2 != null) {
    if (parsedV2.activities.isNotEmpty) {
      await activitiesBox.putAll(parsedV2.activities);
    }
    if (parsedV2.reflections.isNotEmpty) {
      await reflBox.putAll(parsedV2.reflections);
    }
    if (parsedV2.workSessions.isNotEmpty) {
      await workBox.putAll(parsedV2.workSessions);
    }
  }

  if (projectMeta.isNotEmpty) {
    await meta.putAll(projectMeta);
  }

  if (mode == BackupRestoreMode.replace) {
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
  } else {
    // Merge mode: preserve existing settings if present; keep highest streak.
    if (meta.get('settings') == null && settingsRaw != null) {
      await meta.put('settings', settingsRaw);
    }
    final importedCount =
        int.tryParse(decoded['streakCount']?.toString() ?? '') ?? 0;
    final currentCount = int.tryParse(meta.get('streak_count') ?? '') ?? 0;
    if (importedCount > currentCount) {
      await meta.put('streak_count', importedCount.toString());
      final streakLastDate = decoded['streakLastDate'];
      if (streakLastDate is String && streakLastDate.isNotEmpty) {
        await meta.put('streak_last_date', streakLastDate);
      }
    }
  }
}
