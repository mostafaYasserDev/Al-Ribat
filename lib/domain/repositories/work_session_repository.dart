import '../entities/work_session_item.dart';

abstract class WorkSessionRepository {
  Future<List<WorkSessionItem>> loadAll();
  Future<void> save(WorkSessionItem session);
}
