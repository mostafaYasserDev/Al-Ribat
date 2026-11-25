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

    test('copyWith clearMood removes mood and preserves context fields', () {
      final entry = ReflectionEntry(
        id: '2',
        text: 'تأمل مرتبط',
        createdAt: DateTime(2026, 11, 25, 14, 0),
        mood: 'هادئ',
        prayerPhaseName: 'العصر',
        linkedContextTitle: 'تركيز: قراءة',
      );

      final cleared = entry.copyWith(clearMood: true);
      expect(cleared.mood, isNull);
      expect(cleared.prayerPhaseName, 'العصر');
      expect(cleared.linkedContextTitle, 'تركيز: قراءة');
    });

    test('ReflectionEntryModel preserves prayerPhaseName & linkedContextTitle',
        () {
      final created = DateTime(2026, 11, 25, 16, 0);
      final model = ReflectionEntryModel(
        id: '200',
        text: 'خاطرة',
        createdAt: created,
        mood: 'ممتن',
        prayerPhaseName: 'المغرب',
        linkedContextTitle: 'مشروع: حفظ القرآن',
      );

      final restored = ReflectionEntryModel.fromJson(model.toJson());
      expect(restored.prayerPhaseName, 'المغرب');
      expect(restored.linkedContextTitle, 'مشروع: حفظ القرآن');
    });

    test('ReflectionSearch normalizes Arabic and matches multi-word queries',
        () {
      final entry = ReflectionEntry(
        id: '300',
        text: 'تأمل جميل في قراءة القرآن الكريم',
        createdAt: DateTime(2026, 11, 25, 16, 0),
        mood: 'هادئ',
        prayerPhaseName: 'العصر',
        linkedContextTitle: 'مشروع: ختمة القرآن',
      );

      // Alef & diacritic normalization
      expect(ReflectionSearch.matches(entry, 'تامل'), isTrue);
      expect(ReflectionSearch.matches(entry, 'قراءه'), isTrue);
      // Multi-word AND across prayer + project + mood
      expect(ReflectionSearch.matches(entry, 'العصر هادئ'), isTrue);
      expect(ReflectionSearch.matches(entry, 'ختمه القران'), isTrue);
      // Non-matching word
      expect(ReflectionSearch.matches(entry, 'العصر الفجر'), isFalse);
    });

    test('ReflectionEntryModel & Search support title, isPinned, and colorKey',
        () {
      final created = DateTime(2026, 11, 25, 17, 0);
      final model = ReflectionEntryModel(
        id: '400',
        title: 'فائدة من سورة الكهف',
        text: 'أهمية الصحبة الصالحة والثبات',
        createdAt: created,
        isPinned: true,
        colorKey: 'sage',
      );

      final restored = ReflectionEntryModel.fromJson(model.toJson());
      expect(restored.title, 'فائدة من سورة الكهف');
      expect(restored.isPinned, isTrue);
      expect(restored.colorKey, 'sage');
      expect(ReflectionSearch.matches(restored, 'سوره الكهف'), isTrue);
    });
  });
}
