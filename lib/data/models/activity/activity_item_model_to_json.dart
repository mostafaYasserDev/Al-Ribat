part of '../activity_item_model.dart';

String _activityItemModelToJson(ActivityItemModel model) {
  return jsonEncode({
    'id': model.id,
    'title': model.title,
    'description': model.description,
    'repetition': model.repetition.name,
    'repeatDays': model.repeatDays,
    'targetDate': model.targetDate,
    'endDate': model.endDate,
    'type': model.type.name,
    'linkedPrayer': model.linkedPrayer?.name,
    'notificationsEnabled': model.notificationsEnabled,
    'reminderHour': model.reminderHour,
    'reminderMinute': model.reminderMinute,
    'isMeasurable': model.isMeasurable,
    'targetGoal': model.targetGoal,
    'goalUnit': model.goalUnit,
    'createdAt': model.createdAt.toIso8601String(),
    'history': model.history.map((e) => e.toJson()).toList(),
    'historyDates': model.historyDates.toList(),
    'skippedDates': model.skippedDates.toList(),
    'orderIndex': model.orderIndex,
    'colorHex': model.colorHex,
    'iconName': model.iconName,
    'projectName': model.projectName,
    'groupName': model.groupName,
  });
}
