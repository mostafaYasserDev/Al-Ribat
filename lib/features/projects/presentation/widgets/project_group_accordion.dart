import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/domain/entities/activity_item.dart';
import 'project_task_tile.dart';

class ProjectGroupAccordion extends StatefulWidget {
  const ProjectGroupAccordion({
    super.key,
    required this.groupName,
    this.description,
    required this.tasks,
    required this.color,
    required this.onToggleDone,
    required this.onOpenDetails,
    required this.onAddTask,
    this.onRenameGroup,
  });

  final String groupName;
  final String? description;
  final List<ActivityItem> tasks;
  final Color color;
  final ValueChanged<ActivityItem> onToggleDone;
  final void Function(ActivityItem task, BuildContext anchorContext)
      onOpenDetails;
  final VoidCallback onAddTask;
  final void Function(BuildContext anchorContext)? onRenameGroup;

  @override
  State<ProjectGroupAccordion> createState() => _ProjectGroupAccordionState();
}

class _ProjectGroupAccordionState extends State<ProjectGroupAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final doneCount =
        widget.tasks.where((a) => a.historyDates.isNotEmpty).length;
    final isAllDone =
        widget.tasks.isNotEmpty && doneCount == widget.tasks.length;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.07),
            width: 0.7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.bookmark_rounded,
                          size: 17,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.groupName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            if (widget.description != null &&
                                widget.description!.isNotEmpty)
                              Text(
                                widget.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11.5,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.58),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.onRenameGroup != null) ...[
                        const SizedBox(width: 4),
                        Builder(
                          builder: (renameCtx) => InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onRenameGroup!(renameCtx);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isAllDone
                              ? const Color(0xFF34C759).withValues(alpha: 0.14)
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.tasks.isEmpty
                              ? 'فارغة'
                              : '$doneCount/${widget.tasks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAllDone
                                ? const Color(0xFF34C759)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        tooltip: 'إضافة مهمة',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onAddTask();
                        },
                        color: widget.color,
                        visualDensity: VisualDensity.compact,
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(
                          height: 0.6,
                          thickness: 0.6,
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                        if (widget.tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: TextButton.icon(
                              onPressed: widget.onAddTask,
                              icon: const Icon(Icons.add_rounded, size: 17),
                              label: const Text('أضف أول مهمة في هذا الجانب'),
                            ),
                          )
                        else ...[
                          for (var i = 0; i < widget.tasks.length; i++) ...[
                            ProjectTaskTile(
                              task: widget.tasks[i],
                              onToggleDone: () =>
                                  widget.onToggleDone(widget.tasks[i]),
                              onOpenDetails: (anchorCtx) => widget
                                  .onOpenDetails(widget.tasks[i], anchorCtx),
                            ),
                            if (i < widget.tasks.length - 1)
                              Divider(
                                height: 0.6,
                                thickness: 0.6,
                                indent: 52,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.07),
                              ),
                          ],
                          Divider(
                            height: 0.6,
                            thickness: 0.6,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.07),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onAddTask();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 17,
                                    color: widget.color,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'إضافة مهمة جديدة',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: widget.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
