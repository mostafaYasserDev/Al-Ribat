import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/presentation/widgets/activity_add_progress_sheet.dart';
import 'package:al_ribat/presentation/widgets/add_activity_sheet.dart';
import 'project_task_details_dialog.dart';

class ProjectTaskActions {
  static Future<void> toggleDone(
    BuildContext context,
    WidgetRef ref,
    ActivityItem task,
  ) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final d =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final wasDone = task.isSingleCompletion
        ? task.historyDates.isNotEmpty
        : task.isDoneOn(d);
    await ref.read(activitiesProvider.notifier).toggleDone(task, d);
    if (!context.mounted) return;
    if (!wasDone) {
      appSnack(
        context,
        'تم إنجاز "${task.title}" ✓',
        actionLabel: 'تراجع',
        onAction: () =>
            ref.read(activitiesProvider.notifier).toggleDone(task, d),
      );
    } else {
      appSnack(context, 'تم التراجع عن إنجاز "${task.title}"');
    }
  }

  static void openDetails(
    BuildContext anchorContext,
    WidgetRef ref,
    ActivityItem act,
  ) {
    final now = DateTime.now();
    final d =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    showProjectTaskPopover(
      anchorContext,
      activity: act,
      dateStr: d,
      onToggleDone: () async {
        Navigator.pop(anchorContext);
        await toggleDone(anchorContext, ref, act);
      },
      onEdit: () {
        Navigator.pop(anchorContext);
        editActivity(anchorContext, ref, act);
      },
      onDelete: () async {
        Navigator.pop(anchorContext);
        await ref.read(activitiesProvider.notifier).deleteActivity(act.id);
        if (anchorContext.mounted) appSnack(anchorContext, 'تم حذف المهمة.');
      },
      onAddProgress: () {
        Navigator.pop(anchorContext);
        ActivityAddProgressSheet.show(
          anchorContext,
          activity: act,
          dateStr: d,
          onAdd: (val) async {
            await ref
                .read(activitiesProvider.notifier)
                .addProgress(act, d, val);
            if (anchorContext.mounted) {
              appSnack(
                anchorContext,
                'تمت إضافة $val ${act.goalUnit ?? ""} إلى "${act.title}"',
              );
            }
          },
        );
      },
    );
  }

  static void editActivity(
    BuildContext context,
    WidgetRef ref,
    ActivityItem act,
  ) async {
    await showModalBottomSheet<ActivityItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddActivitySheet(
        initialActivity: act,
        onSave: (h) async {
          Navigator.pop(ctx);
          await ref.read(activitiesProvider.notifier).updateActivity(h);
          return true;
        },
      ),
    );
  }
}
