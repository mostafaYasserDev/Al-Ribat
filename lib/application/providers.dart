import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../core/constants/prayer_phase.dart';
import '../data/repositories/habit_repository_impl.dart';
import '../data/repositories/reflection_repository_impl.dart';
import '../data/repositories/prayer_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/repositories/work_session_repository_impl.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/day_state.dart';
import '../domain/entities/habit_item.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/prayer_time.dart';
import '../domain/entities/reflection_entry.dart';
import '../domain/entities/stats_snapshot.dart';
import '../domain/entities/task_item.dart';
import '../domain/entities/work_session_item.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/repositories/prayer_repository.dart';
import '../domain/repositories/reflection_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/work_session_repository.dart';
import '../services/notification_service.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final box = Hive.box<String>('tasks_box');
  return TaskRepositoryImpl(box);
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final box = Hive.box<String>('habits_box');
  return HabitRepositoryImpl(box);
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
    final habits = await ref.read(habitRepositoryProvider).loadAll();
    await notifier.scheduleHabitNotifications(habits, settings);
  } catch (e, st) {
    debugPrint('scheduleHabitNotifications failed: $e\n$st');
  }
  try {
    final taskRepo = ref.read(taskRepositoryProvider);
    final tasks = await taskRepo.getTasksForDay(DateTime.now());
    await notifier.scheduleTaskNotifications(tasks, settings);
  } catch (e, st) {
    debugPrint('scheduleTaskNotifications failed: $e\n$st');
  }
}

final prayerScheduleProvider = FutureProvider<PrayerSchedule>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final repo = ref.watch(prayerRepositoryProvider);
  final schedule = await repo.getPrayerSchedule(settings);
  unawaited(_syncNotificationsAfterSchedule(ref, schedule, settings));
  return schedule;
});

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<TaskItem>>(
  TasksNotifier.new,
);

class TasksNotifier extends AsyncNotifier<List<TaskItem>> {
  late final TaskRepository _repo;
  Future<void> _syncTaskNotifications() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    final tasks = await _repo.getTasksForDay(DateTime.now());
    try {
      await ref.read(notificationServiceProvider).scheduleTaskNotifications(tasks, settings);
    } catch (e, st) {
      debugPrint('scheduleTaskNotifications: $e\n$st');
    }
  }

  @override
  Future<List<TaskItem>> build() async {
    _repo = ref.watch(taskRepositoryProvider);
    return _repo.getTasksForDay(DateTime.now());
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.getTasksForDay(DateTime.now()));
    await _syncTaskNotifications();
  }

  Future<void> addTask(TaskItem task) async {
    await _repo.saveTask(task);
    await load();
    await _syncTaskNotifications();
  }

  Future<void> toggleTask(TaskItem task) async {
    await _repo.updateTask(task.copyWith(isCompleted: !task.isCompleted));
    await load();
    await _syncTaskNotifications();
  }

  Future<void> editTask(TaskItem task) async {
    await _repo.updateTask(task);
    await load();
    await _syncTaskNotifications();
  }

  Future<void> deleteTask(String id) async {
    await _repo.deleteTask(id);
    await load();
    await _syncTaskNotifications();
  }

  Future<void> reorder(TaskItem movedTask, int newIndex, List<TaskItem> source) async {
    final copy = [...source];
    final oldIndex = copy.indexWhere((e) => e.id == movedTask.id);
    if (oldIndex < 0) return;
    final item = copy.removeAt(oldIndex);
    copy.insert(newIndex, item);
    await _repo.reorderTasks(copy);
    state = AsyncData(copy);
    await _syncTaskNotifications();
  }
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<HabitItem>>(
  HabitsNotifier.new,
);

class HabitsNotifier extends AsyncNotifier<List<HabitItem>> {
  late final HabitRepository _repo;

  @override
  Future<List<HabitItem>> build() async {
    _repo = ref.watch(habitRepositoryProvider);
    return _repo.loadAll();
  }

  Future<void> _syncHabitNotifications() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    final habits = await _repo.loadAll();
    try {
      await ref.read(notificationServiceProvider).scheduleHabitNotifications(habits, settings);
    } catch (e, st) {
      debugPrint('scheduleHabitNotifications: $e\n$st');
    }
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.loadAll());
    await _syncHabitNotifications();
  }

  Future<void> addHabit(HabitItem habit) async {
    await _repo.save(habit);
    state = AsyncData(await _repo.loadAll());
    await _syncHabitNotifications();
  }

  Future<void> updateHabit(HabitItem habit) async {
    await _repo.save(habit);
    state = AsyncData(await _repo.loadAll());
    await _syncHabitNotifications();
  }

  Future<void> deleteHabit(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.loadAll());
    await _syncHabitNotifications();
  }

  Future<void> markDoneToday(HabitItem habit) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _repo.save(habit.copyWith(lastMarkedDoneDate: today));
    state = AsyncData(await _repo.loadAll());
    await _syncHabitNotifications();
  }

  Future<void> clearDoneToday(HabitItem habit) async {
    await _repo.save(habit.copyWith(clearLastMarked: true));
    state = AsyncData(await _repo.loadAll());
    await _syncHabitNotifications();
  }
}

final workSessionsProvider =
    AsyncNotifierProvider<WorkSessionsNotifier, List<WorkSessionItem>>(
  WorkSessionsNotifier.new,
);

class WorkSessionsNotifier extends AsyncNotifier<List<WorkSessionItem>> {
  late final WorkSessionRepository _repo;

  @override
  Future<List<WorkSessionItem>> build() async {
    _repo = ref.watch(workSessionRepositoryProvider);
    return _repo.loadAll();
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
  late final ReflectionRepository _repo;

  @override
  Future<List<ReflectionEntry>> build() async {
    _repo = ref.watch(reflectionRepositoryProvider);
    return _repo.loadAll();
  }

  Future<void> add(String text) async {
    final entry = ReflectionEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _repo.add(entry);
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
  required int weeklyTasks,
  required int focusMin,
  required int habitsWeek,
}) {
  if (weeklyTasks >= 12 && focusMin >= 60) {
    return 'أسبوع متوازن بين المهام والتركيز — تابع على هذا المنوال.';
  }
  if (weeklyTasks >= 6) {
    return 'إيقاع جيد. حاول إضافة جلسة تركيز قصيرة بين الحصص.';
  }
  if (habitsWeek >= 4) {
    return 'عاداتك تتكرر بانتظام — هذا يبني ثباتاً داخلياً.';
  }
  return 'ابدأ بخطوة صغيرة بعد كل صلاة؛ التراكم يصنع الفارق.';
}

final statsProvider = Provider<StatsSnapshot>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskItem>[];
  final reflections = ref.watch(reflectionsProvider).valueOrNull ?? const <ReflectionEntry>[];
  final workSessions = ref.watch(workSessionsProvider).valueOrNull ?? const <WorkSessionItem>[];
  final habits = ref.watch(habitsProvider).valueOrNull ?? const <HabitItem>[];
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);
  final completed = tasks.where((e) => e.isCompleted).toList();
  final weekly = completed.where((e) => e.createdAt.isAfter(weekStart)).length;
  final monthly = completed.where((e) => e.createdAt.isAfter(monthStart)).length;
  final byPhase = {
    for (final phase in PrayerPhase.values)
      phase: completed.where((e) => e.linkedPrayer == phase).length,
  };

  final reflectionsThisMonth =
      reflections.where((e) => e.createdAt.isAfter(monthStart)).length;

  final wsWeek = workSessions.where((e) => e.startedAt.isAfter(weekStart)).toList();
  final workSessionsThisWeek = wsWeek.where((e) => e.completed).length;
  final focusMinutesThisWeek = wsWeek
      .where((e) => e.completed)
      .fold<int>(0, (a, b) => a + b.actualMinutes.clamp(0, b.plannedMinutes + 5));

  final habitsMarked = habits.where((h) {
    final d = h.lastMarkedDoneDate;
    if (d == null) return false;
    final dt = DateTime.tryParse(d);
    return dt != null && !dt.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day));
  }).length;

  return StatsSnapshot(
    weeklyCompleted: weekly,
    monthlyCompleted: monthly,
    byPhase: byPhase,
    reflectionsThisMonth: reflectionsThisMonth,
    workSessionsThisWeek: workSessionsThisWeek,
    focusMinutesThisWeek: focusMinutesThisWeek,
    habitsMarkedThisWeek: habitsMarked,
    feedbackLine: _statsFeedback(
      weeklyTasks: weekly,
      focusMin: focusMinutesThisWeek,
      habitsWeek: habitsMarked,
    ),
  );
});

final dayStateProvider = Provider<DayState>((ref) {
  final sched = ref.watch(prayerScheduleProvider).valueOrNull;
  final prayers = sched?.today ?? const <PrayerTime>[];
  final streak = ref.watch(streakProvider).valueOrNull ?? 0;
  final now = DateTime.now();

  PrayerPhase current = PrayerPhase.fajr;
  for (final p in prayers) {
    if (now.isAfter(p.time)) {
      current = p.phase;
    }
  }

  return DayState(currentPrayerPhase: current, streakCount: streak);
});

Future<void> updateStreakIfNeeded(WidgetRef ref) async {
  final tasks = ref.read(tasksProvider).valueOrNull ?? const <TaskItem>[];
  final completed = tasks.where((e) => e.isCompleted).length;
  if (completed == 0) return;
  final box = Hive.box<String>('meta_box');
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final yesterday = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(const Duration(days: 1)));
  final lastDate = box.get('streak_last_date');
  var streak = int.tryParse(box.get('streak_count') ?? '0') ?? 0;

  if (lastDate == today) return;
  if (lastDate == yesterday) {
    streak += 1;
  } else {
    streak = 1;
  }
  await box.put('streak_count', '$streak');
  await box.put('streak_last_date', today);
  ref.invalidate(streakProvider);
}
