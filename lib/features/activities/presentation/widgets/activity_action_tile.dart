import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/core/ui_confirm.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/presentation/widgets/activity_add_progress_sheet.dart';
import 'package:al_ribat/presentation/widgets/activity_details_sheet.dart';
import 'package:al_ribat/presentation/widgets/add_activity_sheet.dart';

class ActivityActionTile extends StatelessWidget {
  const ActivityActionTile({
    super.key,
    required this.activity,
    required this.dateStr,
    required this.onToggleDone,
    required this.onToggleSkip,
    required this.onDelete,
    required this.onUpdate,
    required this.onAddProgress,
    this.isInsideGradientCard = false,
  });

  final ActivityItem activity;
  final String dateStr;
  final Future<void> Function(ActivityItem, String) onToggleDone;
  final Future<void> Function(ActivityItem, String) onToggleSkip;
  final Future<void> Function(ActivityItem) onDelete;
  final Future<void> Function(ActivityItem) onUpdate;
  final Future<void> Function(ActivityItem, String, double) onAddProgress;
  final bool isInsideGradientCard;

  static String formatProgress(double p) {
    return p == p.toInt() ? p.toInt().toString() : p.toStringAsFixed(1);
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ActivityDetailsSheet(
        activity: activity,
        dateStr: dateStr,
        onToggleDone: () async {
          Navigator.pop(ctx);
          await _handleToggleDoneDirect(context);
        },
        onToggleSkip: () async {
          Navigator.pop(ctx);
          HapticFeedback.selectionClick();
          await onToggleSkip(activity, dateStr);
        },
        onEdit: () async {
          Navigator.pop(ctx);
          await _handleEdit(context);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          await _handleDelete(context);
        },
        onAddProgress: () {
          Navigator.pop(ctx);
          _showAddProgressDialog(context);
        },
      ),
    );
  }

  Future<void> _handleToggleDoneDirect(BuildContext context) async {
    HapticFeedback.selectionClick();
    final wasDone = activity.isDoneOn(dateStr);
    await onToggleDone(activity, dateStr);
    if (!context.mounted) return;
    if (!wasDone) {
      appSnack(
        context,
        'تم إنجاز "${activity.title}" ✓',
        actionLabel: 'تراجع',
        onAction: () => onToggleDone(activity, dateStr),
      );
    } else {
      appSnack(context, 'تم التراجع عن إنجاز "${activity.title}"');
    }
  }

  void _showAddProgressDialog(BuildContext context) {
    ActivityAddProgressSheet.show(
      context,
      activity: activity,
      dateStr: dateStr,
      onAdd: (val) async {
        onAddProgress(activity, dateStr, val);
        if (context.mounted) {
          appSnack(context,
              'تمت إضافة $val ${activity.goalUnit ?? ""} إلى "${activity.title}"');
        }
      },
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final option = await showActivityDeleteOptions(context, activity.title);
    if (option == null || !context.mounted) return;
    switch (option) {
      case ActivityDeleteOption.skipToday:
        await onToggleSkip(activity, dateStr);
        break;
      case ActivityDeleteOption.endFuture:
        final current = DateTime.tryParse(dateStr) ?? DateTime.now();
        final prev = DateTime(current.year, current.month, current.day - 1);
        final prevStr =
            "${prev.year.toString().padLeft(4, '0')}-${prev.month.toString().padLeft(2, '0')}-${prev.day.toString().padLeft(2, '0')}";
        await onUpdate(activity.copyWith(endDate: prevStr));
        break;
      case ActivityDeleteOption.deleteCompletely:
        await onDelete(activity);
        break;
    }
    if (context.mounted) appSnack(context, 'تم تنفيذ الإجراء بنجاح.');
  }

  Future<void> _handleEdit(BuildContext context) async {
    final updated = await showModalBottomSheet<ActivityItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddActivitySheet(
        initialActivity: activity,
        onSave: (edited) async {
          Navigator.of(ctx).pop(edited);
          return true;
        },
      ),
    );
    if (updated != null) {
      await onUpdate(updated);
    }
  }

  String _buildSubtitle(BuildContext context) {
    final parts = <String>[];
    if (activity.projectName != null && activity.projectName!.isNotEmpty) {
      parts.add('[${activity.projectName}]');
    }
    if (activity.reminderHour != null && activity.reminderMinute != null) {
      parts.add(
        TimeOfDay(
                hour: activity.reminderHour!, minute: activity.reminderMinute!)
            .format(context),
      );
    }
    if (activity.description != null && activity.description!.isNotEmpty) {
      parts.add(activity.description!);
    }
    return parts.isEmpty ? 'نشاط حر' : parts.join(' · ');
  }

  Widget _buildCardContent(
    BuildContext context,
    Color? titleColor,
    bool isDone,
    bool isSkipped,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor =
        AppIcons.parseColor(activity.colorHex) ?? colorScheme.primary;

    return InkWell(
      onTap: () => _showDetailsSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => _handleToggleDoneDirect(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: isDone
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('done'),
                          color: Colors.green,
                          size: 24,
                        )
                      : (isSkipped
                          ? const Icon(
                              Icons.skip_next_rounded,
                              key: ValueKey('skipped'),
                              color: Colors.orange,
                              size: 24,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              key: const ValueKey('pending'),
                              color: colorScheme.outline,
                              size: 24,
                            )),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (activity.iconName != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.getIconData(activity.iconName),
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activity.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : (isSkipped ? TextDecoration.lineThrough : null),
                      decorationColor: isDone ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isInsideGradientCard &&
                              theme.brightness != Brightness.light
                          ? const Color(0xFFD0D7DE)
                          : colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activity.isMeasurable && activity.targetGoal != null) ...[
                    const SizedBox(height: 6),
                    _buildProgressBar(context),
                  ],
                ],
              ),
            ),
            if (activity.isMeasurable)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                tooltip: 'إضافة تقدم',
                color: colorScheme.primary,
                onPressed: () => _showAddProgressDialog(context),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              onPressed: () => _showDetailsSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final current = activity.getProgressOn(dateStr);
    final target = activity.targetGoal!;
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = current >= target;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${formatProgress(current)}/${formatProgress(target)} ${activity.goalUnit ?? ""}',
          style: TextStyle(
            fontSize: 10,
            color: isComplete
                ? Colors.green
                : Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = activity.isDoneOn(dateStr);
    final isSkipped = activity.isSkippedOn(dateStr);
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;

    Color? titleColor;
    Color bgColor;
    Color borderColor;

    if (isDone) {
      titleColor = light ? const Color(0xFF8A9590) : const Color(0xFFB8C4D4);
      bgColor = light ? const Color(0xFFF0FDF4) : const Color(0xFF0D2416);
      borderColor = Colors.green.withValues(alpha: 0.25);
    } else if (isSkipped) {
      titleColor = Colors.orange;
      bgColor = light ? const Color(0xFFFFFBEB) : const Color(0xFF261D0C);
      borderColor = Colors.orange.withValues(alpha: 0.3);
    } else if (isInsideGradientCard && !light) {
      titleColor = const Color(0xFFF2F6FC);
      bgColor = Colors.black.withValues(alpha: 0.25);
      borderColor = Colors.white12;
    } else {
      bgColor = colorScheme.surfaceContainerHighest
          .withValues(alpha: light ? 0.45 : 0.25);
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.35);
    }

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: _buildCardContent(context, titleColor, isDone, isSkipped),
    );

    return Slidable(
      key: ValueKey('${activity.id}_$dateStr'),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _handleToggleDoneDirect(context),
            backgroundColor: isDone ? Colors.grey : Colors.green,
            foregroundColor: Colors.white,
            icon: isDone ? Icons.undo : Icons.done,
            label: isDone ? 'تراجع' : 'إنجاز',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (!isDone)
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.selectionClick();
                onToggleSkip(activity, dateStr);
              },
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: isSkipped ? Icons.undo : Icons.skip_next,
              label: isSkipped ? 'إلغاء' : 'تخطي',
              borderRadius: BorderRadius.circular(16),
            ),
          SlidableAction(
            onPressed: (_) => _handleDelete(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (_) => _handleEdit(context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: cardWidget,
    );
  }
}
