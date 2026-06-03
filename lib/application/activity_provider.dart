import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/activity_item.dart';
import '../domain/repositories/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  throw UnimplementedError('activityRepositoryProvider not initialized');
});

final activitiesProvider = AsyncNotifierProvider<ActivitiesNotifier, List<ActivityItem>>(
  ActivitiesNotifier.new,
);

class ActivitiesNotifier extends AsyncNotifier<List<ActivityItem>> {
  late ActivityRepository _repository;

  @override
  Future<List<ActivityItem>> build() async {
    _repository = ref.watch(activityRepositoryProvider);
    return _repository.loadAll();
  }

  Future<void> addActivity(ActivityItem activity) async {
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    await _repository.save(activity);
    state = AsyncData([...existing, activity]);
  }

  Future<void> updateActivity(ActivityItem activity) async {
    await _repository.save(activity);
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    state = AsyncData(existing.map((e) => e.id == activity.id ? activity : e).toList());
  }

  Future<void> deleteActivity(String id) async {
    await _repository.delete(id);
    final existing = state.valueOrNull ?? const <ActivityItem>[];
    state = AsyncData(existing.where((e) => e.id != id).toList());
  }

  Future<void> reorder(ActivityItem movedActivity, int newIndex, List<ActivityItem> source) async {
    final list = List<ActivityItem>.from(source);
    final oldIndex = list.indexWhere((e) => e.id == movedActivity.id);
    if (oldIndex == -1) return;
    list.removeAt(oldIndex);
    list.insert(newIndex, movedActivity);

    await _repository.reorder(list);
    final all = state.valueOrNull ?? const <ActivityItem>[];
    
    // We only reordered a subset (e.g. within a prayer phase). 
    // So we update the main list with the new order indexes.
    final updatedMap = {for (var i = 0; i < list.length; i++) list[i].id: i};
    final updatedAll = all.map((e) {
      if (updatedMap.containsKey(e.id)) {
        return e.copyWith(orderIndex: updatedMap[e.id]);
      }
      return e;
    }).toList();
    
    updatedAll.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    state = AsyncData(updatedAll);
  }

  Future<void> toggleDone(ActivityItem activity, String date) async {
    final isDone = activity.isDoneOn(date);
    final newHistory = List<ActivityRecord>.from(activity.history);
    
    if (isDone) {
      newHistory.removeWhere((r) => r.date == date);
    } else {
      // Remove any existing record for this date to avoid duplicates
      newHistory.removeWhere((r) => r.date == date);
      newHistory.add(ActivityRecord(date: date, progress: activity.targetGoal ?? 1.0));
    }
    
    await updateActivity(activity.copyWith(history: newHistory));
  }

  Future<void> skipActivity(ActivityItem activity, String date) async {
    final newHistory = List<ActivityRecord>.from(activity.history);
    newHistory.removeWhere((r) => r.date == date);
    newHistory.add(ActivityRecord(date: date, isSkipped: true));
    await updateActivity(activity.copyWith(history: newHistory));
  }
}
