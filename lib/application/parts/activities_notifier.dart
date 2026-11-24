part of '../providers.dart';

final activitiesProvider =
    AsyncNotifierProvider<ActivitiesNotifier, List<ActivityItem>>(
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
      await ref
          .read(notificationServiceProvider)
          .scheduleActivityNotifications(activities, settings);
    } catch (e, st) {
      reportError('scheduleActivityNotifications', e, st);
    }

    // Update Home Widget
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final dateDisplay = DateFormat('yyyy/MM/dd').format(now);

    final dueToday =
        activities.where((act) => activityVisibleOnDate(act, now)).toList();

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
      reportError('Error updating home widget', e, st);
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
    state = AsyncData(
      existing.map((e) => e.id == activity.id ? activity : e).toList(),
    );
    await _syncActivityNotifications();
  }

  Future<void> deleteActivity(String id) async {
    await _repository.delete(id);
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    state = AsyncData(existing.where((e) => e.id != id).toList());
    await _syncActivityNotifications();
  }

  Future<void> reorder(
    ActivityItem movedActivity,
    int newIndex,
    List<ActivityItem> source,
  ) async {
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
    final isOnce = activity.repetition == ActivityRepetition.once;
    final isDone =
        isOnce ? activity.historyDates.isNotEmpty : activity.isDoneOn(date);
    final newHistory = List<ActivityRecord>.from(activity.history);
    final newHistoryDates = Set<String>.from(activity.historyDates);
    final newSkippedDates = Set<String>.from(activity.skippedDates);

    if (isDone) {
      if (isOnce) {
        newHistory.clear();
        newHistoryDates.clear();
      } else {
        newHistory.removeWhere((r) => r.date == date);
        newHistoryDates.remove(date);
      }
    } else {
      newHistory.removeWhere((r) => r.date == date);
      newHistory.add(
        ActivityRecord(date: date, progress: activity.targetGoal ?? 1.0),
      );
      newHistoryDates.add(date);
      newSkippedDates.remove(date);
    }

    await updateActivity(
      activity.copyWith(
        history: newHistory,
        historyDates: newHistoryDates,
        skippedDates: newSkippedDates,
      ),
    );
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

    await updateActivity(
      activity.copyWith(
        history: newHistory,
        historyDates: newHistoryDates,
        skippedDates: newSkippedDates,
      ),
    );
  }

  Future<void> addProgress(
    ActivityItem activity,
    String date,
    double addedProgress,
  ) async {
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

    await updateActivity(
      activity.copyWith(
        history: newHistory,
        historyDates: newHistoryDates,
        skippedDates: newSkippedDates,
      ),
    );

    if (newProgress >= (activity.targetGoal ?? 1.0) &&
        (activity.targetGoal ?? 1.0) > 0) {
      await updateStreakIfNeeded(ref, date);
    }
  }

  /// إعادة تسمية مشروع لجميع أنشطته
  Future<void> renameProject(String oldName, String newName) async {
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    final updated = <ActivityItem>[];
    for (final act in existing) {
      if (act.projectName == oldName) {
        final u = act.copyWith(projectName: newName);
        await _repository.save(u);
        updated.add(u);
      } else {
        updated.add(act);
      }
    }
    state = AsyncData(updated);
    await _syncActivityNotifications();
  }

  /// حذف مشروع: إما بحذف أنشطته كلياً أو بفك ارتباطها وجعلها عامة
  Future<void> deleteProject(
    String projectName, {
    bool deleteActivities = false,
  }) async {
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    if (deleteActivities) {
      for (final act in existing) {
        if (act.projectName == projectName) {
          await _repository.delete(act.id);
        }
      }
      state = AsyncData(
        existing.where((a) => a.projectName != projectName).toList(),
      );
    } else {
      final updated = <ActivityItem>[];
      for (final act in existing) {
        if (act.projectName == projectName) {
          final u = act.copyWith(projectName: null, groupName: null);
          await _repository.save(u);
          updated.add(u);
        } else {
          updated.add(act);
        }
      }
      state = AsyncData(updated);
    }
    await _syncActivityNotifications();
  }

  /// إضافة مجموعة أنشطة معاً (لقوالب المشاريع)
  Future<void> addMultipleActivities(List<ActivityItem> newActs) async {
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    for (final a in newActs) {
      await _repository.save(a);
    }
    state = AsyncData([...existing, ...newActs]);
    await _syncActivityNotifications();
  }
}
