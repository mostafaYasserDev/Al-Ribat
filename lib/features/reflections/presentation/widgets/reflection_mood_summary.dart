import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_moods.dart';
import '../../domain/reflection_entry.dart';

/// Compact weekly reflection & mood pulse displayed calmly at the top
/// of the Reflections screen.
class ReflectionMoodSummary extends StatelessWidget {
  const ReflectionMoodSummary({super.key, required this.entries});

  final List<ReflectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 6));
    final weekStartDay =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    final weekEntries =
        entries.where((e) => !e.createdAt.isBefore(weekStartDay)).toList();

    if (weekEntries.isEmpty) return const SizedBox.shrink();

    final moodCounts = <String, int>{};
    for (final e in weekEntries) {
      final m = e.mood;
      if (m != null && m.isNotEmpty) {
        moodCounts[m] = (moodCounts[m] ?? 0) + 1;
      }
    }

    String? topMood;
    var topCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > topCount) {
        topMood = mood;
        topCount = count;
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined,
              size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'تأملات الأسبوع: ${weekEntries.length}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (topMood != null) ...[
            Text(
              'الغالب:',
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            MoodDisplayChip(mood: topMood!, dense: true),
          ],
        ],
      ),
    );
  }
}
