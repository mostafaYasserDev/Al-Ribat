import 'package:flutter_test/flutter_test.dart';
import 'package:al_ribat/features/focus/focus.dart';

void main() {
  group('Focus Feature Unit Tests', () {
    test('WorkSessionItem copyWith and properties', () {
      final started = DateTime(2026, 11, 24, 10, 0);
      final ended = DateTime(2026, 11, 24, 10, 25);

      final session = WorkSessionItem(
        id: 'session-1',
        name: 'قراءة كتاب',
        plannedMinutes: 25,
        startedAt: started,
        endedAt: ended,
        completed: true,
      );

      expect(session.id, 'session-1');
      expect(session.name, 'قراءة كتاب');
      expect(session.plannedMinutes, 25);
      expect(session.startedAt, started);
      expect(session.endedAt, ended);
      expect(session.completed, isTrue);

      final updated = session.copyWith(completed: false, name: 'جلسة متوقفة');
      expect(updated.id, 'session-1');
      expect(updated.name, 'جلسة متوقفة');
      expect(updated.completed, isFalse);
    });

    test('WorkSessionItemModel JSON serialization and deserialization', () {
      final started = DateTime(2026, 11, 24, 14, 0);
      final ended = DateTime(2026, 11, 24, 14, 45);

      final model = WorkSessionItemModel(
        id: 'session-100',
        name: 'كتابة مقال',
        plannedMinutes: 45,
        startedAt: started,
        endedAt: ended,
        completed: true,
      );

      final jsonString = model.toJson();
      final restored = WorkSessionItemModel.fromJson(jsonString);

      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.plannedMinutes, model.plannedMinutes);
      expect(restored.startedAt, model.startedAt);
      expect(restored.endedAt, model.endedAt);
      expect(restored.completed, isTrue);
    });

    test('ActiveFocusState canSavePartial returns true only after 10 minutes',
        () {
      final now = DateTime.now();

      // Started 5 minutes ago (< 10 minutes)
      final stateRecent = ActiveFocusState(
        title: 'جلسة حديثة',
        plannedMinutes: 25,
        startedAt: now.subtract(const Duration(minutes: 5)),
        remainingSeconds: 1200,
      );
      expect(stateRecent.canSavePartial, isFalse);

      // Started 12 minutes ago (>= 10 minutes)
      final stateEligible = ActiveFocusState(
        title: 'جلسة قابلة للحفظ',
        plannedMinutes: 25,
        startedAt: now.subtract(const Duration(minutes: 12)),
        remainingSeconds: 780,
      );
      expect(stateEligible.canSavePartial, isTrue);
    });

    test('formatFocusRemaining formats seconds into mm:ss', () {
      expect(formatFocusRemaining(0), '00:00');
      expect(formatFocusRemaining(59), '00:59');
      expect(formatFocusRemaining(60), '01:00');
      expect(formatFocusRemaining(125), '02:05');
      expect(formatFocusRemaining(1500), '25:00');
    });
  });
}
