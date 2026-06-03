import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/arabic_duration.dart';
import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/prayer_time.dart';
import '../../services/motivation_quotes.dart';

class CurrentFocusCard extends StatelessWidget {
  const CurrentFocusCard({
    super.key,
    required this.currentPhase,
    required this.prayers,
    required this.activities,
  });

  final PrayerPhase currentPhase;
  final List<PrayerTime> prayers;
  final List<ActivityItem> activities;

  PrayerTime? _nextPrayer(DateTime now) {
    for (final p in prayers) {
      if (p.time.isAfter(now)) return p;
    }
    return null;
  }

  ActivityItem? _primaryActivity(DateTime now, String todayStr) {
    final inPhase = activities.where((a) {
      if (a.isDoneOn(todayStr) || a.isSkippedOn(todayStr)) return false;
      return a.linkedPrayer == currentPhase;
    }).toList();
    if (inPhase.isEmpty) return null;
    return inPhase.first;
  }

  ActivityItem? _nextActivityToday(DateTime now, String todayStr) {
    if (activities.isEmpty) return null;
    final minutesNow = now.hour * 60 + now.minute;
    ActivityItem? best;
    var bestDelta = 1 << 30;
    
    for (final a in activities) {
      if (a.isDoneOn(todayStr) || a.isSkippedOn(todayStr)) continue;
      if (a.reminderHour == null || a.reminderMinute == null) continue;
      
      final m = a.reminderHour! * 60 + a.reminderMinute!;
      var delta = m - minutesNow;
      if (delta < 0) delta += 24 * 60;
      if (delta < bestDelta) {
        bestDelta = delta;
        best = a;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final next = _nextPrayer(now);
    final primary = _primaryActivity(now, todayStr);
    final upcoming = _nextActivityToday(now, todayStr);

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
            Text('نشاطك الحالي', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              primary == null
                  ? 'لا توجد أنشطة نشطة في هذه المرحلة. أضف نشاطاً أو أكمل ما سبق.'
                  : primary.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text('نشاطك القادم', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              upcoming == null
                  ? 'لا توجد أنشطة قادمة مجدولة.'
                  : '${upcoming.title} — ${_formatClock(upcoming.reminderHour!, upcoming.reminderMinute!)}',
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
