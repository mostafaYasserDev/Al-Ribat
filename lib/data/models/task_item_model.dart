import 'dart:convert';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/task_item.dart';

class TaskItemModel extends TaskItem {
  const TaskItemModel({
    required super.id,
    required super.title,
    required super.linkedPrayer,
    required super.type,
    required super.isCompleted,
    required super.orderIndex,
    super.description,
    required super.createdAt,
    super.startMinutesFromMidnight,
    super.endMinutesFromMidnight,
    super.reminderMinutesFromMidnight,
  });

  factory TaskItemModel.fromEntity(TaskItem entity) {
    return TaskItemModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      linkedPrayer: entity.linkedPrayer,
      type: entity.type,
      isCompleted: entity.isCompleted,
      orderIndex: entity.orderIndex,
      createdAt: entity.createdAt,
      startMinutesFromMidnight: entity.startMinutesFromMidnight,
      endMinutesFromMidnight: entity.endMinutesFromMidnight,
      reminderMinutesFromMidnight: entity.reminderMinutesFromMidnight,
    );
  }

  factory TaskItemModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return TaskItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      linkedPrayer: PrayerPhase.values.firstWhere(
        (e) => e.name == json['linkedPrayer'],
      ),
      type: TaskType.values.firstWhere((e) => e.name == json['type']),
      isCompleted: json['isCompleted'] as bool,
      orderIndex: json['orderIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startMinutesFromMidnight: json['startMinutesFromMidnight'] as int?,
      endMinutesFromMidnight: json['endMinutesFromMidnight'] as int?,
      reminderMinutesFromMidnight: json['reminderMinutesFromMidnight'] as int?,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'description': description,
      'linkedPrayer': linkedPrayer.name,
      'type': type.name,
      'isCompleted': isCompleted,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
      'startMinutesFromMidnight': startMinutesFromMidnight,
      'endMinutesFromMidnight': endMinutesFromMidnight,
      'reminderMinutesFromMidnight': reminderMinutesFromMidnight,
    });
  }
}
