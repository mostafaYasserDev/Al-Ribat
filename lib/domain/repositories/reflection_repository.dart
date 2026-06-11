import '../entities/reflection_entry.dart';

abstract class ReflectionRepository {
  Future<List<ReflectionEntry>> loadAll();
  Future<void> add(ReflectionEntry entry);
  Future<void> update(ReflectionEntry entry);
  Future<void> delete(String id);
}
