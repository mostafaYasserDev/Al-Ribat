import 'package:intl/intl.dart';

import 'reflection_entry.dart';

/// Pure Dart smart search helper for Arabic & English reflections.
/// Normalizes Arabic alef/teh-marbuta/alef-maqsura and strips diacritics,
/// supporting multi-word matching across text, mood, prayer phase,
/// linked project/focus context, and date labels.
abstract final class ReflectionSearch {
  static final RegExp _diacritics = RegExp(r'[\u064B-\u065F\u0670\u0640]');

  static String normalizeArabic(String input) {
    return input
        .toLowerCase()
        .replaceAll(_diacritics, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .trim();
  }

  static bool matches(ReflectionEntry entry, String rawQuery) {
    final normalizedQuery = normalizeArabic(rawQuery);
    if (normalizedQuery.isEmpty) return true;

    final tokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return true;

    var dateText = '';
    try {
      dateText = DateFormat('EEEE d MMMM yyyy', 'ar').format(entry.createdAt);
    } catch (_) {}

    final haystack = normalizeArabic([
      entry.title ?? '',
      entry.text,
      entry.mood ?? '',
      entry.prayerPhaseName ?? '',
      entry.linkedContextTitle ?? '',
      dateText,
    ].join(' '));

    return tokens.every(haystack.contains);
  }
}
