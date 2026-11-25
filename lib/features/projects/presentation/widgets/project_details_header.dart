import 'package:flutter/material.dart';

import '../../domain/project_aggregate.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final color = project.color;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.07),
            width: 0.7,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${project.groups.length} مجموعات • ${project.completedTasks} من ${project.totalTasks} مهام منجزة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                        ? const Color(0xFF34C759).withValues(alpha: 0.14)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(project.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color:
                          project.isCompleted ? const Color(0xFF34C759) : color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: project.progress),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (ctx, val, _) => LinearProgressIndicator(
                  value: val,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.65),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    project.isCompleted ? const Color(0xFF34C759) : color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
