import '../../core/constants/prayer_phase.dart';

class StatsSnapshot {
  const StatsSnapshot({
    required this.weeklyCompleted,
    required this.monthlyCompleted,
    required this.byPhase,
    required this.reflectionsThisMonth,
    required this.workSessionsThisWeek,
    required this.focusMinutesThisWeek,
    required this.habitsMarkedThisWeek,
    required this.feedbackLine,
  });

  final int weeklyCompleted;
  final int monthlyCompleted;
  final Map<PrayerPhase, int> byPhase;
  final int reflectionsThisMonth;
  final int workSessionsThisWeek;
  final int focusMinutesThisWeek;
  final int habitsMarkedThisWeek;
  final String feedbackLine;
}
