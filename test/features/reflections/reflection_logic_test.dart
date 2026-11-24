import 'package:flutter_test/flutter_test.dart';
import 'package:al_ribat/features/reflections/reflections.dart';

void main() {
  group('ReflectionEntry and EditHistory Unit Tests', () {
    test('creates entry and preserves immutability', () {
      final now = DateTime(2026, 11, 24, 15, 0);
      final entry = ReflectionEntry(
        id: '1',
        text: 'الحمد لله على نعمة الإنجاز',
        createdAt: now,
        mood: 'هادئ',
      );

      expect(entry.id, '1');
      expect(entry.text, 'الحمد لله على نعمة الإنجاز');
      expect(entry.mood, 'هادئ');
      expect(entry.createdAt, now);
      expect(entry.editHistory, isEmpty);
    });

    test('copyWith records edit history correctly', () {
      final created = DateTime(2026, 11, 24, 10, 0);
      final edited = DateTime(2026, 11, 24, 11, 0);

      final original = ReflectionEntry(
        id: '1',
        text: 'النص الأصلي',
        createdAt: created,
        mood: 'راضٍ',
      );

      final record = ReflectionEditRecord(
        editedAt: edited,
        oldText: original.text,
        oldMood: original.mood,
      );

      final updated = original.copyWith(
        text: 'النص المعدل',
        mood: 'سعيد',
        editHistory: [record],
      );

      expect(updated.id, original.id);
      expect(updated.text, 'النص المعدل');
      expect(updated.mood, 'سعيد');
      expect(updated.editHistory.length, 1);
      expect(updated.editHistory.first.oldText, 'النص الأصلي');
      expect(updated.editHistory.first.oldMood, 'راضٍ');
      expect(updated.editHistory.first.editedAt, edited);
    });

    test('ReflectionEntryModel serializes to and from JSON without data loss',
        () {
      final created = DateTime(2026, 11, 24, 12, 0);
      final model = ReflectionEntryModel(
        id: '100',
        text: 'تأمل للتجربة',
        createdAt: created,
        mood: 'ملهم',
        editHistory: [
          ReflectionEditRecordModel(
            editedAt: created.add(const Duration(hours: 1)),
            oldText: 'نص سابق',
            oldMood: 'متردد',
          ),
        ],
      );

      final jsonString = model.toJson();
      final restored = ReflectionEntryModel.fromJson(jsonString);

      expect(restored.id, model.id);
      expect(restored.text, model.text);
      expect(restored.mood, model.mood);
      expect(restored.createdAt, model.createdAt);
      expect(restored.editHistory.length, 1);
      expect(restored.editHistory.first.oldText, 'نص سابق');
      expect(restored.editHistory.first.oldMood, 'متردد');
    });
  });
}
