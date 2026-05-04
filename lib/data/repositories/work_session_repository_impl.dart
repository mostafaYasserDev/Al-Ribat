import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/work_session_item.dart';
import '../../domain/repositories/work_session_repository.dart';
import '../models/work_session_item_model.dart';

class WorkSessionRepositoryImpl implements WorkSessionRepository {
  WorkSessionRepositoryImpl(this._box);

  final Box<String> _box;

  @override
  Future<List<WorkSessionItem>> loadAll() async {
    final list = _box.values.map(WorkSessionItemModel.fromJson).toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  @override
  Future<void> save(WorkSessionItem session) async {
    await _box.put(session.id, WorkSessionItemModel.fromEntity(session).toJson());
  }
}
