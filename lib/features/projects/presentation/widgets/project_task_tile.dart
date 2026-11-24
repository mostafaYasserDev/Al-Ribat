import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';

class ProjectTaskTile extends StatelessWidget {
  const ProjectTaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onOpenDetails,
  });

  final ActivityItem task;
  final VoidCallback onToggleDone;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isDone = task.repetition == ActivityRepetition.once
        ? task.historyDates.isNotEmpty
        : task.isDoneOn(todayStr);
    final iconColor = AppIcons.parseColor(task.colorHex) ?? colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color:
            isDone ? Colors.green.withValues(alpha: 0.08) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? Colors.green.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: onToggleDone,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      key: ValueKey<bool>(isDone),
                      color: isDone
                          ? Colors.green
                          : colorScheme.outline.withValues(alpha: 0.7),
                      size: 21,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.getIconData(task.iconName),
                  size: 15,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                  child: Text(task.title),
                ),
              ),
              if (task.isMeasurable) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${task.getProgressOn(todayStr).toInt()}/${task.targetGoal?.toInt() ?? 1} ${task.goalUnit ?? ""}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.more_vert_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
