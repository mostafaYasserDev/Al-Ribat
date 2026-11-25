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
    final moodOpt = AppMoods.find(entry.mood);
    final accentColor = moodOpt?.color ?? colorScheme.primary;
    final isLong = entry.text.length > 160 || entry.text.split('\n').length > 4;
    final hasTags = entry.prayerPhaseName != null ||
        entry.linkedContextTitle != null ||
        entry.editHistory.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtle vertical accent bar on the right (RTL start)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Body text first — writing is the hero
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
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onReadMore,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Text('قراءة المزيد'),
                        ),
                      ),
                    ] else
                      Text(
                        entry.text,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Quiet footer: Time, optional tags, optional mood, and menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                DateFormat('h:mm a · d MMM', 'ar')
                                    .format(entry.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (hasTags) ...[
                                if (entry.prayerPhaseName != null)
                                  _QuietTag(
                                    icon: Icons.mosque_rounded,
                                    label: entry.prayerPhaseName!,
                                    color: colorScheme.primary,
                                  ),
                                if (entry.linkedContextTitle != null)
                                  _QuietTag(
                                    icon: entry.linkedContextTitle!
                                            .startsWith('تركيز:')
                                        ? Icons.timer_outlined
                                        : Icons.folder_outlined,
                                    label: entry.linkedContextTitle!,
                                    color: colorScheme.secondary,
                                  ),
                                if (entry.editHistory.isNotEmpty)
                                  InkWell(
                                    onTap: onShowEditHistory,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Text(
                                      'معدّل',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        if (entry.mood != null) ...[
                          const SizedBox(width: 6),
                          MoodDisplayChip(mood: entry.mood!, dense: true),
                        ],
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                                      style:
                                          TextStyle(color: colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietTag extends StatelessWidget {
  const _QuietTag({
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
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
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
