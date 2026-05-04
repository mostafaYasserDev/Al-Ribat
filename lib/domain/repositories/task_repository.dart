import '../entities/task_item.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> getTasksForDay(DateTime date);
  Future<void> saveTask(TaskItem task);
  Future<void> updateTask(TaskItem task);
  Future<void> deleteTask(String id);
  Future<void> reorderTasks(List<TaskItem> tasks);
}
