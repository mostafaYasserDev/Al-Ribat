import 'package:flutter_test/flutter_test.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';

void main() {
  group('ActivityItem Unit Tests', () {
    test('isDoneOn and isSkippedOn query checks', () {
      final activity = ActivityItem(
        id: 'act-1',
        title: 'قراءة الورد القرآني',
        createdAt: DateTime(2026, 11, 1),
        historyDates: {'2026-11-24', '2026-11-23'},
        skippedDates: {'2026-11-22'},
      );

      expect(activity.isDoneOn('2026-11-24'), isTrue);
      expect(activity.isDoneOn('2026-11-23'), isTrue);
      expect(activity.isDoneOn('2026-11-22'), isFalse);
      expect(activity.isDoneOn('2026-11-21'), isFalse);

      expect(activity.isSkippedOn('2026-11-22'), isTrue);
      expect(activity.isSkippedOn('2026-11-24'), isFalse);
    });

    test(
        'getProgressOn calculates progress correctly for measurable and binary activities',
        () {
      final measurable = ActivityItem(
        id: 'act-2',
        title: 'شرب 3 لتر ماء',
        isMeasurable: true,
        targetGoal: 3.0,
        goalUnit: 'لتر',
        createdAt: DateTime(2026, 11, 1),
        history: const [
          ActivityRecord(date: '2026-11-24', progress: 2.5),
          ActivityRecord(date: '2026-11-23', isSkipped: true, progress: 1.0),
        ],
      );

      expect(measurable.getProgressOn('2026-11-24'), 2.5);
      expect(
          measurable.getProgressOn('2026-11-23'), 0.0); // skipped returns 0.0
      expect(measurable.getProgressOn('2026-11-22'), 0.0); // not logged

      final binary = ActivityItem(
        id: 'act-3',
        title: 'صلاة الوتر',
        isMeasurable: false,
        createdAt: DateTime(2026, 11, 1),
        history: const [
          ActivityRecord(date: '2026-11-24', progress: 1.0),
        ],
      );

      expect(binary.getProgressOn('2026-11-24'), 1.0);
    });

    test('copyWith updates properties without mutating original', () {
      final original = ActivityItem(
        id: 'act-4',
        title: 'رياضة الصباح',
        repetition: ActivityRepetition.daily,
        createdAt: DateTime(2026, 11, 1),
        orderIndex: 0,
      );

      final updated = original.copyWith(
        title: 'رياضة مسائية',
        orderIndex: 3,
        repetition: ActivityRepetition.weekly,
      );

      expect(original.title, 'رياضة الصباح');
      expect(original.orderIndex, 0);
      expect(original.repetition, ActivityRepetition.daily);

      expect(updated.id, original.id);
      expect(updated.title, 'رياضة مسائية');
      expect(updated.orderIndex, 3);
      expect(updated.repetition, ActivityRepetition.weekly);
    });
  });
}
