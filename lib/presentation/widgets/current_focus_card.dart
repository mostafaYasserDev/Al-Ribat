import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/arabic_duration.dart';
import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/habit_item.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/entities/task_item.dart';
import '../../services/motivation_quotes.dart';

class CurrentFocusCard extends StatelessWidget {
  const CurrentFocusCard({
    super.key,
    required this.currentPhase,
    required this.prayers,
    required this.tasks,
    required this.habits,
  });

  final PrayerPhase currentPhase;
  final List<PrayerTime> prayers;
  final List<TaskItem> tasks;
  final List<HabitItem> habits;

  PrayerTime? _nextPrayer(DateTime now) {
    for (final p in prayers) {
      if (p.time.isAfter(now)) return p;
    }
    return null;
  }

  TaskItem? _primaryTask(DateTime now) {
    final inPhase = tasks.where((t) => t.linkedPrayer == currentPhase && !t.isCompleted).toList();
    if (inPhase.isEmpty) return null;
    final withWindow = inPhase.where((t) => t.isWithinPlannedWindow(now)).toList();
    if (withWindow.isNotEmpty) return withWindow.first;
    final noWindow = inPhase.where((t) => t.startMinutesFromMidnight == null).toList();
    if (noWindow.isNotEmpty) return noWindow.first;
    return inPhase.first;
  }

  HabitItem? _nextHabitToday(DateTime now) {
    if (habits.isEmpty) return null;
    final minutesNow = now.hour * 60 + now.minute;
    HabitItem? best;
    var bestDelta = 1 << 30;
    for (final h in habits) {
      final m = h.reminderHour * 60 + h.reminderMinute;
      var delta = m - minutesNow;
      if (delta < 0) delta += 24 * 60;
      if (delta < bestDelta) {
        bestDelta = delta;
        best = h;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final next = _nextPrayer(now);
    final primary = _primaryTask(now);
    final habit = _nextHabitToday(now);

    final untilNext = next?.time.difference(now);
    final subtitle = next == null
        ? 'انتهت صلوات اليوم المعروضة.'
        : untilNext!.isNegative
            ? 'حان وقت ${next.phase.arabicName}'
            : 'حتى ${next.phase.arabicName}: ${formatArabicPrayerRemaining(untilNext)}';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تركيزك الآن',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'المرحلة: ${currentPhase.arabicName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 22),
            Text('مهمتك الحالية', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              primary == null
                  ? 'لا توجد مهمة نشطة في هذه المرحلة. أضف مهمة أو أكمل ما سبق.'
                  : primary.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text('عادتك القادمة', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              habit == null
                  ? 'لم تضف عادات بعد.'
                  : '${habit.title} — ${_formatClock(habit.reminderHour, habit.reminderMinute)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              MotivationQuotes.randomLine(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatClock(int hour, int minute) {
    final d = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm('ar').format(d);
  }

}
