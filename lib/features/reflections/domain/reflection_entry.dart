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
    this.title,
    this.isPinned = false,
    this.colorKey,
    this.mood,
    this.prayerPhaseName,
    this.linkedContextTitle,
    this.editHistory = const [],
  });

  final String id;
  final String? title;
  final String text;
  final DateTime createdAt;
  final bool isPinned;
  final String? colorKey;
  final String? mood;
  final String? prayerPhaseName;
  final String? linkedContextTitle;
  final List<ReflectionEditRecord> editHistory;

  ReflectionEntry copyWith({
    String? title,
    bool clearTitle = false,
    String? text,
    bool? isPinned,
    String? colorKey,
    bool clearColor = false,
    String? mood,
    bool clearMood = false,
    String? prayerPhaseName,
    String? linkedContextTitle,
    bool clearLinkedContext = false,
    List<ReflectionEditRecord>? editHistory,
  }) {
    return ReflectionEntry(
      id: id,
      title: clearTitle ? null : (title ?? this.title),
      text: text ?? this.text,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
      colorKey: clearColor ? null : (colorKey ?? this.colorKey),
      mood: clearMood ? null : (mood ?? this.mood),
      prayerPhaseName: prayerPhaseName ?? this.prayerPhaseName,
      linkedContextTitle: clearLinkedContext
          ? null
          : (linkedContextTitle ?? this.linkedContextTitle),
      editHistory: editHistory ?? this.editHistory,
    );
  }
}
