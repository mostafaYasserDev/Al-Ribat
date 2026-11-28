import '../../../core/activity_schedule.dart';
import '../../../core/constants/prayer_phase.dart';
import '../../activities/domain/activity_item.dart';
import '../../focus/domain/work_session_item.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../reflections/domain/reflection_entry.dart';
import '../domain/ai_context_snapshot.dart';
import '../domain/ai_permissions.dart';
import 'local_reflection_summarizer.dart';

class LocalContextBuilder {
  const LocalContextBuilder({
    LocalReflectionSummarizer summarizer = const LocalReflectionSummarizer(),
  }) : _summarizer = summarizer;

  final LocalReflectionSummarizer _summarizer;

  AiContextSnapshot build({
    required AiPermissions permissions,
    required List<ActivityItem> activities,
    required PrayerSchedule? prayerSchedule,
    required List<ReflectionEntry> reflections,
    required List<WorkSessionItem> workSessions,
    bool reflectionSummaryApproved = false,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final todayStr = _formatDate(current);

    final dueTodayList =
        activities.where((a) => activityVisibleOnDate(a, current)).toList();
    final completedTodayCount =
        dueTodayList.where((a) => a.isDoneOn(todayStr)).length;

    final activitiesLines = permissions.allowActivities
        ? _buildActivityLines(dueTodayList, activities, todayStr)
        : const <String>[];

    final prayerLines = <String>[];
    final prayerSlots = <PrayerSlotInfo>[];
    if (permissions.allowPrayer && prayerSchedule != null) {
      for (final p in prayerSchedule.today) {
        prayerLines.add('${p.phase.arabicName}: ${_formatTime(p.time)}');
      }
      prayerSlots.addAll(
        _buildPrayerSlots(
          prayerSchedule,
          permissions.allowActivities ? dueTodayList : const [],
        ),
      );
    }

    final projectLines = permissions.allowProjects
        ? _buildProjectLines(activities, todayStr)
        : const <String>[];

    final fullReflectionLines = permissions.allowReflections
        ? _buildFullReflectionLines(reflections)
        : const <String>[];

    final ReflectionSummary? reflectionSummary =
        (!permissions.allowReflections &&
                permissions.allowReflectionSummary &&
                reflectionSummaryApproved)
            ? _summarizer.summarize(reflections, now: current)
            : null;

    final weekAgo = current.subtract(const Duration(days: 7));
    final recentSessions = workSessions
        .where((s) => s.startedAt.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final totalFocusMinutesWeek = permissions.allowWorkSessions
        ? recentSessions.fold<int>(0, (sum, s) => sum + s.actualMinutes)
        : 0;
    final workSessionLines = permissions.allowWorkSessions
        ? recentSessions
            .take(8)
            .map((s) => '${s.name} (${s.actualMinutes} د)')
            .toList()
        : const <String>[];

    return AiContextSnapshot(
      activitiesLines: activitiesLines,
      completedToday: permissions.allowActivities ? completedTodayCount : 0,
      dueToday: permissions.allowActivities ? dueTodayList.length : 0,
      prayerLines: prayerLines,
      prayerSlots: prayerSlots,
      projectLines: projectLines,
      fullReflectionLines: fullReflectionLines,
      reflectionSummary: reflectionSummary,
      workSessionLines: workSessionLines,
      totalFocusMinutesWeek: totalFocusMinutesWeek,
    );
  }

  List<String> _buildActivityLines(
    List<ActivityItem> dueToday,
    List<ActivityItem> all,
    String todayStr,
  ) {
    final source = dueToday.isNotEmpty ? dueToday : all;
    return source.take(25).map((a) {
      final done = a.isDoneOn(todayStr) ? '✓' : '○';
      final prayerTag = a.linkedPrayer != null
          ? ' (${a.type == ActivityType.beforePrayer ? "قبل" : "بعد"} ${a.linkedPrayer!.arabicName})'
          : '';
      final projTag = a.projectName != null ? ' [مشروع: ${a.projectName}]' : '';
      return '$done ${a.title}$prayerTag$projTag';
    }).toList();
  }

  List<PrayerSlotInfo> _buildPrayerSlots(
    PrayerSchedule schedule,
    List<ActivityItem> dueToday,
  ) {
    final prayers = schedule.today;
    if (prayers.length < 2) return const [];
    final slots = <PrayerSlotInfo>[];
    for (var i = 0; i < prayers.length; i++) {
      final current = prayers[i];
      final nextTime = i + 1 < prayers.length
          ? prayers[i + 1].time
          : schedule.tomorrowFajr.time;
      final duration = nextTime.difference(current.time).inMinutes;
      final slotTasks = dueToday.where((a) {
        if (a.linkedPrayer == current.phase &&
            a.type == ActivityType.afterPrayer) {
          return true;
        }
        if (i + 1 < prayers.length &&
            a.linkedPrayer == prayers[i + 1].phase &&
            a.type == ActivityType.beforePrayer) {
          return true;
        }
        return false;
      }).toList();
      final nextLabel =
          i + 1 < prayers.length ? prayers[i + 1].phase.arabicName : 'فجر الغد';
      slots.add(
        PrayerSlotInfo(
          label: 'بين ${current.phase.arabicName} و$nextLabel',
          durationMinutes: duration < 0 ? 0 : duration,
          taskCount: slotTasks.length,
          taskTitles: slotTasks.map((t) => t.title).toList(),
        ),
      );
    }
    return slots;
  }

  List<String> _buildProjectLines(
    List<ActivityItem> activities,
    String todayStr,
  ) {
    final byProject = <String, List<ActivityItem>>{};
    for (final a in activities) {
      final name = a.projectName?.trim();
      if (name != null && name.isNotEmpty) {
        (byProject[name] ??= []).add(a);
      }
    }
    return byProject.entries.map((e) {
      final done = e.value.where((a) => a.isDoneOn(todayStr)).length;
      return '${e.key}: ${e.value.length} مهام (أُنجز اليوم $done)';
    }).toList();
  }

  List<String> _buildFullReflectionLines(List<ReflectionEntry> reflections) {
    final sorted = [...reflections]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(6).map((r) {
      final title = r.title != null ? '${r.title}: ' : '';
      final moods = r.moods.isNotEmpty ? ' [${r.moods.join("، ")}]' : '';
      final text =
          r.text.length > 220 ? '${r.text.substring(0, 220)}…' : r.text;
      return '$title$text$moods';
    }).toList();
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(DateTime t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $period';
  }
}
