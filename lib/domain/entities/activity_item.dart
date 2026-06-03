import '../../core/constants/prayer_phase.dart';

enum ActivityRepetition { once, daily, weekly, monthly }

enum ActivityType { beforePrayer, afterPrayer, independent }

class ActivityRecord {
  const ActivityRecord({
    required this.date,
    this.isSkipped = false,
    this.progress = 0.0,
  });

  final String date; // yyyy-MM-dd
  final bool isSkipped;
  final double progress;

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      date: json['date'] as String,
      isSkipped: json['isSkipped'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'isSkipped': isSkipped,
      'progress': progress,
    };
  }
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    this.description,
    this.repetition = ActivityRepetition.daily,
    this.repeatDays = const [],
    this.targetDate,
    this.type = ActivityType.independent,
    this.linkedPrayer,
    this.notificationsEnabled = false,
    this.reminderHour,
    this.reminderMinute,
    this.isMeasurable = false,
    this.targetGoal,
    this.goalUnit,
    required this.createdAt,
    this.history = const [],
    this.historyDates = const {},
    this.skippedDates = const {},
    this.orderIndex = 0,
    this.colorHex,
    this.iconName,
    this.projectName,
    this.groupName,
  });

  final String id;
  final String title;
  final String? description;
  final String? projectName;
  final String? groupName;

  final ActivityRepetition repetition;
  final List<int> repeatDays; // Weekdays for weekly, Month days for monthly
  final String? targetDate; // yyyy-MM-dd for 'once'

  final ActivityType type;
  final PrayerPhase? linkedPrayer;

  final bool notificationsEnabled;
  final int? reminderHour;
  final int? reminderMinute;

  final bool isMeasurable;
  final double? targetGoal;
  final String? goalUnit;

  final DateTime createdAt;
  final List<ActivityRecord> history;

  final Set<String> historyDates;
  final Set<String> skippedDates;

  final int orderIndex;
  final String? colorHex;
  final String? iconName;

  bool isDoneOn(String date) {
    return historyDates.contains(date);
  }

  bool isSkippedOn(String date) {
    return skippedDates.contains(date);
  }

  double getProgressOn(String date) {
    final r = history.where((r) => r.date == date).firstOrNull;
    if (r == null) return 0.0;
    if (r.isSkipped) return 0.0;
    if (!isMeasurable) return 1.0;
    return r.progress;
  }

  ActivityItem copyWith({
    String? id,
    String? title,
    String? description,
    ActivityRepetition? repetition,
    List<int>? repeatDays,
    String? targetDate,
    ActivityType? type,
    PrayerPhase? linkedPrayer,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? isMeasurable,
    double? targetGoal,
    String? goalUnit,
    DateTime? createdAt,
    List<ActivityRecord>? history,
    Set<String>? historyDates,
    Set<String>? skippedDates,
    int? orderIndex,
    String? colorHex,
    String? iconName,
    String? projectName,
    String? groupName,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      repetition: repetition ?? this.repetition,
      repeatDays: repeatDays ?? this.repeatDays,
      targetDate: targetDate ?? this.targetDate,
      type: type ?? this.type,
      linkedPrayer: linkedPrayer ?? this.linkedPrayer,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isMeasurable: isMeasurable ?? this.isMeasurable,
      targetGoal: targetGoal ?? this.targetGoal,
      goalUnit: goalUnit ?? this.goalUnit,
      createdAt: createdAt ?? this.createdAt,
      history: history ?? this.history,
      historyDates: historyDates ?? this.historyDates,
      skippedDates: skippedDates ?? this.skippedDates,
      orderIndex: orderIndex ?? this.orderIndex,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      projectName: projectName ?? this.projectName,
      groupName: groupName ?? this.groupName,
    );
  }
}
