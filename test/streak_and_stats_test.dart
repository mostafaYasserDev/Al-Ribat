import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/date_ranges.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Directory? tempDir;
  Box<String>? metaBox;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('al_ribat_streak_test_');
    Hive.init(tempDir!.path);
    metaBox = await Hive.openBox<String>('meta_box');
  });

  tearDown(() async {
    if (metaBox != null && metaBox!.isOpen) {
      await metaBox!.close();
      await Hive.deleteBoxFromDisk('meta_box');
    }
    if (tempDir != null && tempDir!.existsSync()) {
      await tempDir!.delete(recursive: true);
    }
  });

  String dayOffset(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateFormat('yyyy-MM-dd').format(
      DateTime(today.year, today.month, today.day + days),
    );
  }

  test('streakProvider resets a streak broken more than a day ago', () async {
    final box = metaBox!;
    await box.put('streak_count', '7');
    await box.put('streak_last_date', dayOffset(-3));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(streakProvider.future), 0);
    expect(box.get('streak_count'), '0');
  });

  test('streakProvider keeps a streak from yesterday', () async {
    final box = metaBox!;
    await box.put('streak_count', '5');
    await box.put('streak_last_date', dayOffset(-1));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(streakProvider.future), 5);
  });

  test('updateStreakIfNeeded increments once per day', () async {
    final box = metaBox!;
    await box.put('streak_count', '4');
    await box.put('streak_last_date', dayOffset(-1));

    await updateStreakIfNeeded(null, dayOffset(0));
    expect(box.get('streak_count'), '5');

    await updateStreakIfNeeded(null, dayOffset(0));
    expect(box.get('streak_count'), '5');
  });

  test('updateStreakIfNeeded starts a new streak after a gap', () async {
    final box = metaBox!;
    await box.put('streak_count', '9');
    await box.put('streak_last_date', dayOffset(-4));

    await updateStreakIfNeeded(null, dayOffset(0));
    expect(box.get('streak_count'), '1');
    expect(box.get('streak_last_date'), dayOffset(0));
  });

  test('weekStartSaturday returns Saturday for the whole week', () {
    final saturday = DateTime(2026, 11, 21);
    for (final day in [0, 1, 2, 3, 4, 5, 6]) {
      expect(
        weekStartSaturday(DateTime(2026, 11, 21 + day)),
        saturday,
        reason: 'day offset $day',
      );
    }
  });
}
