import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/stats_snapshot.dart';

part 'stats_insights_card.dart';
part 'stats_row_widgets.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _InsightsCard(stats: stats),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.task_alt,
            title: 'أنشطة مكتملة هذا الأسبوع',
            value: '${stats.weeklyCompleted}',
          ),
          _StatRow(
            icon: Icons.calendar_month,
            title: 'أنشطة مكتملة هذا الشهر',
            value: '${stats.monthlyCompleted}',
          ),
          _StatRow(
            icon: Icons.menu_book_outlined,
            title: 'تأملات هذا الشهر',
            value: '${stats.reflectionsThisMonth}',
          ),
          _StatRow(
            icon: Icons.timelapse,
            title: 'جلسات تركيز مكتملة (أسبوع)',
            value: '${stats.workSessionsThisWeek}',
          ),
          _StatRow(
            icon: Icons.hourglass_bottom,
            title: 'دقائق التركيز (أسبوع)',
            value: '${stats.focusMinutesThisWeek}',
          ),
          _StatRow(
            icon: Icons.event_repeat,
            title: 'تسجيل عادات هذا الأسبوع',
            value: '${stats.habitsMarkedThisWeek}',
          ),
          const SizedBox(height: 18),
          Text('المهام حسب الصلاة',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...PrayerPhase.values.map(
            (phase) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PhaseProgress(
                name: phase.arabicName,
                value: stats.byPhase[phase] ?? 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
