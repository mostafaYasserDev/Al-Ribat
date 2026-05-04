import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/data/repositories/task_repository_impl.dart';
import 'package:al_ribat/domain/entities/task_item.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late TaskRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('al_ribat_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('tasks_box_test');
    repo = TaskRepositoryImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('tasks_box_test');
    await tempDir.delete(recursive: true);
  });

  test('saves and loads tasks ordered by index', () async {
    final now = DateTime.now();
    final t1 = TaskItem(
      id: '1',
      title: 'A',
      linkedPrayer: PrayerPhase.fajr,
      type: TaskType.before,
      isCompleted: false,
      orderIndex: 1,
      createdAt: now,
    );
    final t2 = TaskItem(
      id: '2',
      title: 'B',
      linkedPrayer: PrayerPhase.fajr,
      type: TaskType.before,
      isCompleted: false,
      orderIndex: 0,
      createdAt: now,
    );
    await repo.saveTask(t1);
    await repo.saveTask(t2);

    final loaded = await repo.getTasksForDay(now);
    expect(loaded.first.id, '2');
    expect(loaded.last.id, '1');
  });
}
