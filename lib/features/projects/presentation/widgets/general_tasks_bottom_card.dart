import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/domain/entities/activity_item.dart';
import 'project_task_tile.dart';

class GeneralTasksBottomCard extends StatefulWidget {
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
  State<GeneralTasksBottomCard> createState() => _GeneralTasksBottomCardState();
}

class _GeneralTasksBottomCardState extends State<GeneralTasksBottomCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final doneCount = widget.tasks.where((a) {
      return a.repetition == ActivityRepetition.once
          ? a.historyDates.isNotEmpty
          : a.isDoneOn(todayStr);
    }).length;

    return RepaintBoundary(
      child: Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inbox_rounded,
                          size: 19,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مهام عامة (غير مرتبطة بمشروع)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '$doneCount من ${widget.tasks.length} مهام مكتملة',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                        for (var i = 0; i < widget.tasks.length; i++) ...[
                          ProjectTaskTile(
                            task: widget.tasks[i],
                            onToggleDone: () =>
                                widget.onToggleDone(widget.tasks[i]),
                            onOpenDetails: () =>
                                widget.onOpenDetails(widget.tasks[i]),
                          ),
                          if (i < widget.tasks.length - 1)
                            Divider(
                              height: 0.6,
                              thickness: 0.6,
                              indent: 52,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.07),
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
