part of 'activity_action_tile.dart';

extension _ActivityActionTileTile on ActivityActionTile {
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
            // Checkbox touch target (1-tap to toggle done)
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

            // Habit Custom Icon
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

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      decoration: isDone || isSkipped
                          ? TextDecoration.lineThrough
                          : null,
                      color: titleColor ?? colorScheme.onSurface,
                      fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      decoration: isDone || isSkipped
                          ? TextDecoration.lineThrough
                          : null,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Measurable Progress / Action Info
            if (activity.isMeasurable) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${ActivityActionTile.formatProgress(activity.getProgressOn(dateStr))}/${ActivityActionTile.formatProgress(activity.targetGoal ?? 1)} ${activity.goalUnit ?? ""}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _showAddProgressDialog(context),
              ),
            ] else ...[
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _showDetailsSheet(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
