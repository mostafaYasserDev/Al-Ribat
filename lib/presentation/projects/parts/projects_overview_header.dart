import 'package:flutter/material.dart';

import 'project_models.dart';

class ProjectsOverviewHeader extends StatelessWidget {
  const ProjectsOverviewHeader({
    super.key,
    required this.projects,
    required this.onOpenTemplates,
  });

  final List<ProjectAggregate> projects;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalTasks = projects.fold(0, (s, p) => s + p.totalTasks);
    final completedTasks = projects.fold(0, (s, p) => s + p.completedTasks);
    final double overallProgress =
        totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.rocket_launch_rounded,
                    color: colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنجاز المشاريع والأهداف',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${projects.length} مشاريع • $completedTasks من $totalTasks مهمة منجزة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(overallProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: overallProgress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 5,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
