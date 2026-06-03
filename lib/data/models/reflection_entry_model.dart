import 'dart:convert';

import '../../domain/entities/reflection_entry.dart';

class ReflectionEntryModel extends ReflectionEntry {
  const ReflectionEntryModel({
    required super.id,
    required super.text,
    required super.createdAt,
    super.mood,
  });

  factory ReflectionEntryModel.fromEntity(ReflectionEntry entry) {
    return ReflectionEntryModel(
      id: entry.id,
      text: entry.text,
      createdAt: entry.createdAt,
      mood: entry.mood,
    );
  }

  factory ReflectionEntryModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return ReflectionEntryModel(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mood: json['mood'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'mood': mood,
    });
  }
}
