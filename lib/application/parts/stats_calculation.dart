part of '../providers.dart';

StatsSnapshot _buildStatsSnapshot(Ref ref) {
  final activities =
      ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
  final reflections =
      ref.watch(reflectionsProvider).valueOrNull ?? const <ReflectionEntry>[];
  final workSessions =
      ref.watch(workSessionsProvider).valueOrNull ?? const <WorkSessionItem>[];

  final now = DateTime.now();
  final weekStart = weekStartSaturday(now);
  final monthStart = DateTime(now.year, now.month, 1);

  // Count how many activities are done within the last week
  int weekly = 0;
  int monthly = 0;
  final byPhase = <PrayerPhase, int>{
    for (final p in PrayerPhase.values) p: 0,
  };

  final skipsByActivity = <String, int>{};
  int totalDueThisWeek = 0;
  int totalDoneThisWeek = 0;

  for (final act in activities) {
    // Calculate skipped and done for this week
    int actSkips = 0;
    for (final history in act.history) {
      final historyDate = DateTime.tryParse(history.date);
      if (historyDate == null) continue;
      final normalizedHistory = DateTime(
        historyDate.year,
        historyDate.month,
        historyDate.day,
      );

      if (!normalizedHistory.isBefore(weekStart)) {
        totalDueThisWeek++;
        if (history.isSkipped) {
          actSkips++;
        } else {
          weekly++;
          totalDoneThisWeek++;
        }
      }

      if (!normalizedHistory.isBefore(monthStart) && !history.isSkipped) {
        monthly++;
      }

      if (!history.isSkipped && act.linkedPrayer != null) {
        byPhase[act.linkedPrayer!] = (byPhase[act.linkedPrayer!] ?? 0) + 1;
      }
    }
    if (actSkips > 0) {
      skipsByActivity[act.title] = actSkips;
    }
  }

  final productivePhase = _mostProductivePhase(byPhase);
  final mostSkipped = _mostSkippedActivity(skipsByActivity);

  final completionRateThisWeek =
      totalDueThisWeek == 0 ? 0.0 : totalDoneThisWeek / totalDueThisWeek;

  final reflectionsThisMonth =
      reflections.where((e) => !e.createdAt.isBefore(monthStart)).length;

  final wsWeek =
      workSessions.where((e) => !e.startedAt.isBefore(weekStart)).toList();
  final workSessionsThisWeek = wsWeek.where((e) => e.completed).length;
  final focusMinutesThisWeek = wsWeek.where((e) => e.completed).fold<int>(
      0, (a, b) => a + b.actualMinutes.clamp(0, b.plannedMinutes + 5));

  return StatsSnapshot(
    weeklyCompleted: weekly,
    monthlyCompleted: monthly,
    byPhase: byPhase,
    reflectionsThisMonth: reflectionsThisMonth,
    workSessionsThisWeek: workSessionsThisWeek,
    focusMinutesThisWeek: focusMinutesThisWeek,
    habitsMarkedThisWeek: weekly, // Merged
    feedbackLine: _statsFeedback(
      activitiesWeek: weekly,
      focusMin: focusMinutesThisWeek,
    ),
    mostProductivePhase: productivePhase,
    mostSkippedActivity: mostSkipped,
    completionRateThisWeek: completionRateThisWeek,
  );
}
