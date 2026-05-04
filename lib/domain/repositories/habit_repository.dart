import '../entities/habit_item.dart';

abstract class HabitRepository {
  Future<List<HabitItem>> loadAll();
  Future<void> save(HabitItem habit);
  Future<void> delete(String id);
}
