import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/focus_time_formatter.dart';
import '../../domain/work_session_item.dart';

class FocusSessionTile extends StatelessWidget {
  const FocusSessionTile({super.key, required this.session});

  final WorkSessionItem session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actualText =
        FocusTimeFormatter.formatDurationReadable(session.actualMinutes);
    final plannedText =
        FocusTimeFormatter.formatDurationReadable(session.plannedMinutes);

    final durationInfo = session.plannedMinutes > 0
        ? 'منجز: $actualText / مخطط: $plannedText'
        : 'المدة: $actualText';

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
        subtitle: Text(
          '${DateFormat('EEEE d MMM · HH:mm', 'ar').format(session.startedAt)} · '
          '$durationInfo · '
          '${session.completed ? 'مكتملة' : 'متوقفة'}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
