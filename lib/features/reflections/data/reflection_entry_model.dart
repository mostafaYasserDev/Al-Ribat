import 'dart:convert';

import '../domain/reflection_entry.dart';

class ReflectionEditRecordModel extends ReflectionEditRecord {
  const ReflectionEditRecordModel({
    required super.editedAt,
    required super.oldText,
    super.oldMood,
  });

  factory ReflectionEditRecordModel.fromJson(Map<String, dynamic> json) {
    return ReflectionEditRecordModel(
      editedAt: DateTime.parse(json['editedAt'] as String),
      oldText: json['oldText'] as String,
      oldMood: json['oldMood'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'editedAt': editedAt.toIso8601String(),
      'oldText': oldText,
      'oldMood': oldMood,
    };
  }
}

class ReflectionEntryModel extends ReflectionEntry {
  const ReflectionEntryModel({
    required super.id,
    required super.text,
    required super.createdAt,
    super.mood,
    super.prayerPhaseName,
    super.linkedContextTitle,
    super.editHistory,
  });

  factory ReflectionEntryModel.fromEntity(ReflectionEntry entry) {
    return ReflectionEntryModel(
      id: entry.id,
      text: entry.text,
      createdAt: entry.createdAt,
      mood: entry.mood,
      prayerPhaseName: entry.prayerPhaseName,
      linkedContextTitle: entry.linkedContextTitle,
      editHistory: entry.editHistory,
    );
  }

  factory ReflectionEntryModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return ReflectionEntryModel(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mood: json['mood'] as String?,
      prayerPhaseName: json['prayerPhaseName'] as String?,
      linkedContextTitle: json['linkedContextTitle'] as String?,
      editHistory: (json['editHistory'] as List<dynamic>?)
              ?.map((e) =>
                  ReflectionEditRecordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'mood': mood,
      if (prayerPhaseName != null) 'prayerPhaseName': prayerPhaseName,
      if (linkedContextTitle != null) 'linkedContextTitle': linkedContextTitle,
      'editHistory': editHistory
          .map((e) => ReflectionEditRecordModel(
                editedAt: e.editedAt,
                oldText: e.oldText,
                oldMood: e.oldMood,
              ).toMap())
          .toList(),
    });
  }
}
