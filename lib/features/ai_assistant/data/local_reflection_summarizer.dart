import '../../reflections/domain/reflection_entry.dart';
import '../domain/ai_context_snapshot.dart';

class LocalReflectionSummarizer {
  const LocalReflectionSummarizer();

  static const Set<String> _stopWords = {
    'في',
    'من',
    'على',
    'إلى',
    'عن',
    'مع',
    'هذا',
    'هذه',
    'ذلك',
    'تلك',
    'التي',
    'الذي',
    'الذين',
    'كان',
    'كانت',
    'يكون',
    'أن',
    'إن',
    'لا',
    'لم',
    'لن',
    'ما',
    'هل',
    'قد',
    'ثم',
    'أو',
    'و',
    'ف',
    'ب',
    'ل',
    'ك',
    'أنا',
    'نحن',
    'أنت',
    'هو',
    'هي',
    'هم',
    'كل',
    'بعض',
    'جداً',
    'جدا',
    'فقط',
    'اليوم',
    'أمس',
    'غداً',
    'الله',
    'الحمد',
    'يارب',
    'رب',
    'شيء',
    'أكثر',
    'أقل',
    'عند',
    'بين',
    'بعد',
    'قبل',
    'حتى',
    'لكن',
    'لأن',
    'إذا',
    'لو',
    'the',
    'and',
    'for',
    'that',
    'this',
    'with',
    'have',
    'not',
    'but',
  };

  ReflectionSummary summarize(
    List<ReflectionEntry> entries, {
    int lastDays = 7,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final cutoff = current.subtract(Duration(days: lastDays));
    final recent = entries.where((e) => e.createdAt.isAfter(cutoff)).toList();

    if (recent.isEmpty) {
      return ReflectionSummary(
        count: 0,
        periodDays: lastDays,
        topMoods: const [],
        recurringThemes: const [],
      );
    }

    final moodCounts = <String, int>{};
    final wordCounts = <String, int>{};
    final prayerCounts = <String, int>{};

    for (final entry in recent) {
      for (final m in entry.moods) {
        moodCounts[m] = (moodCounts[m] ?? 0) + 1;
      }

      if (entry.prayerPhaseName != null &&
          entry.prayerPhaseName!.trim().isNotEmpty) {
        final p = entry.prayerPhaseName!.trim();
        prayerCounts[p] = (prayerCounts[p] ?? 0) + 1;
      }

      final combined = '${entry.title ?? ''} ${entry.text}';
      final tokens = combined
          .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9\s]'), ' ')
          .split(RegExp(r'\s+'));
      for (final raw in tokens) {
        final w = raw.trim().toLowerCase();
        if (w.length < 3 || _stopWords.contains(w)) continue;
        wordCounts[w] = (wordCounts[w] ?? 0) + 1;
      }
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMoods =
        sortedMoods.take(4).map((e) => '${e.key} (${e.value}×)').toList();

    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recurringThemes = sortedWords
        .where((e) => e.value >= 2)
        .take(5)
        .map((e) => e.key)
        .toList();

    final sortedPrayers = prayerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakPrayer =
        sortedPrayers.isNotEmpty ? sortedPrayers.first.key : null;

    return ReflectionSummary(
      count: recent.length,
      periodDays: lastDays,
      topMoods: topMoods,
      recurringThemes: recurringThemes,
      peakPrayerTime: peakPrayer,
    );
  }
}
