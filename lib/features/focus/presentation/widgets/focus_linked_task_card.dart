import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/projects/presentation/widgets/anchored_popover.dart';
import '../../application/active_focus_notifier.dart';

class FocusLinkedTaskCard extends ConsumerStatefulWidget {
  const FocusLinkedTaskCard({
    super.key,
    required this.selectedActivity,
    required this.onSelectActivity,
    required this.onClearActivity,
    this.selectedProjectName,
    this.onSelectProject,
    this.disabled = false,
    this.buttonLabel = 'ربط الجلسة بمهمة أو مشروع',
  });

  final ActivityItem? selectedActivity;
  final String? selectedProjectName;
  final ValueChanged<ActivityItem> onSelectActivity;
  final ValueChanged<String>? onSelectProject;
  final VoidCallback onClearActivity;
  final bool disabled;
  final String buttonLabel;

  @override
  ConsumerState<FocusLinkedTaskCard> createState() =>
      _FocusLinkedTaskCardState();
}

class _FocusLinkedTaskCardState extends ConsumerState<FocusLinkedTaskCard> {
  bool _pressed = false;

  void _showLinkPopover(BuildContext anchorContext) {
    HapticFeedback.lightImpact();
    final raw = ref.read(activitiesProvider).valueOrNull ?? const [];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final activities = List<ActivityItem>.from(raw)
      ..sort((a, b) {
        final aDone = a.isDoneOn(todayStr) ? 1 : 0;
        final bDone = b.isDoneOn(todayStr) ? 1 : 0;
        return aDone.compareTo(bDone);
      });

    final projectCounts = <String, int>{};
    for (final act in raw) {
      final p = act.projectName?.trim();
      if (p != null && p.isNotEmpty) {
        projectCounts[p] = (projectCounts[p] ?? 0) + 1;
      }
    }
    final projects = projectCounts.keys.toList()..sort();

    var showProjectsTab =
        widget.selectedProjectName != null && widget.selectedActivity == null;

    showAnchoredPopover<void>(
      anchorContext,
      width: 340,
      preferAbove: false,
      anchorRadius: 18,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (ctx, setPopoverState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0B1322)
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PopoverSegmentTab(
                              label: 'مهام اليوم (${activities.length})',
                              icon: Icons.check_circle_outline_rounded,
                              selected: !showProjectsTab,
                              onTap: () => setPopoverState(
                                  () => showProjectsTab = false),
                            ),
                          ),
                          Expanded(
                            child: _PopoverSegmentTab(
                              label: 'المشاريع (${projects.length})',
                              icon: Icons.folder_outlined,
                              selected: showProjectsTab,
                              onTap: () =>
                                  setPopoverState(() => showProjectsTab = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 0.6,
                    thickness: 0.6,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  if (!showProjectsTab)
                    _buildTasksList(ctx, theme, activities, todayStr)
                  else
                    _buildProjectsList(ctx, theme, projects, projectCounts),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTasksList(
    BuildContext ctx,
    ThemeData theme,
    List<ActivityItem> activities,
    String todayStr,
  ) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text('لا توجد مهام مسجلة لهذا اليوم'),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: activities.length,
        separatorBuilder: (_, __) => Divider(
          height: 0.6,
          thickness: 0.6,
          indent: 52,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
        itemBuilder: (context, i) {
          final act = activities[i];
          final isDone = act.isDoneOn(todayStr);
          final String subtitleText;
          if (act.isMeasurable) {
            final isTime = ActiveFocusNotifier.isTimeMeasuredActivity(act);
            final unit = act.goalUnit ?? '';
            subtitleText = 'هدف: ${act.targetGoal?.toInt() ?? 0} $unit'
                '${isTime ? ' (تحديث زمني تلقائي)' : ' (توثيق في السجل)'}';
          } else {
            subtitleText = act.projectName ?? 'مهمة يومية';
          }

          return ListTile(
            dense: true,
            title: Text(
              act.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
            subtitle: Text(
              subtitleText,
              style: const TextStyle(fontSize: 11.5),
            ),
            leading: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : (act.isMeasurable
                      ? Icons.track_changes_rounded
                      : Icons.radio_button_unchecked_rounded),
              size: 20,
              color:
                  isDone ? const Color(0xFF34C759) : theme.colorScheme.primary,
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSelectActivity(act);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectsList(
    BuildContext ctx,
    ThemeData theme,
    List<String> projects,
    Map<String, int> projectCounts,
  ) {
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text('لا توجد مشاريع مضافة بعد'),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: projects.length,
        separatorBuilder: (_, __) => Divider(
          height: 0.6,
          thickness: 0.6,
          indent: 52,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
        itemBuilder: (context, i) {
          final project = projects[i];
          final count = projectCounts[project] ?? 0;
          final isSelected = widget.selectedProjectName == project;
          return ListTile(
            dense: true,
            leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_rounded,
                size: 17,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              project,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '$count ${count == 1 ? 'نشاط مرتبط' : 'أنشطة مرتبطة'}',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  )
                : null,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSelectProject?.call(project);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final selectedAct = widget.selectedActivity;
    final selectedProj = widget.selectedProjectName;
    final hasLink = selectedAct != null || selectedProj != null;
    final isProjectLink = selectedAct == null && selectedProj != null;

    final linkLabel = isProjectLink ? 'مشروع مرتبط' : 'مهمة مرتبطة';
    final linkTitle = selectedAct?.title ?? selectedProj ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Builder(
        builder: (anchorCtx) => AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: Material(
            color: hasLink
                ? colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.08)
                : cardColor,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onHighlightChanged: (v) {
                if (!widget.disabled && _pressed != v) {
                  setState(() => _pressed = v);
                }
              },
              onTap: widget.disabled ? null : () => _showLinkPopover(anchorCtx),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hasLink
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.onSurface
                            .withValues(alpha: isDark ? 0.08 : 0.07),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (hasLink
                                ? colorScheme.primary
                                : const Color(0xFF007AFF))
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        isProjectLink
                            ? Icons.folder_rounded
                            : (hasLink
                                ? Icons.link_rounded
                                : Icons.add_link_rounded),
                        size: 18,
                        color: hasLink
                            ? colorScheme.primary
                            : const Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: hasLink
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  linkLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  linkTitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Text(
                              widget.buttonLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                    ),
                    if (!widget.disabled && hasLink)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          widget.onClearActivity();
                        },
                        tooltip: 'إلغاء الربط',
                        visualDensity: VisualDensity.compact,
                      )
                    else if (!widget.disabled)
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                        size: 20,
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

class _PopoverSegmentTab extends StatelessWidget {
  const _PopoverSegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF1A2942) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
