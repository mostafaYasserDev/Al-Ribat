import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/core/theme/app_moods.dart';
import '../../domain/reflection_colors.dart';
import '../../domain/reflection_entry.dart';

class ReflectionEntryCard extends StatefulWidget {
  const ReflectionEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    this.isGrid = false,
  });

  final ReflectionEntry entry;
  final void Function(BuildContext cardContext, Color bgColor) onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final bool isGrid;

  @override
  State<ReflectionEntryCard> createState() => _ReflectionEntryCardState();
}

class _ReflectionEntryCardState extends State<ReflectionEntryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customBg =
        ReflectionColors.resolveBackground(entry.colorKey, theme.brightness);
    final bgColor = customBg ?? colorScheme.surfaceContainerLow;
    final hasTitle = entry.title != null && entry.title!.trim().isNotEmpty;
    final hasBody = entry.text.trim().isNotEmpty;

    return AnimatedScale(
      scale: _pressed ? 0.965 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHighlightChanged: (v) {
            if (_pressed != v) setState(() => _pressed = v);
          },
          onTap: () => widget.onTap(context, bgColor),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: customBg != null
                    ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4, top: 2),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  if (hasBody) const SizedBox(height: 6),
                ],

                if (hasBody)
                  Text(
                    entry.text,
                    maxLines: widget.isGrid ? 7 : 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontSize: 13.5,
                    ),
                  )
                else if (!hasTitle)
                  Text(
                    'توثيق حالة مزاجية',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                const SizedBox(height: 10),

                // Quiet metadata footer
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!hasTitle && entry.isPinned)
                      Icon(
                        Icons.push_pin_rounded,
                        size: 13,
                        color: colorScheme.primary,
                      ),
                    if (entry.prayerPhaseName != null)
                      _QuietTag(
                        icon: Icons.mosque_rounded,
                        label: entry.prayerPhaseName!,
                        color: colorScheme.primary,
                      ),
                    if (entry.linkedContextTitle != null)
                      _QuietTag(
                        icon: entry.linkedContextTitle!.startsWith('تركيز:')
                            ? Icons.timer_outlined
                            : Icons.folder_outlined,
                        label: entry.linkedContextTitle!,
                        color: colorScheme.secondary,
                      ),
                    if (entry.mood != null)
                      MoodDisplayChip(mood: entry.mood!, dense: true),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Text(
                      DateFormat('h:mm a · d MMM', 'ar')
                          .format(entry.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) {
                        if (val == 'pin') {
                          widget.onTogglePin();
                        } else if (val == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                entry.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(entry.isPinned ? 'إلغاء التثبيت' : 'تثبيت'),
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
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
