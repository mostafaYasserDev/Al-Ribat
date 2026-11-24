import 'package:flutter/material.dart';

import '../parts/project_models.dart';

class ProjectDetailsHeader extends StatelessWidget {
  const ProjectDetailsHeader({
    super.key,
    required this.project,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectAggregate project;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = project.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(project.icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${project.groups.length} مجموعات • ${project.completedTasks} من ${project.totalTasks} مهام منجزة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: project.isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(project.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: project.isCompleted ? Colors.green.shade700 : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: project.progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  project.isCompleted ? Colors.green : color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
