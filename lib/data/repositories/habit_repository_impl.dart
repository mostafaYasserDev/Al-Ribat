import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/habit_item.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_item_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(this._box);

  final Box<String> _box;

  @override
  Future<List<HabitItem>> loadAll() async {
    final list = _box.values.map(HabitItemModel.fromJson).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<void> save(HabitItem habit) async {
    await _box.put(habit.id, HabitItemModel.fromEntity(habit).toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
