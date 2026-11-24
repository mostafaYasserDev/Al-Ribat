part of '../home_screen.dart';

class _HomeSelectedActivitiesSection extends StatelessWidget {
  const _HomeSelectedActivitiesSection({
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
  final PrayerPhase? selectedPhase;
  final ValueChanged<PrayerPhase> onAddForPhase;

  Widget _buildTile(ActivityItem act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = selectedPhase ?? PrayerPhase.fajr;
    final phaseActs = activitiesForPhase(activities, phase, selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مهام صلاة ${phase.arabicName}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => onAddForPhase(phase),
              icon: const Icon(Icons.add, size: 18),
              label: Text('إضافة لـ${phase.arabicName}'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (phaseActs.isEmpty)
          _buildEmptyState(
            context,
            title: 'لا توجد مهام مرتبطة بصلاة ${phase.arabicName}',
            subtitle: 'أضف ورداً أو سنة أو مهمة بعد أو قبل الصلاة لتنظيم وقتك.',
            onAdd: () => onAddForPhase(phase),
          )
        else
          ...phaseActs.map(_buildTile),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.playlist_add_check_circle_outlined,
            size: 40,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('أضف نشاطاً الآن'),
          ),
        ],
      ),
    );
  }
}

class _HomeIndependentActivitiesSection extends StatelessWidget {
  const _HomeIndependentActivitiesSection({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final indActs = independentActivities(activities, selectedDate);
    if (indActs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingActs =
        indActs.where((a) => !a.historyDates.contains(todayStr)).toList();
    final completedActs =
        indActs.where((a) => a.historyDates.contains(todayStr)).toList();

    final allDone = pendingActs.isEmpty && completedActs.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: allDone
                      ? Colors.green.withValues(alpha: 0.15)
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  allDone ? Icons.check_circle_rounded : Icons.star_rounded,
                  size: 16,
                  color: allDone
                      ? Colors.green.shade700
                      : colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'المهام الحرة (طوال اليوم)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: allDone
                      ? Colors.green.withValues(alpha: 0.12)
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  allDone ? 'مكتملة ✓' : '${pendingActs.length} متبقية',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: allDone
                        ? Colors.green.shade700
                        : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddIndependent,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Pending activities first
          ...pendingActs.map(_buildTile),
          // Completed activities shown cleanly with their green completed card style
          ...completedActs.map(_buildTile),
        ],
      ),
    );
  }
}
