import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/activity_item.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_item_model.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._box);

  final Box<String> _box;

  @override
  Future<List<ActivityItem>> loadAll() async {
    final list = _box.values.map(ActivityItemModel.fromJson).toList();
    list.sort((a, b) {
      if (a.orderIndex != b.orderIndex) {
        return a.orderIndex.compareTo(b.orderIndex);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<void> save(ActivityItem activity) async {
    await _box.put(activity.id, ActivityItemModel.fromEntity(activity).toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> reorder(List<ActivityItem> activities) async {
    for (int i = 0; i < activities.length; i++) {
      final act = activities[i];
      final updated = act.copyWith(orderIndex: i);
      await _box.put(updated.id, ActivityItemModel.fromEntity(updated).toJson());
    }
  }
}
