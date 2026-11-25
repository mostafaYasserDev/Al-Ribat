import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import 'anchored_popover.dart';

/// Apple/Telegram anchored popover showing task summary and clean action rows.
Future<void> showProjectTaskPopover(
  BuildContext anchorContext, {
  required ActivityItem activity,
  required String dateStr,
  required VoidCallback onToggleDone,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onAddProgress,
}) {
  return showAnchoredPopover<void>(
    anchorContext,
    width: 264,
    preferAbove: true,
    anchorRadius: 10,
    builder: (ctx) => _TaskPopoverBody(
      activity: activity,
      dateStr: dateStr,
      onToggleDone: onToggleDone,
      onEdit: onEdit,
      onDelete: onDelete,
      onAddProgress: onAddProgress,
    ),
  );
}

class _TaskPopoverBody extends StatelessWidget {
  const _TaskPopoverBody({
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
    final colorScheme = theme.colorScheme;
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);

    final isDone = activity.repetition == ActivityRepetition.once
        ? activity.historyDates.isNotEmpty
        : activity.isDoneOn(dateStr);
    final iconColor =
        AppIcons.parseColor(activity.colorHex) ?? colorScheme.primary;

    final metaParts = <String>[
      _repetitionLabel(activity.repetition),
      if (activity.linkedPrayer != null) activity.linkedPrayer!.arabicName,
      if (activity.isMeasurable && activity.targetGoal != null)
        '${activity.getProgressOn(dateStr).toInt()}/${activity.targetGoal!.toInt()} ${activity.goalUnit ?? ""}',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.getIconData(activity.iconName),
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metaParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (activity.description != null &&
            activity.description!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
            child: Text(
              activity.description!.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        Divider(height: 0.6, thickness: 0.6, color: dividerColor),
        PopoverActionRow(
          icon:
              isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
          color: isDone ? const Color(0xFFFF9500) : const Color(0xFF34C759),
          label: isDone ? 'التراجع عن الإنجاز' : 'تم الإنجاز',
          onTap: onToggleDone,
        ),
        if (activity.isMeasurable && activity.targetGoal != null) ...[
          Divider(height: 0.6, thickness: 0.6, indent: 52, color: dividerColor),
          PopoverActionRow(
            icon: Icons.add_chart_rounded,
            color: const Color(0xFF007AFF),
            label: 'إضافة تقدم',
            onTap: onAddProgress,
          ),
        ],
        Divider(height: 0.6, thickness: 0.6, indent: 52, color: dividerColor),
        PopoverActionRow(
          icon: Icons.edit_outlined,
          color: const Color(0xFF007AFF),
          label: 'تعديل المهمة',
          onTap: onEdit,
        ),
        Divider(height: 0.6, thickness: 0.6, indent: 52, color: dividerColor),
        PopoverActionRow(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFFF3B30),
          label: 'حذف المهمة',
          isDestructive: true,
          onTap: onDelete,
        ),
      ],
    );
  }
}
