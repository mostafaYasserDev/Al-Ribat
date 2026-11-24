part of '../backup_export_service.dart';

Future<String> _buildBackupJson() async {
  final meta = Hive.box<String>('meta_box');
  final activitiesBox = Hive.box<String>('activities_box');
  final reflBox = Hive.box<String>('reflections_box');
  final workBox = Hive.box<String>('work_sessions_box');

  final payload = <String, dynamic>{
    'version': 2,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'settingsJson': meta.get('settings'),
    'streakCount': meta.get('streak_count'),
    'streakLastDate': meta.get('streak_last_date'),
    'activities': activitiesBox.values.toList(),
    'reflections': reflBox.values.toList(),
    'workSessions': workBox.values.toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}
