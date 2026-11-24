import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/ui_feedback.dart';
import '../../../domain/entities/activity_item.dart';
import '../../widgets/activity_add_progress_sheet.dart';
import '../../widgets/activity_details_sheet.dart';
import '../../widgets/add_activity_sheet.dart';

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
    final wasDone = task.repetition == ActivityRepetition.once
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
    BuildContext context,
    WidgetRef ref,
    ActivityItem act,
  ) {
    final now = DateTime.now();
    final d =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ActivityDetailsSheet(
        activity: act,
        dateStr: d,
        onToggleDone: () async {
          Navigator.pop(ctx);
          await toggleDone(context, ref, act);
        },
        onToggleSkip: () async {
          Navigator.pop(ctx);
          await ref.read(activitiesProvider.notifier).toggleSkip(act, d);
        },
        onEdit: () {
          Navigator.pop(ctx);
          editActivity(context, ref, act);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          await ref.read(activitiesProvider.notifier).deleteActivity(act.id);
          if (context.mounted) appSnack(context, 'تم حذف المهمة.');
        },
        onAddProgress: () {
          Navigator.pop(ctx);
          ActivityAddProgressSheet.show(
            context,
            activity: act,
            dateStr: d,
            onAdd: (val) async {
              await ref
                  .read(activitiesProvider.notifier)
                  .addProgress(act, d, val);
              if (context.mounted) {
                appSnack(context,
                    'تمت إضافة $val ${act.goalUnit ?? ""} إلى "${act.title}"');
              }
            },
          );
        },
      ),
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
