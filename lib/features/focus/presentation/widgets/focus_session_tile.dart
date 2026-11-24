import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/work_session_item.dart';

class FocusSessionTile extends StatelessWidget {
  const FocusSessionTile({super.key, required this.session});

  final WorkSessionItem session;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.completed
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            session.completed ? Icons.check_rounded : Icons.pause_rounded,
            color: session.completed
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        title: Text(
          session.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat('EEEE d MMM · HH:mm', 'ar').format(session.startedAt)} — '
          '${session.plannedMinutes} دقيقة مخططة — '
          '${session.completed ? 'مكتملة' : 'متوقفة'}',
        ),
      ),
    );
  }
}
