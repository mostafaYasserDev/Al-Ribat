part of '../backup_export_service.dart';

Future<void> _restoreBackupV1Tasks(
  Map<String, dynamic> decoded,
  Box<String> activitiesBox,
) async {
  final tasks = _asBackupStringList(decoded['tasks'] ?? [], key: 'tasks');
  for (final tStr in tasks) {
    final t = jsonDecode(tStr) as Map<String, dynamic>;
    final act = {
      'id': t['id'],
      'title': t['title'],
      'description': t['description'],
      'repetition': 'once',
      'targetDate': t['date'],
      'type': t['type'] ?? 'independent',
      'linkedPrayer': t['linkedPrayer'],
      'notificationsEnabled': t['notificationsEnabled'] ?? false,
      'reminderHour': t['reminderHour'],
      'reminderMinute': t['reminderMinute'],
      'isMeasurable': false,
      'createdAt': t['createdAt'],
      'history': t['isCompleted'] == true
          ? [
              {'date': t['date'], 'isSkipped': false, 'progress': 1.0},
            ]
          : [],
      'historyDates': t['isCompleted'] == true ? [t['date']] : [],
      'orderIndex': t['orderIndex'] ?? 0,
      'skippedDates': <String>[],
    };
    await _putBackupByEntityId(activitiesBox, jsonEncode(act));
  }
}
