import 'dart:convert';

import '../domain/work_session_item.dart';

class WorkSessionItemModel extends WorkSessionItem {
  const WorkSessionItemModel({
    required super.id,
    required super.name,
    required super.plannedMinutes,
    required super.startedAt,
    required super.endedAt,
    super.completed = true,
    super.linkedActivityTitle,
    super.sessionMode,
    super.reflection,
  });

  factory WorkSessionItemModel.fromEntity(WorkSessionItem e) {
    return WorkSessionItemModel(
      id: e.id,
      name: e.name,
      plannedMinutes: e.plannedMinutes,
      startedAt: e.startedAt,
      endedAt: e.endedAt,
      completed: e.completed,
      linkedActivityTitle: e.linkedActivityTitle,
      sessionMode: e.sessionMode,
      reflection: e.reflection,
    );
  }

  factory WorkSessionItemModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return WorkSessionItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      plannedMinutes: json['plannedMinutes'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      completed: json['completed'] as bool? ?? true,
      linkedActivityTitle: json['linkedActivityTitle'] as String?,
      sessionMode: json['sessionMode'] as String?,
      reflection: json['reflection'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'plannedMinutes': plannedMinutes,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'completed': completed,
      'linkedActivityTitle': linkedActivityTitle,
      'sessionMode': sessionMode,
      'reflection': reflection,
    });
  }
}
