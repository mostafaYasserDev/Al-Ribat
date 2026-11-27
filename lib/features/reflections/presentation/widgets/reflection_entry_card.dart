import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import '../../../settings/presentation/widgets/settings_action_sheet.dart';
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
  final _cardKey = GlobalKey();
  bool _pressed = false;

  Future<void> _showActionsSheet(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final entry = widget.entry;
    final hasText = entry.text.trim().isNotEmpty ||
        (entry.title?.trim().isNotEmpty ?? false);

    final action = await showAnchoredSettingsMenu<String>(
      context: context,
      anchorKey: _cardKey,
      title: entry.title?.trim().isNotEmpty == true
          ? entry.title!.trim()
          : 'خيارات الخاطرة',
      options: [
        AnchoredMenuOption(
          value: 'pin',
          title: entry.isPinned ? 'إلغاء التثبيت' : 'تثبيت الخاطرة',
          icon:
              entry.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        if (hasText) ...[
          const AnchoredMenuOption(
            value: 'copy',
            title: 'نسخ النص',
            icon: Icons.copy_rounded,
            color: Color(0xFF007AFF),
          ),
          const AnchoredMenuOption(
            value: 'share',
            title: 'مشاركة الخاطرة',
            icon: Icons.ios_share_rounded,
            color: Color(0xFF5856D6),
          ),
        ],
        const AnchoredMenuOption(
          value: 'delete',
          title: 'حذف',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );

    if (action == null || !context.mounted) return;
    final fullText = [
      if (entry.title != null && entry.title!.trim().isNotEmpty)
        entry.title!.trim(),
      if (entry.text.trim().isNotEmpty) entry.text.trim(),
    ].join('\n');

    if (action == 'pin') {
      widget.onTogglePin();
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: fullText));
      if (context.mounted) appSnack(context, 'تم نسخ الخاطرة.');
    } else if (action == 'share') {
      try {
        await Share.share(fullText);
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: fullText));
        if (context.mounted) appSnack(context, 'تم نسخ الخاطرة للمشاركة.');
      }
    } else if (action == 'delete') {
      widget.onDelete();
    }
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
      key: _cardKey,
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
                        for (final m in entry.moods)
                          MoodDisplayChip(mood: m, dense: true),
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
