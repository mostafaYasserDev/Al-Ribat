part of '../backup_export_service.dart';

({
  Map<String, String> activities,
  Map<String, String> reflections,
  Map<String, String> workSessions,
}) _parseBackupV2(Map<String, dynamic> decoded) {
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

  return (
    activities: _indexByEntityId(activities),
    reflections: _indexByEntityId(reflections),
    workSessions: _indexByEntityId(workSessions),
  );
}

Map<String, String> _indexByEntityId(List<String> items) {
  final out = <String, String>{};
  for (final jsonStr in items) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final id = map['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('عنصر النسخة الاحتياطية يفتقد حقل id.');
    }
    out[id] = jsonStr;
  }
  return out;
}
