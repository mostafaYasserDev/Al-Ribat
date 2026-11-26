import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';

class ActivityDetailsSheet extends StatelessWidget {
  const ActivityDetailsSheet({
    super.key,
    required this.activity,
    required this.dateStr,
    required this.onToggleDone,
    required this.onToggleSkip,
    required this.onEdit,
    required this.onDelete,
    required this.onAddProgress,
  });

  final ActivityItem activity;
  final String dateStr;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleSkip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = activity.isDoneOn(dateStr);
    final isSkipped = activity.isSkippedOn(dateStr);
    final iconColor =
        AppIcons.parseColor(activity.colorHex) ?? colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (activity.iconName != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.getIconData(activity.iconName),
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (activity.description != null &&
                          activity.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          activity.description!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Details metadata rows
            _buildDetailRow(
              context,
              icon: Icons.repeat_rounded,
              label: 'التكرار',
              value: _repetitionLabel(activity.repetition),
            ),
            if (activity.linkedPrayer != null)
              _buildDetailRow(
                context,
                icon: Icons.access_time_rounded,
                label: 'مرتبط بصلاة',
                value: activity.linkedPrayer!.arabicName,
              ),
            if (activity.projectName != null &&
                activity.projectName!.isNotEmpty)
              _buildDetailRow(
                context,
                icon: Icons.folder_open_rounded,
                label: 'المشروع',
                value: activity.projectName!,
              ),
            if (activity.isMeasurable && activity.targetGoal != null) ...[
              const SizedBox(height: 10),
              _buildProgressSection(context),
            ],

            const SizedBox(height: 20),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label:
                        const Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onToggleDone,
              style: FilledButton.styleFrom(
                backgroundColor: isDone ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                  isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
                  size: 20),
              label: Text(isDone ? 'إلغاء الإنجاز' : 'تم الإنجاز اليوم'),
            ),
            if (!isDone) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onToggleSkip,
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                icon: Icon(
                    isSkipped ? Icons.undo_rounded : Icons.skip_next_rounded,
                    size: 18),
                label: Text(isSkipped ? 'إلغاء التخطي' : 'تخطي اليوم'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final cur = activity.getProgressOn(dateStr);
    final tgt = activity.targetGoal!;
    final u = activity.goalUnit ?? '';
    final progress = (cur / tgt).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الهدف اليومي: ${tgt.toInt()} $u',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.bold)),
              Text('المحقق: ${cur.toInt()} $u',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: cur >= tgt ? Colors.green : null,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                cur >= tgt ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddProgress,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('تسجيل تقدم جديد'),
          ),
        ],
      ),
    );
  }

  String _repetitionLabel(ActivityRepetition rep) {
    switch (rep) {
      case ActivityRepetition.once:
        return 'مرة واحدة';
      case ActivityRepetition.daily:
        return 'يومياً';
      case ActivityRepetition.weekly:
        return 'أسبوعياً';
      case ActivityRepetition.monthly:
        return 'شهرياً';
      case ActivityRepetition.open:
        return 'مفتوحة (حتى الإتمام)';
    }
  }
}
