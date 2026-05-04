import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/reflection_entry.dart';
import '../../domain/repositories/reflection_repository.dart';
import '../models/reflection_entry_model.dart';

class ReflectionRepositoryImpl implements ReflectionRepository {
  ReflectionRepositoryImpl(this._box);

  final Box<String> _box;

  @override
  Future<List<ReflectionEntry>> loadAll() async {
    final all = _box.values.map(ReflectionEntryModel.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<void> add(ReflectionEntry entry) async {
    await _box.put(entry.id, ReflectionEntryModel.fromEntity(entry).toJson());
  }
}
