part of '../providers.dart';

final streakProvider = FutureProvider<int>((ref) async {
  final box = Hive.box<String>('meta_box');
  final streak = int.tryParse(box.get('streak_count') ?? '0') ?? 0;
  final lastDate = box.get('streak_last_date');
  if (lastDate == null || streak == 0) return 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final last = DateTime.tryParse(lastDate);
  if (last == null) return 0;
  final lastDay = DateTime(last.year, last.month, last.day);
  final yesterday = DateTime(today.year, today.month, today.day - 1);

  if (lastDay == today || lastDay == yesterday) {
    return streak;
  }

  // Streak broken: reset to 0
  await box.put('streak_count', '0');
  return 0;
});

Future<void> updateStreakIfNeeded(dynamic ref, [String? dateStr]) async {
  final box = Hive.box<String>('meta_box');
  final targetDateStr =
      dateStr ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

  final targetDate = DateTime.tryParse(targetDateStr);
  if (targetDate == null) return;

  final normalizedTarget =
      DateTime(targetDate.year, targetDate.month, targetDate.day);
  final previousDay = DateTime(
    normalizedTarget.year,
    normalizedTarget.month,
    normalizedTarget.day - 1,
  );
  final previousDateStr = DateFormat('yyyy-MM-dd').format(previousDay);

  final lastDateStr = box.get('streak_last_date');
  var streak = int.tryParse(box.get('streak_count') ?? '0') ?? 0;

  if (lastDateStr == targetDateStr) return;
  if (lastDateStr == previousDateStr) {
    streak += 1;
  } else {
    if (lastDateStr != null) {
      final last = DateTime.tryParse(lastDateStr);
      if (last != null &&
          DateTime(last.year, last.month, last.day).isAfter(normalizedTarget)) {
        return;
      }
    }
    streak = 1;
  }
  await box.put('streak_count', '$streak');
  await box.put('streak_last_date', targetDateStr);
  try {
    ref.invalidate(streakProvider);
  } catch (_) {}
}
