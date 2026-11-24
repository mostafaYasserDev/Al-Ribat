class ReflectionEditRecord {
  const ReflectionEditRecord({
    required this.editedAt,
    required this.oldText,
    this.oldMood,
  });

  final DateTime editedAt;
  final String oldText;
  final String? oldMood;
}

class ReflectionEntry {
  const ReflectionEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mood,
    this.editHistory = const [],
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? mood;
  final List<ReflectionEditRecord> editHistory;

  ReflectionEntry copyWith({
    String? text,
    String? mood,
    List<ReflectionEditRecord>? editHistory,
  }) {
    return ReflectionEntry(
      id: id,
      text: text ?? this.text,
      createdAt: createdAt,
      mood: mood ?? this.mood,
      editHistory: editHistory ?? this.editHistory,
    );
  }
}
