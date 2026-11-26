part of '../providers.dart';

class ProjectStatsSnapshot {
  const ProjectStatsSnapshot({
    required this.projectName,
    required this.totalActivities,
    required this.weeklyCompleted,
    required this.monthlyCompleted,
    required this.totalDueThisWeek,
    required this.totalDoneThisWeek,
    required this.completionRateThisWeek,
    required this.weeklyDailyCounts,
    required this.byGroup,
    this.mostSkippedTask,
  });

  final String projectName;
  final int totalActivities;
  final int weeklyCompleted;
  final int monthlyCompleted;
  final int totalDueThisWeek;
  final int totalDoneThisWeek;
  final double completionRateThisWeek;
  final List<int> weeklyDailyCounts;
  final Map<String, int> byGroup;
  final String? mostSkippedTask;
}

class ActivityStatsSnapshot {
  const ActivityStatsSnapshot({
    required this.activity,
    required this.weeklyCompleted,
    required this.monthlyCompleted,
    required this.totalCompletedAllTime,
    required this.totalSkippedAllTime,
    required this.totalDueThisWeek,
    required this.totalDoneThisWeek,
    required this.completionRateThisWeek,
    required this.weeklyDailyCounts,
    required this.weeklyProgressTotal,
  });

  final ActivityItem activity;
  final int weeklyCompleted;
  final int monthlyCompleted;
  final int totalCompletedAllTime;
  final int totalSkippedAllTime;
  final int totalDueThisWeek;
  final int totalDoneThisWeek;
  final double completionRateThisWeek;
  final List<int> weeklyDailyCounts;
  final double weeklyProgressTotal;
}

ProjectStatsSnapshot buildProjectStats(
  String projectName,
  List<ActivityItem> activities, {
  DateTime? referenceDate,
}) {
  final now = referenceDate ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = weekStartSaturday(today);
  final monthStart = DateTime(now.year, now.month, 1);

  final projectActs =
      activities.where((a) => a.projectName?.trim() == projectName).toList();

  int weekly = 0;
  int monthly = 0;
  int totalDueThisWeek = 0;
  int totalDoneThisWeek = 0;
  final weeklyDailyCounts = List<int>.filled(7, 0);
  final byGroup = <String, int>{};
  final skipsByTask = <String, int>{};

  for (final act in projectActs) {
    final group = (act.groupName?.trim().isNotEmpty ?? false)
        ? act.groupName!.trim()
        : 'عام';
    byGroup.putIfAbsent(group, () => 0);

    int skips = 0;
    for (final h in act.history) {
      final d = DateTime.tryParse(h.date);
      if (d == null) continue;
      final norm = DateTime(d.year, d.month, d.day);

      if (!norm.isBefore(weekStart) && !norm.isAfter(today)) {
        if (h.isSkipped) {
          skips++;
        } else {
          weekly++;
          final idx = norm.difference(weekStart).inDays;
          if (idx >= 0 && idx < 7) weeklyDailyCounts[idx]++;
        }
      }
      if (!norm.isBefore(monthStart) && !h.isSkipped) {
        monthly++;
      }
      if (!h.isSkipped) {
        byGroup[group] = (byGroup[group] ?? 0) + 1;
      }
    }

    for (var d = weekStart;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      if (!activityVisibleOnDate(act, d)) continue;
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      if (act.isSkippedOn(dateStr)) continue;
      totalDueThisWeek++;
      if (act.isDoneOn(dateStr)) totalDoneThisWeek++;
    }

    if (skips > 0) skipsByTask[act.title] = skips;
  }

  final rate = totalDueThisWeek == 0
      ? 0.0
      : (totalDoneThisWeek / totalDueThisWeek).clamp(0.0, 1.0);

  return ProjectStatsSnapshot(
    projectName: projectName,
    totalActivities: projectActs.length,
    weeklyCompleted: weekly,
    monthlyCompleted: monthly,
    totalDueThisWeek: totalDueThisWeek,
    totalDoneThisWeek: totalDoneThisWeek,
    completionRateThisWeek: rate,
    weeklyDailyCounts: weeklyDailyCounts,
    byGroup: byGroup,
    mostSkippedTask: _mostSkippedActivity(skipsByTask),
  );
}

ActivityStatsSnapshot buildActivityStats(
  ActivityItem activity, {
  DateTime? referenceDate,
}) {
  final now = referenceDate ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = weekStartSaturday(today);
  final monthStart = DateTime(now.year, now.month, 1);

  int weekly = 0;
  int monthly = 0;
  int totalDone = 0;
  int totalSkipped = 0;
  int totalDueThisWeek = 0;
  int totalDoneThisWeek = 0;
  double weeklyProgress = 0;
  final weeklyDailyCounts = List<int>.filled(7, 0);

  for (final h in activity.history) {
    if (h.isSkipped) {
      totalSkipped++;
    } else {
      totalDone++;
    }
    final d = DateTime.tryParse(h.date);
    if (d == null) continue;
    final norm = DateTime(d.year, d.month, d.day);

    if (!norm.isBefore(weekStart) && !norm.isAfter(today) && !h.isSkipped) {
      weekly++;
      weeklyProgress += h.progress;
      final idx = norm.difference(weekStart).inDays;
      if (idx >= 0 && idx < 7) weeklyDailyCounts[idx]++;
    }
    if (!norm.isBefore(monthStart) && !h.isSkipped) {
      monthly++;
    }
  }

  for (var d = weekStart;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))) {
    if (!activityVisibleOnDate(activity, d)) continue;
    final dateStr = DateFormat('yyyy-MM-dd').format(d);
    if (activity.isSkippedOn(dateStr)) continue;
    totalDueThisWeek++;
    if (activity.isDoneOn(dateStr)) totalDoneThisWeek++;
  }

  final rate = totalDueThisWeek == 0
      ? 0.0
      : (totalDoneThisWeek / totalDueThisWeek).clamp(0.0, 1.0);

  return ActivityStatsSnapshot(
    activity: activity,
    weeklyCompleted: weekly,
    monthlyCompleted: monthly,
    totalCompletedAllTime: totalDone,
    totalSkippedAllTime: totalSkipped,
    totalDueThisWeek: totalDueThisWeek,
    totalDoneThisWeek: totalDoneThisWeek,
    completionRateThisWeek: rate,
    weeklyDailyCounts: weeklyDailyCounts,
    weeklyProgressTotal: weeklyProgress,
  );
}
