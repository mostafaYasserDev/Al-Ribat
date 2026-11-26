part of '../backup_export_service.dart';

Future<String> _buildBackupJson() async {
  final meta = Hive.box<String>('meta_box');
  final activitiesBox = Hive.box<String>('activities_box');
  final reflBox = Hive.box<String>('reflections_box');
  final workBox = Hive.box<String>('work_sessions_box');

  final projectMeta = <String, String>{};
  for (final key in meta.keys) {
    final k = key.toString();
    if (k.startsWith('proj_groups_meta_') || k.startsWith('proj_info_')) {
      final val = meta.get(key);
      if (val != null) projectMeta[k] = val;
    }
  }

  final payload = <String, dynamic>{
    'version': 2,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'settingsJson': meta.get('settings'),
    'streakCount': meta.get('streak_count'),
    'streakLastDate': meta.get('streak_last_date'),
    'projectMeta': projectMeta,
    'activities': activitiesBox.values.toList(),
    'reflections': reflBox.values.toList(),
    'workSessions': workBox.values.toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}
