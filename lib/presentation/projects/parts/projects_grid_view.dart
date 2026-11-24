import 'package:flutter/material.dart';

import 'project_grid_card.dart';
import 'project_models.dart';

class ProjectsGridView extends StatelessWidget {
  const ProjectsGridView({
    super.key,
    required this.projects,
    required this.onSelectProject,
    required this.onOpenTemplates,
    required this.onNewProject,
  });

  final List<ProjectAggregate> projects;
  final ValueChanged<ProjectAggregate> onSelectProject;
  final VoidCallback onOpenTemplates;
  final VoidCallback onNewProject;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final proj = projects[index];
        return ProjectGridCard(
          project: proj,
          onTap: () => onSelectProject(proj),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 52, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'لا توجد مشاريع مضافة حتى الآن',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قسّم أهدافك الكبرى إلى جوانب ومهام محددة للمتابعة والإنجاز.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpenTemplates,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('قوالب جاهزة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNewProject,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('مشروع جديد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
