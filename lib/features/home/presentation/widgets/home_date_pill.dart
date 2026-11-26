import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Telegram/Apple-style animated date capsule pill with clear visual
/// distinction between Past, Today, and Future dates.
class HomeDatePill extends StatelessWidget {
  const HomeDatePill({
    super.key,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
    this.onReturnToToday,
  });

  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final void Function(BuildContext anchorContext) onPickDate;
  final VoidCallback? onReturnToToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final baseCardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final diffDays = query.difference(today).inDays;
    final isPast = diffDays < 0;
    final isFuture = diffDays > 0;

    final Color accentColor;
    final IconData leadingIcon;
    final String? statusText;

    if (isPast) {
      accentColor = const Color(0xFFD97706);
      leadingIcon = Icons.history_rounded;
      statusText =
          diffDays == -1 ? 'أمس' : 'أرشيف الماضي · قبل ${diffDays.abs()} أيام';
    } else if (isFuture) {
      accentColor = const Color(0xFF007AFF);
      leadingIcon = Icons.upcoming_rounded;
      statusText =
          diffDays == 1 ? 'غداً' : 'تخطيط مستقبلي · بعد $diffDays أيام';
    } else {
      accentColor = colorScheme.primary;
      leadingIcon = Icons.calendar_today_rounded;
      statusText = null;
    }

    final pillBg = (isPast || isFuture)
        ? Color.alphaBlend(
            accentColor.withValues(alpha: isDark ? 0.14 : 0.07),
            baseCardColor,
          )
        : baseCardColor;
    final pillBorder = (isPast || isFuture)
        ? accentColor.withValues(alpha: isDark ? 0.42 : 0.35)
        : colorScheme.onSurface.withValues(alpha: isDark ? 0.09 : 0.07);

    final pillKey = GlobalKey();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: AnimatedContainer(
            key: pillKey,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: pillBorder,
                width: (isPast || isFuture) ? 1.0 : 0.7,
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavArrowButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'اليوم السابق',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPreviousDay();
                  },
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onPickDate(pillKey.currentContext ?? context);
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          leadingIcon,
                          size: 15,
                          color: accentColor,
                        ),
                        const SizedBox(width: 7),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            DateFormat('EEEE · d MMMM yyyy', 'ar')
                                .format(selectedDate),
                            key: ValueKey(
                              '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavArrowButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'اليوم التالي',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onNextDay();
                  },
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: statusText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(leadingIcon, size: 13, color: accentColor),
                            const SizedBox(width: 5),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onReturnToToday != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onReturnToToday!();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'العودة لليوم',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  const _NavArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
