import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/core/theme/app_moods.dart';
import '../../domain/reflection_entry.dart';

class ReflectionEntryCard extends StatelessWidget {
  const ReflectionEntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onReadMore,
    required this.onShowEditHistory,
  });

  final ReflectionEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReadMore;
  final VoidCallback onShowEditHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLong = entry.text.length > 150 || entry.text.split('\n').length > 4;
    final hasTags = entry.prayerPhaseName != null ||
        entry.linkedContextTitle != null ||
        entry.editHistory.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clean top row: Time + Mood + Menu
            Row(
              children: [
                Text(
                  DateFormat('h:mm a · d MMM', 'ar').format(entry.createdAt),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (entry.mood != null) ...[
                  MoodDisplayChip(mood: entry.mood!, dense: true),
                  const SizedBox(width: 4),
                ],
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text('حذف',
                              style: TextStyle(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Body text (or calm fallback if mood-only)
            if (entry.text.trim().isEmpty)
              Text(
                'توثيق حالة مزاجية',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (isLong) ...[
              Text(
                entry.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onReadMore,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('قراءة المزيد'),
                ),
              ),
            ] else
              Text(
                entry.text,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),

            // Context tags row (Prayer, Focus/Project link, Edit history)
            if (hasTags) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (entry.prayerPhaseName != null)
                    _ContextBadge(
                      icon: Icons.mosque_rounded,
                      label: 'رباط ${entry.prayerPhaseName!}',
                      color: colorScheme.primary,
                    ),
                  if (entry.linkedContextTitle != null)
                    _ContextBadge(
                      icon: entry.linkedContextTitle!.startsWith('تركيز:')
                          ? Icons.timer_outlined
                          : Icons.folder_outlined,
                      label: entry.linkedContextTitle!,
                      color: colorScheme.secondary,
                    ),
                  if (entry.editHistory.isNotEmpty)
                    InkWell(
                      onTap: onShowEditHistory,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text(
                          'معدّل (${entry.editHistory.length})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextBadge extends StatelessWidget {
  const _ContextBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
