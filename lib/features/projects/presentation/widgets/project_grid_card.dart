import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/project_aggregate.dart';

class ProjectGridCard extends StatefulWidget {
  const ProjectGridCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final ProjectAggregate project;
  final VoidCallback onTap;

  @override
  State<ProjectGridCard> createState() => _ProjectGridCardState();
}

class _ProjectGridCardState extends State<ProjectGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final project = widget.project;
    final color = project.color;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
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
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onHighlightChanged: (v) {
                if (_pressed != v) setState(() => _pressed = v);
              },
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(project.icon, color: color, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: project.isCompleted
                                ? const Color(0xFF34C759)
                                    .withValues(alpha: 0.14)
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(project.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: project.isCompleted
                                  ? const Color(0xFF34C759)
                                  : color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      project.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${project.groups.length} مجموعات • ${project.completedTasks}/${project.totalTasks}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.58),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0.0, end: project.progress),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (ctx, val, _) => LinearProgressIndicator(
                              value: val,
                              minHeight: 4,
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                project.isCompleted
                                    ? const Color(0xFF34C759)
                                    : color,
                              ),
                            ),
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
