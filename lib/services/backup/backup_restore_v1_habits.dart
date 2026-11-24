part of '../backup_export_service.dart';

Future<void> _restoreBackupV1Habits(
  Map<String, dynamic> decoded,
  Box<String> activitiesBox,
) async {
  final habits = _asBackupStringList(decoded['habits'] ?? [], key: 'habits');
  for (final hStr in habits) {
    final h = jsonDecode(hStr) as Map<String, dynamic>;
    final history = h['history'] as List<dynamic>?;
    final act = {
      'id': h['id'],
      'title': h['title'],
      'description': h['description'],
      'repetition': 'daily',
      'type': 'independent',
      'linkedPrayer': h['anchorPrayer'],
      'notificationsEnabled': h['notificationsEnabled'] ?? false,
      'reminderHour': h['reminderHour'],
      'reminderMinute': h['reminderMinute'],
      'isMeasurable': h['isMeasurable'] ?? false,
      'targetGoal': h['targetGoal'],
      'goalUnit': h['goalUnit'],
      'createdAt': h['createdAt'],
      'history': h['history'] ?? [],
      'historyDates': history?.map((e) => (e as Map)['date']).toList() ?? [],
      'orderIndex': h['orderIndex'] ?? 0,
      'skippedDates': h['skippedDates'] ?? <String>[],
    };
    await _putBackupByEntityId(activitiesBox, jsonEncode(act));
  }
}
