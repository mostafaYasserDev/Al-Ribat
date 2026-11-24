import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../domain/entities/activity_item.dart';

class GeneralTasksBottomCard extends StatelessWidget {
  const GeneralTasksBottomCard({
    super.key,
    required this.tasks,
    required this.onToggleDone,
    required this.onOpenDetails,
  });

  final List<ActivityItem> tasks;
  final ValueChanged<ActivityItem> onToggleDone;
  final ValueChanged<ActivityItem> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final doneCount = tasks.where((a) {
      return a.repetition == ActivityRepetition.once
          ? a.historyDates.isNotEmpty
          : a.isDoneOn(todayStr);
    }).length;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.inbox_rounded, size: 20, color: colorScheme.primary),
          ),
          title: Text(
            'مهام عامة (غير مرتبطة بمشروع)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            '$doneCount من ${tasks.length} مهام مكتملة',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          children: tasks.map((act) {
            final isDone = act.repetition == ActivityRepetition.once
                ? act.historyDates.isNotEmpty
                : act.isDoneOn(todayStr);
            final iconColor =
                AppIcons.parseColor(act.colorHex) ?? colorScheme.primary;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green.withValues(alpha: 0.08)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDone
                      ? Colors.green.withValues(alpha: 0.35)
                      : colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: InkWell(
                onTap: () => onOpenDetails(act),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => onToggleDone(act),
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
                          AppIcons.getIconData(act.iconName),
                          size: 15,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.more_vert_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
