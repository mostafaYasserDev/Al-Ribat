part of '../backup_export_service.dart';

Future<void> _restoreBackupV2(
  Map<String, dynamic> decoded,
  Box<String> activitiesBox,
  Box<String> reflBox,
  Box<String> workBox,
) async {
  final activities = _asBackupStringList(
    decoded['activities'] ?? [],
    key: 'activities',
  );
  final reflections = _asBackupStringList(
    decoded['reflections'] ?? [],
    key: 'reflections',
  );
  final workSessions = _asBackupStringList(
    decoded['workSessions'] ?? [],
    key: 'workSessions',
  );

  for (final item in activities) {
    await _putBackupByEntityId(activitiesBox, item);
  }
  for (final item in reflections) {
    await _putBackupByEntityId(reflBox, item);
  }
  for (final item in workSessions) {
    await _putBackupByEntityId(workBox, item);
  }
}
