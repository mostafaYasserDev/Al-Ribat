import 'package:flutter/material.dart';

import '../../core/constants/prayer_phase.dart';
import '../../core/theme/app_icons.dart';
import '../../domain/entities/activity_item.dart';

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

    final progress = activity.getProgressOn(dateStr);
    final target = activity.targetGoal ?? 1.0;
    final progressFraction =
        target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Icon + Title + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.getIconData(activity.iconName),
                      color: iconColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        if (activity.description != null &&
                            activity.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            activity.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.15)
                          : (isSkipped
                              ? Colors.orange.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : (isSkipped
                                  ? Icons.skip_next_rounded
                                  : Icons.hourglass_top_rounded),
                          size: 14,
                          color: isDone
                              ? Colors.green
                              : (isSkipped
                                  ? Colors.orange
                                  : colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDone
                              ? 'مكتمل اليوم'
                              : (isSkipped ? 'متخطى' : 'قيد الانتظار'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? Colors.green
                                : (isSkipped
                                    ? Colors.orange
                                    : colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Badges Section (Prayer, Project, Group, Reminder)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (activity.linkedPrayer != null)
                    _buildInfoChip(
                      icon: Icons.mosque_rounded,
                      label: 'مرتبط بصلاة ${activity.linkedPrayer!.arabicName}',
                      color: colorScheme.primary,
                    ),
                  if (activity.projectName != null &&
                      activity.projectName!.isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.folder_outlined,
                      label: activity.projectName!,
                      color: colorScheme.secondary,
                    ),
                  if (activity.groupName != null &&
                      activity.groupName!.isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.tag_rounded,
                      label: activity.groupName!,
                      color: colorScheme.tertiary,
                    ),
                  if (activity.reminderHour != null &&
                      activity.reminderMinute != null)
                    _buildInfoChip(
                      icon: Icons.notifications_active_outlined,
                      label:
                          'تنبيه: ${TimeOfDay(hour: activity.reminderHour!, minute: activity.reminderMinute!).format(context)}',
                      color: Colors.amber.shade800,
                    ),
                  _buildInfoChip(
                    icon: Icons.repeat_rounded,
                    label: _repetitionLabel(activity.repetition),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Measurable Progress Section (if measurable)
              if (activity.isMeasurable) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الهدف اليومي الرقمي',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_formatNum(progress)} / ${_formatNum(target)} ${activity.goalUnit ?? ""}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 6,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressFraction >= 1.0
                                ? Colors.green
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: onAddProgress,
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('إضافة تقدم'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.12),
                            foregroundColor: colorScheme.primary,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // History & Total stats row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.checklist_rounded,
                      title: 'مرات الإنجاز',
                      value: '${activity.historyDates.length} يوم',
                      colorScheme: colorScheme,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    _buildStatItem(
                      icon: Icons.calendar_today_rounded,
                      title: 'تاريخ الإنشاء',
                      value:
                          activity.createdAt.toIso8601String().split('T').first,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row (Edit, Skip, Delete)
              Row(
                children: [
                  // Toggle Done button
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onToggleDone,
                      icon: Icon(
                          isDone ? Icons.undo_rounded : Icons.check_rounded,
                          size: 18),
                      label: Text(isDone ? 'تراجع' : 'إنجاز'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isDone ? Colors.grey.shade700 : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Skip button
                  if (!isDone) ...[
                    OutlinedButton.icon(
                      onPressed: onToggleSkip,
                      icon: Icon(
                          isSkipped
                              ? Icons.undo_rounded
                              : Icons.skip_next_rounded,
                          size: 18),
                      label: Text(isSkipped ? 'إلغاء التخطي' : 'تخطي'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Edit button
                  IconButton.outlined(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    style: IconButton.styleFrom(
                      side: BorderSide(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.6)),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    tooltip: 'تعديل',
                  ),
                  const SizedBox(width: 8),

                  // Delete button
                  IconButton.outlined(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red.shade700),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.08),
                      side:
                          BorderSide(color: Colors.red.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatNum(double n) {
    return n == n.toInt() ? n.toInt().toString() : n.toStringAsFixed(1);
  }

  static String _repetitionLabel(ActivityRepetition rep) {
    switch (rep) {
      case ActivityRepetition.once:
        return 'مرة واحدة';
      case ActivityRepetition.daily:
        return 'تكرار يومي';
      case ActivityRepetition.weekly:
        return 'تكرار أسبوعي';
      case ActivityRepetition.monthly:
        return 'تكرار شهري';
    }
  }
}
