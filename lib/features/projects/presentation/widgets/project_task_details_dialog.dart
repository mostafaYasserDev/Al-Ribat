import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';

/// Apple-style Scale+Fade popup dialog showing task details & quick actions.
Future<void> showProjectTaskDetailsDialog(
  BuildContext context, {
  required ActivityItem activity,
  required String dateStr,
  required VoidCallback onToggleDone,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onAddProgress,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _ProjectTaskDetailsDialog(
      activity: activity,
      dateStr: dateStr,
      onToggleDone: onToggleDone,
      onEdit: onEdit,
      onDelete: onDelete,
      onAddProgress: onAddProgress,
    ),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ProjectTaskDetailsDialog extends StatelessWidget {
  const _ProjectTaskDetailsDialog({
    required this.activity,
    required this.dateStr,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
    required this.onAddProgress,
  });

  final ActivityItem activity;
  final String dateStr;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddProgress;

  String _repetitionLabel(ActivityRepetition rep) {
    switch (rep) {
      case ActivityRepetition.daily:
        return 'يومي';
      case ActivityRepetition.weekly:
        return 'أسبوعي';
      case ActivityRepetition.monthly:
        return 'شهري';
      case ActivityRepetition.once:
        return 'مرة واحدة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final innerCardBg = isDark
        ? const Color(0xFF0A101D)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);

    final isDone = activity.repetition == ActivityRepetition.once
        ? activity.historyDates.isNotEmpty
        : activity.isDoneOn(dateStr);
    final iconColor =
        AppIcons.parseColor(activity.colorHex) ?? colorScheme.primary;

    final metaRows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.repeat_rounded,
        label: 'التكرار',
        value: _repetitionLabel(activity.repetition),
      ),
      if (activity.linkedPrayer != null)
        (
          icon: Icons.mosque_rounded,
          label: 'الصلاة',
          value: activity.linkedPrayer!.arabicName,
        ),
      if (activity.projectName != null && activity.projectName!.isNotEmpty)
        (
          icon: Icons.folder_outlined,
          label: 'المشروع',
          value: activity.groupName != null && activity.groupName!.isNotEmpty
              ? '${activity.projectName!} · ${activity.groupName!}'
              : activity.projectName!,
        ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              elevation: 16,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.getIconData(activity.iconName),
                            color: iconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (activity.description != null &&
                                  activity.description!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  activity.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: innerCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface
                              .withValues(alpha: isDark ? 0.08 : 0.06),
                          width: 0.6,
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < metaRows.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    metaRows[i].icon,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    metaRows[i].label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: Text(
                                      metaRows[i].value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < metaRows.length - 1)
                              Divider(
                                height: 0.6,
                                thickness: 0.6,
                                indent: 36,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.07),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (activity.isMeasurable &&
                        activity.targetGoal != null) ...[
                      const SizedBox(height: 12),
                      _MeasurableProgressCard(
                        activity: activity,
                        dateStr: dateStr,
                        innerCardBg: innerCardBg,
                        onAddProgress: onAddProgress,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onToggleDone();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDone
                            ? colorScheme.surfaceContainerHighest
                            : const Color(0xFF34C759),
                        foregroundColor:
                            isDone ? colorScheme.onSurface : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        isDone
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 19,
                      ),
                      label: Text(
                        isDone ? 'التراجع عن الإنجاز' : 'تم الإنجاز',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onEdit();
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('تعديل'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onDelete();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(
                                color:
                                    colorScheme.error.withValues(alpha: 0.35),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('حذف'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasurableProgressCard extends StatelessWidget {
  const _MeasurableProgressCard({
    required this.activity,
    required this.dateStr,
    required this.innerCardBg,
    required this.onAddProgress,
  });

  final ActivityItem activity;
  final String dateStr;
  final Color innerCardBg;
  final VoidCallback onAddProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = activity.getProgressOn(dateStr);
    final target = activity.targetGoal ?? 1;
    final ratio = (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: innerCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم: ${current.toInt()} / ${target.toInt()} ${activity.goalUnit ?? ""}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: onAddProgress,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('إضافة تقدم'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
