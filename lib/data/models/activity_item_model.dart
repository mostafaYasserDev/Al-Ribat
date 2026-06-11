import 'dart:convert';
import '../../domain/entities/activity_item.dart';
import '../../core/constants/prayer_phase.dart';

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

  factory ActivityItemModel.fromEntity(ActivityItem entity) {
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

  factory ActivityItemModel.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return ActivityItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      repetition: ActivityRepetition.values.firstWhere(
        (e) => e.name == map['repetition'],
        orElse: () => ActivityRepetition.daily,
      ),
      repeatDays: (map['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
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
      historyDates: (map['historyDates'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? const {},
      skippedDates: (map['skippedDates'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? const {},
      orderIndex: map['orderIndex'] as int? ?? 0,
      colorHex: map['colorHex'] as String?,
      iconName: map['iconName'] as String?,
      projectName: map['projectName'] as String?,
      groupName: map['groupName'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'description': description,
      'repetition': repetition.name,
      'repeatDays': repeatDays,
      'targetDate': targetDate,
      'endDate': endDate,
      'type': type.name,
      'linkedPrayer': linkedPrayer?.name,
      'notificationsEnabled': notificationsEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'isMeasurable': isMeasurable,
      'targetGoal': targetGoal,
      'goalUnit': goalUnit,
      'createdAt': createdAt.toIso8601String(),
      'history': history.map((e) => e.toJson()).toList(),
      'historyDates': historyDates.toList(),
      'skippedDates': skippedDates.toList(),
      'orderIndex': orderIndex,
      'colorHex': colorHex,
      'iconName': iconName,
      'projectName': projectName,
      'groupName': groupName,
    });
  }
}
