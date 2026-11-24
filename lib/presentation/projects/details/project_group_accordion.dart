import 'package:flutter/material.dart';

import '../../../domain/entities/activity_item.dart';
import 'project_task_tile.dart';

class ProjectGroupAccordion extends StatelessWidget {
  const ProjectGroupAccordion({
    super.key,
    required this.groupName,
    this.description,
    required this.tasks,
    required this.color,
    required this.onToggleDone,
    required this.onOpenDetails,
    required this.onAddTask,
  });

  final String groupName;
  final String? description;
  final List<ActivityItem> tasks;
  final Color color;
  final ValueChanged<ActivityItem> onToggleDone;
  final ValueChanged<ActivityItem> onOpenDetails;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doneCount = tasks.where((a) => a.historyDates.isNotEmpty).length;
    final isAllDone = tasks.isNotEmpty && doneCount == tasks.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.1),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bookmark_rounded, size: 18, color: color),
          ),
          title: Text(
            groupName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
          ),
          subtitle: description != null && description!.isNotEmpty
              ? Text(
                  description!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? Colors.green.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tasks.isEmpty ? 'فارغة' : '$doneCount/${tasks.length}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isAllDone
                        ? Colors.green.shade700
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                tooltip: 'إضافة مهمة',
                onPressed: onAddTask,
                color: color,
              ),
            ],
          ),
          children: [
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('أضف أول مهمة في هذا الجانب'),
                ),
              )
            else ...[
              ...tasks.map(
                (task) => ProjectTaskTile(
                  task: task,
                  onToggleDone: () => onToggleDone(task),
                  onOpenDetails: () => onOpenDetails(task),
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('إضافة مهمة جديدة'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
