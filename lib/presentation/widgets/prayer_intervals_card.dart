import 'package:flutter/material.dart';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/prayer_schedule.dart';

/// فترات بين الصلوات + من العشاء إلى فجر الغد (بدون تكرار أوقات الصلاة).
class PrayerIntervalsCard extends StatelessWidget {
  const PrayerIntervalsCard({super.key, required this.schedule});

  final PrayerSchedule schedule;

  String _formatBetween(Duration d) {
    if (d.isNegative) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '$h ساعة و $m دقيقة';
    }
    return '$m دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final prayers = schedule.today;
    if (prayers.length < 2) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final rowMain = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        );
    final rowValue = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        );

    final rows = <Widget>[];
    for (var i = 0; i < prayers.length - 1; i++) {
      final cur = prayers[i];
      final next = prayers[i + 1];
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'من ${cur.phase.arabicName} إلى ${next.phase.arabicName}',
                  style: rowMain,
                ),
              ),
              Text(
                _formatBetween(next.time.difference(cur.time)),
                style: rowValue,
              ),
            ],
          ),
        ),
      );
    }

    final isha = prayers.firstWhere((p) => p.phase == PrayerPhase.isha);
    final fajrNext = schedule.tomorrowFajr;
    rows.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'من ${isha.phase.arabicName} إلى فجر الغد',
                style: rowMain,
              ),
            ),
            Text(
              _formatBetween(fajrNext.time.difference(isha.time)),
              style: rowValue,
            ),
          ],
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفترات بين الصلوات',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}
