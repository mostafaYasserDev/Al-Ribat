import 'dart:convert';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/activity_item.dart';

part 'activity/activity_item_model_entity.dart';
part 'activity/activity_item_model_from_json.dart';
part 'activity/activity_item_model_to_json.dart';

class ActivityItemModel extends ActivityItem {
  const ActivityItemModel({
    required super.id,
    required super.title,
    super.description,
    super.repetition = ActivityRepetition.daily,
    super.repeatDays = const [],
    super.targetDate,
    super.endDate,
    super.type = ActivityType.independent,
    super.linkedPrayer,
    super.notificationsEnabled = false,
    super.reminderHour,
    super.reminderMinute,
    super.isMeasurable = false,
    super.targetGoal,
    super.goalUnit,
    required super.createdAt,
    super.history = const [],
    super.historyDates = const {},
    super.skippedDates = const {},
    super.orderIndex = 0,
    super.colorHex,
    super.iconName,
    super.projectName,
    super.groupName,
  });

  factory ActivityItemModel.fromEntity(ActivityItem entity) =>
      _activityItemModelFromEntity(entity);

  factory ActivityItemModel.fromJson(String source) =>
      _activityItemModelFromJson(source);

  String toJson() => _activityItemModelToJson(this);
}
