import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/core/ui_feedback.dart';
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

  void _showActionsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final entry = widget.entry;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: sheetBg,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    entry.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title:
                      Text(entry.isPinned ? 'إلغاء التثبيت' : 'تثبيت الخاطرة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    HapticFeedback.selectionClick();
                    widget.onTogglePin();
                  },
                ),
                if (entry.text.trim().isNotEmpty ||
                    (entry.title?.trim().isNotEmpty ?? false))
                  ListTile(
                    leading: Icon(
                      Icons.copy_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    title: const Text('نسخ النص'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final buffer = [
                        if (entry.title != null &&
                            entry.title!.trim().isNotEmpty)
                          entry.title!.trim(),
                        if (entry.text.trim().isNotEmpty) entry.text.trim(),
                      ].join('\n');
                      await Clipboard.setData(ClipboardData(text: buffer));
                      if (context.mounted) {
                        appSnack(context, 'تم نسخ الخاطرة.');
                      }
                    },
                  ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'حذف',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDelete();
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final customBg =
        ReflectionColors.resolveBackground(entry.colorKey, theme.brightness);
    final bgColor = customBg ??
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final hasTitle = entry.title != null && entry.title!.trim().isNotEmpty;
    final hasBody = entry.text.trim().isNotEmpty;

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 95),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: customBg != null
                  ? colorScheme.onSurface.withValues(alpha: 0.09)
                  : colorScheme.onSurface
                      .withValues(alpha: isDark ? 0.08 : 0.07),
              width: 0.7,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onHighlightChanged: (v) {
                if (_pressed != v) setState(() => _pressed = v);
              },
              onTap: () => widget.onTap(context, bgColor),
              onLongPress: () => _showActionsSheet(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                                fontWeight: FontWeight.w700,
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
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showActionsSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
