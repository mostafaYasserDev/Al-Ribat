import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/constants/prayer_phase.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('نظرة ذكية', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stats.feedbackLine,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  if (stats.mostProductivePhase != null)
                    Text('✨ أكثر الأوقات إنتاجية: ${stats.mostProductivePhase!.arabicName}'),
                  if (stats.mostSkippedActivity != null)
                    Text('⚠️ العادة الأكثر تخطياً: ${stats.mostSkippedActivity}'),
                  const SizedBox(height: 6),
                  Text('📈 نسبة الالتزام هذا الأسبوع: ${(stats.completionRateThisWeek * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.task_alt,
            title: 'مهام مكتملة هذا الأسبوع',
            value: '${stats.weeklyCompleted}',
          ),
          _StatRow(
            icon: Icons.calendar_month,
            title: 'مهام مكتملة هذا الشهر',
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
          Text('المهام حسب الصلاة', style: Theme.of(context).textTheme.titleSmall),
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

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}

class _PhaseProgress extends StatelessWidget {
  const _PhaseProgress({required this.name, required this.value});

  final String name;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(name)),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (value / 12).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: track,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$value', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
