part of '../providers.dart';

StatsSnapshot _buildStatsSnapshot(Ref ref) {
  final activities =
      ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
  final reflections =
      ref.watch(reflectionsProvider).valueOrNull ?? const <ReflectionEntry>[];
  final workSessions =
      ref.watch(workSessionsProvider).valueOrNull ?? const <WorkSessionItem>[];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = weekStartSaturday(today);
  final monthStart = DateTime(now.year, now.month, 1);

  int weekly = 0;
  int monthly = 0;
  int independentCompleted = 0;
  final byPhase = <PrayerPhase, int>{
    for (final p in PrayerPhase.values) p: 0,
  };
  final weeklyDailyCounts = List<int>.filled(7, 0);

  final skipsByActivity = <String, int>{};
  int totalDueThisWeek = 0;
  int totalDoneThisWeek = 0;

  for (final act in activities) {
    int actSkips = 0;
    for (final history in act.history) {
      final historyDate = DateTime.tryParse(history.date);
      if (historyDate == null) continue;
      final normalizedHistory = DateTime(
        historyDate.year,
        historyDate.month,
        historyDate.day,
      );

      if (!normalizedHistory.isBefore(weekStart) &&
          !normalizedHistory.isAfter(today)) {
        if (history.isSkipped) {
          actSkips++;
        } else {
          weekly++;
          final dayIndex = normalizedHistory.difference(weekStart).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyDailyCounts[dayIndex]++;
          }
        }
      }

      if (!normalizedHistory.isBefore(monthStart) && !history.isSkipped) {
        monthly++;
      }

      if (!history.isSkipped) {
        if (act.linkedPrayer != null) {
          byPhase[act.linkedPrayer!] = (byPhase[act.linkedPrayer!] ?? 0) + 1;
        } else {
          independentCompleted++;
        }
      }
    }

    // Accurate weekly commitment: compare due days from Saturday..today vs done
    for (var d = weekStart;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      if (!activityVisibleOnDate(act, d)) continue;
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      if (act.isSkippedOn(dateStr)) continue;
      totalDueThisWeek++;
      if (act.isDoneOn(dateStr)) {
        totalDoneThisWeek++;
      }
    }

    if (actSkips > 0) {
      skipsByActivity[act.title] = actSkips;
    }
  }

  final productivePhase = _mostProductivePhase(byPhase);
  final mostSkipped = _mostSkippedActivity(skipsByActivity);

  final completionRateThisWeek = totalDueThisWeek == 0
      ? 0.0
      : (totalDoneThisWeek / totalDueThisWeek).clamp(0.0, 1.0);

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
    habitsMarkedThisWeek: weekly,
    feedbackLine: _statsFeedback(
      activitiesWeek: weekly,
      focusMin: focusMinutesThisWeek,
    ),
    mostProductivePhase: productivePhase,
    mostSkippedActivity: mostSkipped,
    completionRateThisWeek: completionRateThisWeek,
    weeklyDailyCounts: weeklyDailyCounts,
    independentCompleted: independentCompleted,
    totalDueThisWeek: totalDueThisWeek,
    totalDoneThisWeek: totalDoneThisWeek,
  );
}
