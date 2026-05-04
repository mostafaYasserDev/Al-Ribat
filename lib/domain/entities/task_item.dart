import '../../core/constants/prayer_phase.dart';

enum TaskType { before, after }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.linkedPrayer,
    required this.type,
    required this.isCompleted,
    required this.orderIndex,
    this.description,
    required this.createdAt,
    this.startMinutesFromMidnight,
    this.endMinutesFromMidnight,
    this.reminderMinutesFromMidnight,
  });

  final String id;
  final String title;
  final String? description;
  final PrayerPhase linkedPrayer;
  final TaskType type;
  final bool isCompleted;
  final int orderIndex;
  final DateTime createdAt;

  /// Minutes from midnight on [createdAt]'s calendar day; inclusive start of window.
  final int? startMinutesFromMidnight;

  /// Exclusive end of planned window (same convention as typical ranges).
  final int? endMinutesFromMidnight;

  /// Optional reminder time for today (minutes from midnight).
  final int? reminderMinutesFromMidnight;

  /// When both bounds are set, returns whether [now] falls inside today's window.
  bool isWithinPlannedWindow(DateTime now) {
    if (startMinutesFromMidnight == null || endMinutesFromMidnight == null) {
      return true;
    }
    final start = startMinutesFromMidnight!;
    final end = endMinutesFromMidnight!;
    final m = now.hour * 60 + now.minute;
    if (end > start) {
      return m >= start && m < end;
    }
    if (end == start) {
      return false;
    }
    return m >= start || m < end;
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    PrayerPhase? linkedPrayer,
    TaskType? type,
    bool? isCompleted,
    int? orderIndex,
    DateTime? createdAt,
    int? startMinutesFromMidnight,
    int? endMinutesFromMidnight,
    int? reminderMinutesFromMidnight,
    bool clearTimeWindow = false,
    bool clearReminder = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      linkedPrayer: linkedPrayer ?? this.linkedPrayer,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      startMinutesFromMidnight:
          clearTimeWindow ? null : (startMinutesFromMidnight ?? this.startMinutesFromMidnight),
      endMinutesFromMidnight:
          clearTimeWindow ? null : (endMinutesFromMidnight ?? this.endMinutesFromMidnight),
      reminderMinutesFromMidnight: clearReminder
          ? null
          : (reminderMinutesFromMidnight ?? this.reminderMinutesFromMidnight),
    );
  }
}
