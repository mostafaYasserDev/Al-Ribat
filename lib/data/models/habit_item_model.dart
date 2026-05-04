import 'dart:convert';

import '../../domain/entities/habit_item.dart';

class HabitItemModel extends HabitItem {
  const HabitItemModel({
    required super.id,
    required super.title,
    super.description,
    required super.reminderHour,
    required super.reminderMinute,
    required super.notificationsEnabled,
    required super.createdAt,
    super.repeatWeekdays,
    super.lastMarkedDoneDate,
  });

  factory HabitItemModel.fromEntity(HabitItem entity) {
    return HabitItemModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      reminderHour: entity.reminderHour,
      reminderMinute: entity.reminderMinute,
      notificationsEnabled: entity.notificationsEnabled,
      createdAt: entity.createdAt,
      repeatWeekdays: entity.repeatWeekdays,
      lastMarkedDoneDate: entity.lastMarkedDoneDate,
    );
  }

  factory HabitItemModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final rawDays = json['repeatWeekdays'] as List<dynamic>?;
    final days = rawDays == null
        ? const <int>[]
        : rawDays.map((e) => (e as num).toInt()).where((e) => e >= 1 && e <= 7).toList();
    return HabitItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      reminderHour: json['reminderHour'] as int? ?? 8,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      repeatWeekdays: days,
      lastMarkedDoneDate: json['lastMarkedDoneDate'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'description': description,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'repeatWeekdays': repeatWeekdays,
      'lastMarkedDoneDate': lastMarkedDoneDate,
    });
  }
}
