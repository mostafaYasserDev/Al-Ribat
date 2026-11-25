import 'work_session_item.dart';

abstract class WorkSessionRepository {
  Future<List<WorkSessionItem>> loadAll();
  Future<void> save(WorkSessionItem session);
  Future<void> delete(String id);
}
