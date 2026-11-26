import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:al_ribat/features/projects/presentation/widgets/anchored_popover.dart';

/// Opens an Apple / Telegram-inspired Arabic calendar popover anchored to
/// [anchorContext], expanding from the date pill and collapsing back on close.
Future<void> showArabicDatePopover(
  BuildContext anchorContext, {
  required DateTime initialDate,
  required ValueChanged<DateTime> onSelected,
}) {
  return showAnchoredPopover<void>(
    anchorContext,
    width: 312,
    preferAbove: false,
    anchorRadius: 22,
    builder: (popCtx) => _ArabicCalendarPopoverContent(
      initialDate: initialDate,
      onSelected: (picked) {
        onSelected(picked);
        Navigator.pop(popCtx);
      },
    ),
  );
}

class _ArabicCalendarPopoverContent extends StatefulWidget {
  const _ArabicCalendarPopoverContent({
    required this.initialDate,
    required this.onSelected,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_ArabicCalendarPopoverContent> createState() =>
      _ArabicCalendarPopoverContentState();
}

class _ArabicCalendarPopoverContentState
    extends State<_ArabicCalendarPopoverContent> {
  late DateTime _visibleMonth;

  static const _weekHeaders = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _accentFor(DateTime date, DateTime today, Color primary) {
    final norm = DateTime(date.year, date.month, date.day);
    if (norm.isBefore(today)) return const Color(0xFFD97706);
    if (norm.isAfter(today)) return const Color(0xFF007AFF);
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final innerBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Saturday = 0 .. Friday = 6 (Dart weekday: Mon=1..Sat=6, Sun=7)
    final leadingBlanks = (firstOfMonth.weekday + 1) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick shortcuts: أمس | اليوم | غداً
          Row(
            children: [
              _QuickDateChip(
                label: 'أمس',
                color: const Color(0xFFD97706),
                selected: _sameDay(
                  selected,
                  today.subtract(const Duration(days: 1)),
                ),
                bg: innerBg,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelected(today.subtract(const Duration(days: 1)));
                },
              ),
              const SizedBox(width: 6),
              _QuickDateChip(
                label: 'اليوم',
                color: colorScheme.primary,
                selected: _sameDay(selected, today),
                bg: innerBg,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelected(today);
                },
              ),
              const SizedBox(width: 6),
              _QuickDateChip(
                label: 'غداً',
                color: const Color(0xFF007AFF),
                selected: _sameDay(
                  selected,
                  today.add(const Duration(days: 1)),
                ),
                bg: innerBg,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelected(today.add(const Duration(days: 1)));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 0.6, thickness: 0.6, color: dividerColor),
          const SizedBox(height: 10),

          // Month navigation header
          Row(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 19),
                ),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'ar').format(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, size: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Weekday header (Sat .. Fri)
          Row(
            children: _weekHeaders
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.48),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),

          // Calendar days grid
          for (var r = 0; r < rowCount; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: List.generate(7, (c) {
                  final cellIdx = r * 7 + c;
                  final dayNum = cellIdx - leadingBlanks + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 34));
                  }
                  final cellDate = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month,
                    dayNum,
                  );
                  final isSel = _sameDay(cellDate, selected);
                  final isToday = _sameDay(cellDate, today);
                  final accent =
                      _accentFor(cellDate, today, colorScheme.primary);

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelected(cellDate);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 34,
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: isSel
                              ? accent
                              : (isToday
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSel
                              ? Border.all(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.45),
                                  width: 1,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel || isToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSel
                                ? Colors.white
                                : (isToday
                                    ? colorScheme.primary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.85)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : bg,
            borderRadius: BorderRadius.circular(10),
            border: selected ? Border.all(color: color, width: 1.2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? color
                  : colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ),
      ),
    );
  }
}
