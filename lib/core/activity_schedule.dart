import 'package:intl/intl.dart';

import '../domain/entities/activity_item.dart';
import 'constants/prayer_phase.dart';

/// Returns whether [activity] should appear on [date] (past, today, or future).
bool activityVisibleOnDate(ActivityItem activity, DateTime date) {
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  final queryDate = DateTime(date.year, date.month, date.day);

  final createdDate = DateTime(
    activity.createdAt.year,
    activity.createdAt.month,
    activity.createdAt.day,
  );

  DateTime startDate = createdDate;
  if (activity.targetDate != null) {
    final target = DateTime.tryParse(activity.targetDate!);
    if (target != null && target.isBefore(startDate)) {
      startDate = DateTime(target.year, target.month, target.day);
    }
  }

  if (queryDate.isBefore(startDate)) return false;

  if (activity.endDate != null) {
    final endTarget = DateTime.tryParse(activity.endDate!);
    if (endTarget != null) {
      final endTargetDate = DateTime(endTarget.year, endTarget.month, endTarget.day);
      if (queryDate.isAfter(endTargetDate)) return false;
    }
  }

  switch (activity.repetition) {
    case ActivityRepetition.once:
      final target = activity.targetDate ?? DateFormat('yyyy-MM-dd').format(activity.createdAt);
      return target == dateStr;
    case ActivityRepetition.daily:
      return true;
    case ActivityRepetition.weekly:
      return activity.repeatDays.contains(date.weekday);
    case ActivityRepetition.monthly:
      return activity.repeatDays.contains(date.day);
  }
}

List<ActivityItem> activitiesForPhase(
  List<ActivityItem> activities,
  PrayerPhase phase,
  DateTime date,
) {
  return activities
      .where((a) => a.type != ActivityType.independent)
      .where((a) => activityVisibleOnDate(a, date))
      .where((a) => a.linkedPrayer == phase)
      .toList();
}

List<ActivityItem> independentActivities(
  List<ActivityItem> activities,
  DateTime date,
) {
  return activities
      .where((a) => a.type == ActivityType.independent)
      .where((a) => activityVisibleOnDate(a, date))
      .toList();
}
