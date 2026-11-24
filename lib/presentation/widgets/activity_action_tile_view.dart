part of 'activity_action_tile.dart';

extension _ActivityActionTileView on ActivityActionTile {
  Widget _buildActivityTile(BuildContext context) {
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
