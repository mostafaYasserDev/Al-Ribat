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
  ReflectionEntryModel({
    required super.id,
    required super.text,
    required super.createdAt,
    super.title,
    super.isPinned,
    super.colorKey,
    super.mood,
    super.moods,
    super.prayerPhaseName,
    super.linkedContextTitle,
    super.editHistory,
  });

  factory ReflectionEntryModel.fromEntity(ReflectionEntry entry) {
    return ReflectionEntryModel(
      id: entry.id,
      title: entry.title,
      text: entry.text,
      createdAt: entry.createdAt,
      isPinned: entry.isPinned,
      colorKey: entry.colorKey,
      moods: entry.moods,
      prayerPhaseName: entry.prayerPhaseName,
      linkedContextTitle: entry.linkedContextTitle,
      editHistory: entry.editHistory,
    );
  }

  factory ReflectionEntryModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final rawMoods = (json['moods'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return ReflectionEntryModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      colorKey: json['colorKey'] as String?,
      mood: json['mood'] as String?,
      moods: rawMoods,
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
      if (title != null) 'title': title,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      if (isPinned) 'isPinned': true,
      if (colorKey != null) 'colorKey': colorKey,
      'mood': mood,
      if (moods.isNotEmpty) 'moods': moods,
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
