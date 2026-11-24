part of '../activity_item_model.dart';

ActivityItemModel _activityItemModelFromJson(String source) {
  final map = jsonDecode(source) as Map<String, dynamic>;
  return ActivityItemModel(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    repetition: ActivityRepetition.values.firstWhere(
      (e) => e.name == map['repetition'],
      orElse: () => ActivityRepetition.daily,
    ),
    repeatDays:
        (map['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ??
            const [],
    targetDate: map['targetDate'] as String?,
    endDate: map['endDate'] as String?,
    type: ActivityType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => ActivityType.independent,
    ),
    linkedPrayer: map['linkedPrayer'] != null
        ? PrayerPhase.values.firstWhere(
            (e) => e.name == map['linkedPrayer'],
            orElse: () => PrayerPhase.asr,
          )
        : null,
    notificationsEnabled: map['notificationsEnabled'] as bool? ?? false,
    reminderHour: map['reminderHour'] as int?,
    reminderMinute: map['reminderMinute'] as int?,
    isMeasurable: map['isMeasurable'] as bool? ?? false,
    targetGoal: (map['targetGoal'] as num?)?.toDouble(),
    goalUnit: map['goalUnit'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    history: (map['history'] as List<dynamic>?)
            ?.map((e) => ActivityRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    historyDates: (map['historyDates'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        const {},
    skippedDates: (map['skippedDates'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        const {},
    orderIndex: map['orderIndex'] as int? ?? 0,
    colorHex: map['colorHex'] as String?,
    iconName: map['iconName'] as String?,
    projectName: map['projectName'] as String?,
    groupName: map['groupName'] as String?,
  );
}
