import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final actualSec = session.endedAt.difference(session.startedAt).inSeconds;
    final actualText = FocusTimeFormatter.formatSecondsReadable(actualSec);
    final plannedText =
        FocusTimeFormatter.formatDurationReadable(session.plannedMinutes);

    final durationInfo = session.plannedMinutes > 0
        ? 'منجز: $actualText / مخطط: $plannedText'
        : 'المدة: $actualText';
    final modeText = _modeLabel(session.sessionMode);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.completed
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            session.completed ? Icons.check_rounded : Icons.pause_rounded,
            color:
                session.completed ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        title: Text(
          session.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('EEEE d MMM · hh:mm a', 'ar').format(session.startedAt)} · '
              '$durationInfo · '
              '${session.completed ? 'مكتملة' : 'متوقفة'}',
              style: const TextStyle(fontSize: 12),
            ),
            if (session.linkedActivityTitle != null || modeText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
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
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: colorScheme.onSurfaceVariant),
                tooltip: 'حذف الجلسة',
                onPressed: onDelete,
              )
            : null,
      ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
