/// [repeatWeekdays]: `DateTime.monday`…`DateTime.sunday` (1–7). Empty = every day.
class HabitItem {
  const HabitItem({
    required this.id,
    required this.title,
    this.description,
    required this.reminderHour,
    required this.reminderMinute,
    required this.notificationsEnabled,
    required this.createdAt,
    this.repeatWeekdays = const [],
    this.lastMarkedDoneDate,
  });

  final String id;
  final String title;
  final String? description;
  final int reminderHour;
  final int reminderMinute;
  final bool notificationsEnabled;
  final DateTime createdAt;

  /// Empty or contains all seven → daily. Otherwise only selected weekdays.
  final List<int> repeatWeekdays;

  /// `yyyy-MM-dd` when user tapped «تم اليوم».
  final String? lastMarkedDoneDate;

  /// Weekdays for notifications (1=Mon … 7=Sun).
  List<int> get effectiveWeekdays {
    if (repeatWeekdays.isEmpty) {
      return const [1, 2, 3, 4, 5, 6, 7];
    }
    final s = repeatWeekdays.toSet().toList()..sort();
    return s;
  }

  bool get isDoneToday {
    final n = DateTime.now();
    final today =
        '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    return lastMarkedDoneDate == today;
  }

  HabitItem copyWith({
    String? id,
    String? title,
    String? description,
    int? reminderHour,
    int? reminderMinute,
    bool? notificationsEnabled,
    DateTime? createdAt,
    List<int>? repeatWeekdays,
    String? lastMarkedDoneDate,
    bool clearLastMarked = false,
  }) {
    return HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      lastMarkedDoneDate:
          clearLastMarked ? null : (lastMarkedDoneDate ?? this.lastMarkedDoneDate),
    );
  }
}
