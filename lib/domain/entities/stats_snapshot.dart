import '../../core/constants/prayer_phase.dart';

class StatsSnapshot {
  const StatsSnapshot({
    required this.weeklyCompleted,
    required this.monthlyCompleted,
    required this.byPhase,
    required this.reflectionsThisMonth,
    required this.workSessionsThisWeek,
    required this.focusMinutesThisWeek,
    this.habitsMarkedThisWeek = 0,
    required this.feedbackLine,
    this.mostProductivePhase,
    this.mostSkippedActivity,
    this.completionRateThisWeek = 0.0,
    this.weeklyDailyCounts = const [0, 0, 0, 0, 0, 0, 0],
    this.independentCompleted = 0,
    this.totalDueThisWeek = 0,
    this.totalDoneThisWeek = 0,
  });

  final int weeklyCompleted;
  final int monthlyCompleted;
  final Map<PrayerPhase, int> byPhase;
  final int reflectionsThisMonth;
  final int workSessionsThisWeek;
  final int focusMinutesThisWeek;
  final int habitsMarkedThisWeek;
  final String feedbackLine;
  final PrayerPhase? mostProductivePhase;
  final String? mostSkippedActivity;
  final double completionRateThisWeek;

  /// Completed activities per day from Saturday (index 0) to Friday (index 6).
  final List<int> weeklyDailyCounts;
  final int independentCompleted;
  final int totalDueThisWeek;
  final int totalDoneThisWeek;
}
