import 'dart:convert';

import '../../domain/entities/work_session_item.dart';

class WorkSessionItemModel extends WorkSessionItem {
  const WorkSessionItemModel({
    required super.id,
    required super.name,
    required super.plannedMinutes,
    required super.startedAt,
    super.endedAt,
    required super.completed,
  });

  factory WorkSessionItemModel.fromEntity(WorkSessionItem e) {
    return WorkSessionItemModel(
      id: e.id,
      name: e.name,
      plannedMinutes: e.plannedMinutes,
      startedAt: e.startedAt,
      endedAt: e.endedAt,
      completed: e.completed,
    );
  }

  factory WorkSessionItemModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return WorkSessionItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      plannedMinutes: json['plannedMinutes'] as int? ?? 25,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null ? null : DateTime.parse(json['endedAt'] as String),
      completed: json['completed'] as bool? ?? false,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'plannedMinutes': plannedMinutes,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'completed': completed,
    });
  }
}
