import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/active_focus_state.dart';
import '../../domain/focus_time_formatter.dart';
import '../../domain/work_session_item.dart';

class FocusSessionTile extends StatelessWidget {
  const FocusSessionTile({
    super.key,
    required this.session,
    this.onDelete,
  });

  final WorkSessionItem session;
  final VoidCallback? onDelete;

  String? _modeLabel(String? mode) {
    if (mode == null) return null;
    for (final m in FocusSessionMode.values) {
      if (m.name == mode) return m.arabicLabel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actualSec = session.endedAt.difference(session.startedAt).inSeconds;
    final actualText = FocusTimeFormatter.formatSecondsReadable(actualSec);
    final plannedText =
        FocusTimeFormatter.formatDurationReadable(session.plannedMinutes);

    final durationInfo = session.plannedMinutes > 0
        ? 'منجز: $actualText · مخطط: $plannedText'
        : 'المدة: $actualText';
    final modeText = _modeLabel(session.sessionMode);
    final badgeColor =
        session.completed ? const Color(0xFF34C759) : const Color(0xFFFF9500);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              session.completed ? Icons.check_rounded : Icons.pause_rounded,
              color: badgeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('EEEE d MMM · hh:mm a', 'ar').format(session.startedAt)}\n$durationInfo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (session.linkedActivityTitle != null || modeText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (session.linkedActivityTitle != null)
                          _MetaChip(
                            icon: Icons.link_rounded,
                            label: session.linkedActivityTitle!,
                            color: colorScheme.primary,
                          ),
                        if (modeText != null)
                          _MetaChip(
                            icon: Icons.timer_outlined,
                            label: modeText,
                            color: colorScheme.secondary,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              tooltip: 'حذف الجلسة',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                HapticFeedback.lightImpact();
                onDelete!();
              },
            ),
        ],
      ),
    );

    if (onDelete == null) return content;

    return Dismissible(
      key: ValueKey('session_${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.error,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete!();
      },
      child: content,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
