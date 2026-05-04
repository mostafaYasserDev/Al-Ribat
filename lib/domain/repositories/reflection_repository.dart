import '../entities/reflection_entry.dart';

abstract class ReflectionRepository {
  Future<List<ReflectionEntry>> loadAll();
  Future<void> add(ReflectionEntry entry);
}
