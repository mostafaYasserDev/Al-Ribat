import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import '../../../settings/presentation/widgets/settings_action_sheet.dart';
import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../domain/reflection_entry.dart';

enum ReflectionViewMode {
  grid(
    label: 'شبكة',
    subtitle: 'بطاقات متجاورة بعمودين',
    icon: Icons.grid_view_rounded,
  ),
  list(
    label: 'قائمة',
    subtitle: 'بطاقات بعرض كامل مريحة للقراءة',
    icon: Icons.view_agenda_outlined,
  ),
  timeline(
    label: 'الخط الزمني',
    subtitle: 'مرتبة حسب الأيام وأوقات الصلاة',
    icon: Icons.timeline_rounded,
  ),
  compact(
    label: 'مضغوط',
    subtitle: 'عناوين سريعة في قائمة مجمّعة',
    icon: Icons.format_list_bulleted_rounded,
  );

  const ReflectionViewMode({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final IconData icon;
}

/// Staggered spring entrance wrapper used when switching view modes.
class StaggeredReflectionItem extends StatefulWidget {
  const StaggeredReflectionItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredReflectionItem> createState() =>
      _StaggeredReflectionItemState();
}

class _StaggeredReflectionItemState extends State<StaggeredReflectionItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curved;
    _scale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curved);

    final delayMs = (widget.index * 35).clamp(0, 240);
    if (delayMs == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Vertical timeline view grouped by day and linked to prayer phases.
class ReflectionTimelineView extends StatelessWidget {
  const ReflectionTimelineView({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
  });

  final List<ReflectionEntry> entries;
  final void Function(
      ReflectionEntry entry, BuildContext cardContext, Color bgColor) onTap;
  final void Function(ReflectionEntry entry) onTogglePin;
  final void Function(ReflectionEntry entry) onDelete;

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return DateFormat('EEEE، d MMMM', 'ar').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    final children = <Widget>[];
    String? lastDay;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final day = _dayLabel(entry.createdAt);
      if (day != lastDay) {
        lastDay = day;
        children.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10, bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  day,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final primaryMood =
          entry.mood != null ? AppMoods.find(entry.mood!) : null;
      final dotColor = primaryMood?.color ?? theme.colorScheme.primary;
      final isLastInGroup =
          i == entries.length - 1 || _dayLabel(entries[i + 1].createdAt) != day;

      children.add(
        StaggeredReflectionItem(
          index: i,
          child: _TimelineRow(
            entry: entry,
            dotColor: dotColor,
            cardColor: cardColor,
            showConnector: !isLastInGroup,
            onTap: (ctx) => onTap(entry, ctx, cardColor),
            onTogglePin: () => onTogglePin(entry),
            onDelete: () => onDelete(entry),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _TimelineRow extends StatefulWidget {
  const _TimelineRow({
    required this.entry,
    required this.dotColor,
    required this.cardColor,
    required this.showConnector,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
  });

  final ReflectionEntry entry;
  final Color dotColor;
  final Color cardColor;
  final bool showConnector;
  final void Function(BuildContext cardContext) onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  final _rowKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = widget.entry;
    final timeStr = DateFormat('h:mm a', 'ar').format(entry.createdAt);
    final hasTitle = entry.title != null && entry.title!.trim().isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: widget.dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.dotColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (widget.showConnector)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: isDark ? 0.12 : 0.10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KeyedSubtree(
                key: _rowKey,
                child: PressableScale(
                  onTap: () => widget.onTap(context),
                  child: Material(
                    color: widget.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTap(context);
                      },
                      onLongPress: () => _showRowMenu(context),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: isDark ? 0.08 : 0.06),
                            width: 0.6,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  timeStr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.52),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (entry.prayerPhaseName != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${entry.prayerPhaseName!}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (entry.isPinned)
                                  Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (hasTitle)
                              Text(
                                entry.title!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (entry.text.trim().isNotEmpty) ...[
                              if (hasTitle) const SizedBox(height: 2),
                              Text(
                                entry.text.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.45,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRowMenu(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final entry = widget.entry;
    final action = await showAnchoredSettingsMenu<String>(
      context: context,
      anchorKey: _rowKey,
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
        const AnchoredMenuOption(
          value: 'delete',
          title: 'حذف',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
    if (action == 'pin') {
      widget.onTogglePin();
    } else if (action == 'delete') {
      widget.onDelete();
    }
  }
}

/// Compact Apple Notes-style grouped list for scanning many entries at once.
class ReflectionCompactView extends StatelessWidget {
  const ReflectionCompactView({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
  });

  final List<ReflectionEntry> entries;
  final void Function(
      ReflectionEntry entry, BuildContext cardContext, Color bgColor) onTap;
  final void Function(ReflectionEntry entry) onTogglePin;
  final void Function(ReflectionEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return SettingsGroupCard(
      margin: EdgeInsets.zero,
      dividerIndent: 44,
      children: [
        for (var i = 0; i < entries.length; i++)
          StaggeredReflectionItem(
            index: i,
            child: _CompactReflectionRow(
              entry: entries[i],
              cardColor: cardColor,
              onTap: (ctx) => onTap(entries[i], ctx, cardColor),
              onTogglePin: () => onTogglePin(entries[i]),
              onDelete: () => onDelete(entries[i]),
            ),
          ),
      ],
    );
  }
}

class _CompactReflectionRow extends StatefulWidget {
  const _CompactReflectionRow({
    required this.entry,
    required this.cardColor,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
  });

  final ReflectionEntry entry;
  final Color cardColor;
  final void Function(BuildContext ctx) onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  State<_CompactReflectionRow> createState() => _CompactReflectionRowState();
}

class _CompactReflectionRowState extends State<_CompactReflectionRow> {
  final _rowKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final hasTitle = entry.title != null && entry.title!.trim().isNotEmpty;
    final displayText = hasTitle
        ? entry.title!.trim()
        : entry.text.trim().replaceAll('\n', ' ');
    final primaryMood = entry.mood != null ? AppMoods.find(entry.mood!) : null;
    final badgeColor = primaryMood?.color ?? theme.colorScheme.primary;
    final dateStr = DateFormat('d MMM', 'ar').format(entry.createdAt);

    return KeyedSubtree(
      key: _rowKey,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(context);
        },
        onLongPress: () async {
          HapticFeedback.mediumImpact();
          final action = await showAnchoredSettingsMenu<String>(
            context: context,
            anchorKey: _rowKey,
            title: displayText.isEmpty ? 'خيارات الخاطرة' : displayText,
            options: [
              AnchoredMenuOption(
                value: 'pin',
                title: entry.isPinned ? 'إلغاء التثبيت' : 'تثبيت الخاطرة',
                icon: entry.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: theme.colorScheme.primary,
              ),
              if (entry.text.trim().isNotEmpty)
                const AnchoredMenuOption(
                  value: 'copy',
                  title: 'نسخ النص',
                  icon: Icons.copy_rounded,
                  color: Color(0xFF007AFF),
                ),
              const AnchoredMenuOption(
                value: 'delete',
                title: 'حذف',
                icon: Icons.delete_outline_rounded,
                isDestructive: true,
              ),
            ],
          );
          if (action == 'pin') {
            widget.onTogglePin();
          } else if (action == 'copy') {
            await Clipboard.setData(ClipboardData(text: entry.text.trim()));
            if (context.mounted) appSnack(context, 'تم نسخ الخاطرة.');
          } else if (action == 'delete') {
            widget.onDelete();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText.isEmpty ? 'خاطرة' : displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (entry.prayerPhaseName != null) ...[
                Text(
                  entry.prayerPhaseName!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                dateStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                ),
              ),
              if (entry.isPinned) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.push_pin_rounded,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
