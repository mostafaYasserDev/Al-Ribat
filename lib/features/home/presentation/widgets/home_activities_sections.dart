import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../core/activity_schedule.dart';
import '../../../../core/constants/prayer_phase.dart';
import '../../../../domain/entities/activity_item.dart';
import '../../../../presentation/widgets/activity_action_tile.dart';
import 'home_prayer_hero_card.dart';

class HomePhaseActivitiesSection extends StatelessWidget {
  const HomePhaseActivitiesSection({
    super.key,
    required this.ref,
    required this.activities,
    required this.selectedDate,
    required this.todayStr,
    required this.selectedPhase,
    required this.onAddForPhase,
  });

  final WidgetRef ref;
  final List<ActivityItem> activities;
  final DateTime selectedDate;
  final String todayStr;
  final PrayerPhase selectedPhase;
  final ValueChanged<PrayerPhase> onAddForPhase;

  Widget _buildTile(ActivityItem act) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: ActivityActionTile(
          activity: act,
          dateStr: todayStr,
          onToggleDone: (a, d) =>
              ref.read(activitiesProvider.notifier).toggleDone(a, d),
          onAddProgress: (a, d, val) =>
              ref.read(activitiesProvider.notifier).addProgress(a, d, val),
          onToggleSkip: (a, d) =>
              ref.read(activitiesProvider.notifier).toggleSkip(a, d),
          onDelete: (a) =>
              ref.read(activitiesProvider.notifier).deleteActivity(a.id),
          onUpdate: (a) =>
              ref.read(activitiesProvider.notifier).updateActivity(a),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phaseActs =
        activitiesForPhase(activities, selectedPhase, selectedDate);
    final visual = prayerPhaseVisual(selectedPhase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(visual.icon, size: 16, color: visual.color),
            ),
            const SizedBox(width: 9),
            Text(
              'مهام صلاة ${selectedPhase.arabicName}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (phaseActs.isNotEmpty) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${phaseActs.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: visual.color,
                  ),
                ),
              ),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAddForPhase(selectedPhase);
              },
              icon: const Icon(Icons.add_rounded, size: 17),
              label: Text('إضافة لـ${selectedPhase.arabicName}'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 210),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(selectedPhase),
            child: phaseActs.isEmpty
                ? _buildEmptyState(
                    context,
                    visual: visual,
                    title:
                        'لا توجد مهام مرتبطة بصلاة ${selectedPhase.arabicName}',
                    subtitle:
                        'أضف ورداً أو سنة أو مهمة بعد أو قبل الصلاة لتنظيم وقتك.',
                    onAdd: () => onAddForPhase(selectedPhase),
                  )
                : Column(
                    children: phaseActs.map(_buildTile).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required ({IconData icon, Color color}) visual,
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.07),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(visual.icon, size: 26, color: visual.color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.58),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('أضف نشاطاً الآن'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeIndependentActivitiesSection extends StatelessWidget {
  const HomeIndependentActivitiesSection({
    super.key,
    required this.ref,
    required this.activities,
    required this.selectedDate,
    required this.todayStr,
    required this.onAddIndependent,
  });

  final WidgetRef ref;
  final List<ActivityItem> activities;
  final DateTime selectedDate;
  final String todayStr;
  final VoidCallback onAddIndependent;

  Widget _buildTile(ActivityItem act) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: ActivityActionTile(
          activity: act,
          dateStr: todayStr,
          onToggleDone: (a, d) =>
              ref.read(activitiesProvider.notifier).toggleDone(a, d),
          onAddProgress: (a, d, val) =>
              ref.read(activitiesProvider.notifier).addProgress(a, d, val),
          onToggleSkip: (a, d) =>
              ref.read(activitiesProvider.notifier).toggleSkip(a, d),
          onDelete: (a) =>
              ref.read(activitiesProvider.notifier).deleteActivity(a.id),
          onUpdate: (a) =>
              ref.read(activitiesProvider.notifier).updateActivity(a),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final indActs = independentActivities(activities, selectedDate);
    if (indActs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final pendingCount =
        indActs.where((a) => !a.historyDates.contains(todayStr)).length;
    final allDone = pendingCount == 0 && indActs.isNotEmpty;
    final badgeColor =
        allDone ? const Color(0xFF34C759) : const Color(0xFF007AFF);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  allDone ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                  size: 16,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'المهام الحرة (طوال اليوم)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  allDone ? 'مكتملة ✓' : '$pendingCount متبقية',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAddIndependent();
                },
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('إضافة'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...indActs.map(_buildTile),
        ],
      ),
    );
  }
}
