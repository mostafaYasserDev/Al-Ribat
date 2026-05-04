import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_item_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._box);

  final Box<String> _box;

  @override
  Future<List<TaskItem>> getTasksForDay(DateTime date) async {
    final all = _box.values.map(TaskItemModel.fromJson).toList();
    return all
        .where(
          (e) =>
              e.createdAt.year == date.year &&
              e.createdAt.month == date.month &&
              e.createdAt.day == date.day,
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  @override
  Future<void> saveTask(TaskItem task) async {
    final model = TaskItemModel.fromEntity(task);
    await _box.put(task.id, model.toJson());
  }

  @override
  Future<void> updateTask(TaskItem task) async {
    final model = TaskItemModel.fromEntity(task);
    await _box.put(task.id, model.toJson());
  }

  @override
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> reorderTasks(List<TaskItem> tasks) async {
    for (var i = 0; i < tasks.length; i++) {
      final updated = tasks[i].copyWith(orderIndex: i);
      await _box.put(updated.id, TaskItemModel.fromEntity(updated).toJson());
    }
  }
}
