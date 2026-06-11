import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';

import '../core/activity_schedule.dart';
import '../core/constants/prayer_phase.dart';
import '../data/repositories/activity_repository_impl.dart';
import '../data/repositories/prayer_repository_impl.dart';
import '../data/repositories/reflection_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/work_session_repository_impl.dart';
import '../domain/entities/activity_item.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/day_state.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/prayer_time.dart';
import '../domain/entities/reflection_entry.dart';
import '../domain/entities/stats_snapshot.dart';
import '../domain/entities/work_session_item.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/repositories/prayer_repository.dart';
import '../domain/repositories/reflection_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/work_session_repository.dart';
import '../services/notification_service.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final box = Hive.box<String>('activities_box');
  return ActivityRepositoryImpl(box);
});

final workSessionRepositoryProvider = Provider<WorkSessionRepository>((ref) {
  final box = Hive.box<String>('work_sessions_box');
  return WorkSessionRepositoryImpl(box);
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = Hive.box<String>('meta_box');
  return SettingsRepositoryImpl(box);
});

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  final box = Hive.box<String>('reflections_box');
  return ReflectionRepositoryImpl(box);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.watch(settingsRepositoryProvider).load();
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).saveSettings(settings);
      return settings;
    });
    ref.invalidate(prayerScheduleProvider);
  }
}

Future<void> _syncNotificationsAfterSchedule(
  Ref ref,
  PrayerSchedule schedule,
  AppSettings settings,
) async {
  final notifier = ref.read(notificationServiceProvider);
  try {
    await notifier.schedulePrayerNotifications(schedule.today, settings);
  } catch (e, st) {
    debugPrint('schedulePrayerNotifications failed: $e\n$st');
  }
  try {
    final activities = await ref.read(activityRepositoryProvider).loadAll();
    await notifier.scheduleActivityNotifications(activities, settings);
  } catch (e, st) {
    debugPrint('scheduleActivityNotifications failed: $e\n$st');
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final prayerScheduleProvider = FutureProvider<PrayerSchedule>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final repo = ref.watch(prayerRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final schedule = await repo.getPrayerSchedule(settings, date: date);
  unawaited(_syncNotificationsAfterSchedule(ref, schedule, settings));
  return schedule;
});

final activitiesProvider = AsyncNotifierProvider<ActivitiesNotifier, List<ActivityItem>>(
  ActivitiesNotifier.new,
);

class ActivitiesNotifier extends AsyncNotifier<List<ActivityItem>> {
  ActivityRepository get _repository => ref.read(activityRepositoryProvider);

  @override
  Future<List<ActivityItem>> build() async {
    return ref.watch(activityRepositoryProvider).loadAll();
  }

  Future<void> _syncActivityNotifications() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    final activities = await _repository.loadAll();
    try {
      await ref.read(notificationServiceProvider).scheduleActivityNotifications(activities, settings);
    } catch (e, st) {
      debugPrint('scheduleActivityNotifications failed: $e\n$st');
    }
    
    // Update Home Widget
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Format date for display in Arabic (example: ١٤ رجب - although we can just use normal date)
    final dateDisplay = DateFormat('yyyy/MM/dd').format(now);
    
    final dueToday = activities.where((act) => activityVisibleOnDate(act, now)).toList();

    final totalHabits = dueToday.length;
    final completedHabits = dueToday.where((a) => a.isDoneOn(todayStr)).length;
    
    final habitsListString = dueToday.map((a) {
      final isDone = a.isDoneOn(todayStr);
      return '${isDone ? "[x]" : "[ ]"} ${a.title}';
    }).join('\n');

    try {
      await HomeWidget.saveWidgetData<int>('totalHabits', totalHabits);
      await HomeWidget.saveWidgetData<int>('completedHabits', completedHabits);
      await HomeWidget.saveWidgetData<String>('currentDate', dateDisplay);
      await HomeWidget.saveWidgetData<String>('habitsList', habitsListString);
      await HomeWidget.updateWidget(
        name: 'HabitsWidgetProvider',
        iOSName: 'HabitsWidget',
      );
    } catch (e, st) {
      debugPrint('Error updating home widget: $e\n$st');
    }
  }

  Future<void> addActivity(ActivityItem activity) async {
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    await _repository.save(activity);
    state = AsyncData([...existing, activity]);
    await _syncActivityNotifications();
  }

  Future<void> updateActivity(ActivityItem activity) async {
    await _repository.save(activity);
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    state = AsyncData(existing.map((e) => e.id == activity.id ? activity : e).toList());
    await _syncActivityNotifications();
  }

  Future<void> deleteActivity(String id) async {
    await _repository.delete(id);
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    state = AsyncData(existing.where((e) => e.id != id).toList());
    await _syncActivityNotifications();
  }

  Future<void> reorder(ActivityItem movedActivity, int newIndex, List<ActivityItem> source) async {
    final list = List<ActivityItem>.from(source);
    final oldIndex = list.indexWhere((e) => e.id == movedActivity.id);
    if (oldIndex == -1) return;
    list.removeAt(oldIndex);
    list.insert(newIndex, movedActivity);

    await _repository.reorder(list);
    final all = state.valueOrNull ?? const <ActivityItem>[];
    
    final updatedMap = {for (var i = 0; i < list.length; i++) list[i].id: i};
    final updatedAll = all.map((e) {
      if (updatedMap.containsKey(e.id)) {
        return e.copyWith(orderIndex: updatedMap[e.id]);
      }
      return e;
    }).toList();
    
    updatedAll.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    state = AsyncData(updatedAll);
    await _syncActivityNotifications();
  }

  Future<void> toggleDone(ActivityItem activity, String date) async {
    final isDone = activity.isDoneOn(date);
    final newHistory = List<ActivityRecord>.from(activity.history);
    final newHistoryDates = Set<String>.from(activity.historyDates);
    final newSkippedDates = Set<String>.from(activity.skippedDates);
    
    if (isDone) {
      newHistory.removeWhere((r) => r.date == date);
      newHistoryDates.remove(date);
    } else {
      newHistory.removeWhere((r) => r.date == date);
      newHistory.add(ActivityRecord(date: date, progress: activity.targetGoal ?? 1.0));
      newHistoryDates.add(date);
      newSkippedDates.remove(date);
    }
    
    await updateActivity(activity.copyWith(
      history: newHistory,
      historyDates: newHistoryDates,
      skippedDates: newSkippedDates,
    ));
    if (!isDone) {
      await updateStreakIfNeeded(ref, date);
    }
  }

  Future<void> toggleSkip(ActivityItem activity, String date) async {
    final isSkipped = activity.isSkippedOn(date);
    final newHistory = List<ActivityRecord>.from(activity.history);
    final newHistoryDates = Set<String>.from(activity.historyDates);
    final newSkippedDates = Set<String>.from(activity.skippedDates);
    
    if (isSkipped) {
      newHistory.removeWhere((r) => r.date == date);
      newSkippedDates.remove(date);
    } else {
      newHistory.removeWhere((r) => r.date == date);
      newHistory.add(ActivityRecord(date: date, isSkipped: true));
      newSkippedDates.add(date);
      newHistoryDates.remove(date);
    }
    
    await updateActivity(activity.copyWith(
      history: newHistory,
      historyDates: newHistoryDates,
      skippedDates: newSkippedDates,
    ));
  }

  Future<void> addProgress(ActivityItem activity, String date, double addedProgress) async {
    final newHistory = List<ActivityRecord>.from(activity.history);
    final idx = newHistory.indexWhere((r) => r.date == date);
    
    double newProgress = addedProgress;
    if (idx >= 0) {
      final old = newHistory[idx];
      newProgress = old.progress + addedProgress;
      newHistory[idx] = ActivityRecord(
        date: date, 
        isSkipped: old.isSkipped, 
        progress: newProgress,
      );
    } else {
      newHistory.add(ActivityRecord(date: date, progress: newProgress));
    }
    
    final newHistoryDates = Set<String>.from(activity.historyDates);
    if (newProgress >= (activity.targetGoal ?? 1.0)) {
      newHistoryDates.add(date);
    } else {
      newHistoryDates.remove(date);
    }
    
    final newSkippedDates = Set<String>.from(activity.skippedDates);
    newSkippedDates.remove(date);
    
    await updateActivity(activity.copyWith(
      history: newHistory,
      historyDates: newHistoryDates,
      skippedDates: newSkippedDates,
    ));
    
    if (newProgress >= (activity.targetGoal ?? 1.0) && (activity.targetGoal ?? 1.0) > 0) {
      await updateStreakIfNeeded(ref, date);
    }
  }
}

final workSessionsProvider =
    AsyncNotifierProvider<WorkSessionsNotifier, List<WorkSessionItem>>(
  WorkSessionsNotifier.new,
);

class WorkSessionsNotifier extends AsyncNotifier<List<WorkSessionItem>> {
  WorkSessionRepository get _repo => ref.read(workSessionRepositoryProvider);

  @override
  Future<List<WorkSessionItem>> build() async {
    return ref.watch(workSessionRepositoryProvider).loadAll();
  }

  Future<void> addSession(WorkSessionItem session) async {
    await _repo.save(session);
    state = AsyncData(await _repo.loadAll());
  }
}

final reflectionsProvider =
    AsyncNotifierProvider<ReflectionNotifier, List<ReflectionEntry>>(
  ReflectionNotifier.new,
);

class ReflectionNotifier extends AsyncNotifier<List<ReflectionEntry>> {
  ReflectionRepository get _repo => ref.read(reflectionRepositoryProvider);

  @override
  Future<List<ReflectionEntry>> build() async {
    return ref.watch(reflectionRepositoryProvider).loadAll();
  }

  Future<void> add(String text, {String? mood, DateTime? createdAt}) async {
    final at = createdAt ?? DateTime.now();
    final entry = ReflectionEntry(
      id: at.microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: at,
      mood: mood,
    );
    await _repo.add(entry);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> updateReflection(ReflectionEntry oldEntry, String newText, {String? newMood}) async {
    final editRecord = ReflectionEditRecord(
      editedAt: DateTime.now(),
      oldText: oldEntry.text,
      oldMood: oldEntry.mood,
    );
    
    final updatedEntry = oldEntry.copyWith(
      text: newText.trim(),
      mood: newMood,
      editHistory: [...oldEntry.editHistory, editRecord],
    );
    
    await _repo.update(updatedEntry);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.loadAll());
  }
}

final streakProvider = FutureProvider<int>((ref) async {
  final box = Hive.box<String>('meta_box');
  final streak = int.tryParse(box.get('streak_count') ?? '0') ?? 0;
  final lastDate = box.get('streak_last_date');
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  if (lastDate == today) return streak;
  return streak;
});

String _statsFeedback({
  required int activitiesWeek,
  required int focusMin,
}) {
  if (activitiesWeek >= 12 && focusMin >= 60) {
    return 'أسبوع متوازن بين الأنشطة والتركيز — تابع على هذا المنوال.';
  }
  if (activitiesWeek >= 6) {
    return 'إيقاع جيد. حاول إضافة جلسة تركيز قصيرة بين الحصص.';
  }
  return 'ابدأ بخطوة صغيرة بعد كل صلاة؛ التراكم يصنع الفارق.';
}

final statsProvider = Provider<StatsSnapshot>((ref) {
  final activities = ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
  final reflections = ref.watch(reflectionsProvider).valueOrNull ?? const <ReflectionEntry>[];
  final workSessions = ref.watch(workSessionsProvider).valueOrNull ?? const <WorkSessionItem>[];
  
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
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
      
      if (historyDate.isAfter(weekStart)) {
        totalDueThisWeek++;
        if (history.isSkipped) {
          actSkips++;
        } else {
          weekly++;
          totalDoneThisWeek++;
        }
      }
      
      if (historyDate.isAfter(monthStart) && !history.isSkipped) {
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

  PrayerPhase? productivePhase;
  int maxCount = -1;
  for (final entry in byPhase.entries) {
    if (entry.value > maxCount && entry.value > 0) {
      maxCount = entry.value;
      productivePhase = entry.key;
    }
  }

  String? mostSkipped;
  int maxSkips = -1;
  for (final entry in skipsByActivity.entries) {
    if (entry.value > maxSkips) {
      maxSkips = entry.value;
      mostSkipped = entry.key;
    }
  }

  final completionRateThisWeek = totalDueThisWeek == 0 ? 0.0 : (totalDoneThisWeek / totalDueThisWeek);

  final reflectionsThisMonth =
      reflections.where((e) => e.createdAt.isAfter(monthStart)).length;

  final wsWeek = workSessions.where((e) => e.startedAt.isAfter(weekStart)).toList();
  final workSessionsThisWeek = wsWeek.where((e) => e.completed).length;
  final focusMinutesThisWeek = wsWeek
      .where((e) => e.completed)
      .fold<int>(0, (a, b) => a + b.actualMinutes.clamp(0, b.plannedMinutes + 5));

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
});

final dayStateProvider = Provider<DayState>((ref) {
  final sched = ref.watch(prayerScheduleProvider).valueOrNull;
  final prayers = sched?.today ?? const <PrayerTime>[];
  final streak = ref.watch(streakProvider).valueOrNull ?? 0;
  final selectedDate = ref.watch(selectedDateProvider);
  final now = DateTime.now();

  PrayerPhase current = PrayerPhase.fajr;
  
  // If the selected date is in the past, default to Isha. If in the future, default to Fajr.
  if (selectedDate.year < now.year || 
      (selectedDate.year == now.year && selectedDate.month < now.month) ||
      (selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day < now.day)) {
    current = PrayerPhase.isha;
  } else if (selectedDate.year > now.year || 
             (selectedDate.year == now.year && selectedDate.month > now.month) ||
             (selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day > now.day)) {
    current = PrayerPhase.fajr;
  } else {
    for (final p in prayers) {
      if (now.isAfter(p.time)) {
        current = p.phase;
      }
    }
  }

  return DayState(currentPrayerPhase: current, streakCount: streak);
});

Future<void> updateStreakIfNeeded(dynamic ref, [String? dateStr]) async {
  final activities = ref.read(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
  final targetDateStr = dateStr ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  final doneOnTargetDate = activities.where((a) => a.isDoneOn(targetDateStr)).length;
  if (doneOnTargetDate == 0) return;
  
  final box = Hive.box<String>('meta_box');
  final targetDate = DateTime.parse(targetDateStr);
  final previousDate = DateFormat('yyyy-MM-dd').format(targetDate.subtract(const Duration(days: 1)));
  
  final lastDate = box.get('streak_last_date');
  var streak = int.tryParse(box.get('streak_count') ?? '0') ?? 0;

  if (lastDate == targetDateStr) return;
  if (lastDate == previousDate) {
    streak += 1;
  } else {
    if (lastDate != null && DateTime.parse(lastDate).isAfter(targetDate)) {
      return; 
    }
    streak = 1;
  }
  await box.put('streak_count', '$streak');
  await box.put('streak_last_date', targetDateStr);
  ref.invalidate(streakProvider);
}
