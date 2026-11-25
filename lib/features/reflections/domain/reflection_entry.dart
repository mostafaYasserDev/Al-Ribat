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
  ReflectionEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.title,
    this.isPinned = false,
    this.colorKey,
    String? mood,
    List<String>? moods,
    this.prayerPhaseName,
    this.linkedContextTitle,
    this.editHistory = const [],
  }) : moods = List.unmodifiable(
          moods != null && moods.isNotEmpty
              ? moods.where((m) => m.trim().isNotEmpty).toSet().toList()
              : (mood != null && mood.trim().isNotEmpty ? [mood] : const []),
        );

  final String id;
  final String? title;
  final String text;
  final DateTime createdAt;
  final bool isPinned;
  final String? colorKey;
  final List<String> moods;
  final String? prayerPhaseName;
  final String? linkedContextTitle;
  final List<ReflectionEditRecord> editHistory;

  /// Primary mood (first selected mood) for backward compatibility.
  String? get mood => moods.isEmpty ? null : moods.first;

  ReflectionEntry copyWith({
    String? title,
    bool clearTitle = false,
    String? text,
    bool? isPinned,
    String? colorKey,
    bool clearColor = false,
    String? mood,
    List<String>? moods,
    bool clearMood = false,
    String? prayerPhaseName,
    String? linkedContextTitle,
    bool clearLinkedContext = false,
    List<ReflectionEditRecord>? editHistory,
  }) {
    final List<String> resolvedMoods;
    if (clearMood) {
      resolvedMoods = const [];
    } else if (moods != null) {
      resolvedMoods = moods;
    } else if (mood != null) {
      resolvedMoods = [mood];
    } else {
      resolvedMoods = this.moods;
    }

    return ReflectionEntry(
      id: id,
      title: clearTitle ? null : (title ?? this.title),
      text: text ?? this.text,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
      colorKey: clearColor ? null : (colorKey ?? this.colorKey),
      moods: resolvedMoods,
      prayerPhaseName: prayerPhaseName ?? this.prayerPhaseName,
      linkedContextTitle: clearLinkedContext
          ? null
          : (linkedContextTitle ?? this.linkedContextTitle),
      editHistory: editHistory ?? this.editHistory,
    );
  }
}
