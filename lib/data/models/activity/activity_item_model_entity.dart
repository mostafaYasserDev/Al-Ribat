part of '../activity_item_model.dart';

ActivityItemModel _activityItemModelFromEntity(ActivityItem entity) {
  return ActivityItemModel(
    id: entity.id,
    title: entity.title,
    description: entity.description,
    repetition: entity.repetition,
    repeatDays: entity.repeatDays,
    targetDate: entity.targetDate,
    endDate: entity.endDate,
    type: entity.type,
    linkedPrayer: entity.linkedPrayer,
    notificationsEnabled: entity.notificationsEnabled,
    reminderHour: entity.reminderHour,
    reminderMinute: entity.reminderMinute,
    isMeasurable: entity.isMeasurable,
    targetGoal: entity.targetGoal,
    goalUnit: entity.goalUnit,
    createdAt: entity.createdAt,
    history: entity.history,
    historyDates: entity.historyDates,
    skippedDates: entity.skippedDates,
    orderIndex: entity.orderIndex,
    colorHex: entity.colorHex,
    iconName: entity.iconName,
    projectName: entity.projectName,
    groupName: entity.groupName,
  );
}
