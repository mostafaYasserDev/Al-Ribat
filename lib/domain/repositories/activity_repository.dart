import '../../domain/entities/activity_item.dart';

abstract class ActivityRepository {
  Future<List<ActivityItem>> loadAll();
  Future<void> save(ActivityItem activity);
  Future<void> delete(String id);
  Future<void> reorder(List<ActivityItem> activities);
}
