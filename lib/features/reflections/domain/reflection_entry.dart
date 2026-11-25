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
    this.prayerPhaseName,
    this.linkedContextTitle,
    this.editHistory = const [],
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? mood;
  final String? prayerPhaseName;
  final String? linkedContextTitle;
  final List<ReflectionEditRecord> editHistory;

  ReflectionEntry copyWith({
    String? text,
    String? mood,
    bool clearMood = false,
    String? prayerPhaseName,
    String? linkedContextTitle,
    bool clearLinkedContext = false,
    List<ReflectionEditRecord>? editHistory,
  }) {
    return ReflectionEntry(
      id: id,
      text: text ?? this.text,
      createdAt: createdAt,
      mood: clearMood ? null : (mood ?? this.mood),
      prayerPhaseName: prayerPhaseName ?? this.prayerPhaseName,
      linkedContextTitle: clearLinkedContext
          ? null
          : (linkedContextTitle ?? this.linkedContextTitle),
      editHistory: editHistory ?? this.editHistory,
    );
  }
}
