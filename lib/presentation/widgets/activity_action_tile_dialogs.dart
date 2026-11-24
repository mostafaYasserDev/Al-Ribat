part of 'activity_action_tile.dart';

extension _ActivityActionTileDialogs on ActivityActionTile {
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
      HapticFeedback.lightImpact();
      await onUpdate(updated);
      if (context.mounted) appSnack(context, 'تم تعديل النشاط.');
    }
  }
}
